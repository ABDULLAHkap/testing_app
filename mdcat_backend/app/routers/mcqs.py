import math
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.auth import get_current_user, require_test_access
from app.exam_catalog import EXAM_CATALOG
from app.database import get_db
from app.models.models import User, QuizSet
from app.schemas import (
    GenerateMCQRequest, QuizSetOut, QuizSetSummary, TopicListItem,
    PastPaperSummary, PastPaperDetail, SubjectBreakdownItem,
)
from app.services.batch_generator import generate_large_mcqs

router = APIRouter(prefix="/mcqs", tags=["mcqs"])


# Curated MDCAT subject/topic structure (per the standard Pakistani MDCAT
# syllabus). Used to power the "Practice by Topic" picker in the app —
# students never need to upload their own material.
MDCAT_SYLLABUS: dict[str, list[str]] = {
    "Biology": [
        "Cell Biology", "Biological Molecules", "Enzymes", "Bioenergetics",
        "Nutrition", "Gaseous Exchange", "Transport", "Homeostasis",
        "Support and Movement", "Coordination and Control", "Reproduction",
        "Genetics", "Evolution", "Biotechnology", "Ecosystem",
    ],
    "Chemistry": [
        "Basic Chemistry", "Atomic Structure", "Chemical Bonding",
        "Thermochemistry", "Chemical Equilibrium", "Reaction Kinetics",
        "Periodic Table", "s- and p-Block Elements", "Organic Chemistry Basics",
        "Hydrocarbons", "Alkyl Halides", "Biomolecules", "Environmental Chemistry",
    ],
    "Physics": [
        "Vectors and Equilibrium", "Motion and Force", "Work and Energy",
        "Rotational Dynamics", "Oscillations", "Waves", "Thermodynamics",
        "Electrostatics", "Current Electricity", "Electromagnetism",
        "Electromagnetic Induction", "Modern Physics", "Atomic and Nuclear Physics",
    ],
    "English": [
        "Grammar", "Vocabulary", "Sentence Completion", "Analogy",
        "Comprehension",
    ],
    "Logical Reasoning": [
        "Pattern Recognition", "Analytical Reasoning", "Data Sufficiency",
        "Logical Sequences",
    ],
}

# Approximate official MDCAT subject weightage, used to build proportional
# mock tests across subjects.
MDCAT_WEIGHTAGE: dict[str, float] = {
    "Biology": 0.44,
    "Chemistry": 0.30,
    "Physics": 0.19,
    "English": 0.04,
    "Logical Reasoning": 0.03,
}


def _require_exact_questions(questions: list[dict], expected: int) -> None:
    if len(questions) != expected:
        raise HTTPException(
            502,
            detail=(
                f"The AI service produced {len(questions)} unique questions "
                f"instead of {expected}. Please try again."
            ),
        )


def _allocate_mock_questions(total: int) -> dict[str, int]:
    """Allocates an exact total while including every MDCAT subject."""
    subjects = list(MDCAT_WEIGHTAGE)
    counts = {subject: 1 for subject in subjects}
    remaining = total - len(subjects)

    raw = {
        subject: remaining * weight
        for subject, weight in MDCAT_WEIGHTAGE.items()
    }
    for subject, amount in raw.items():
        counts[subject] += math.floor(amount)

    assigned = sum(counts.values())
    for subject in sorted(raw, key=lambda item: raw[item] % 1, reverse=True):
        if assigned >= total:
            break
        counts[subject] += 1
        assigned += 1

    return counts


class MockTestRequest(BaseModel):
    total_questions: int = Field(default=100, ge=5, le=200)
    difficulty: str = "Medium"
    quiz_minutes: int = 150


# Metadata describing the STRUCTURE of well-known MDCAT past papers
# (question count, timing, subject split, marking scheme) — used to
# generate a fresh, original AI practice test that follows the same
# pattern. This does NOT reproduce any actual past exam questions;
# real past papers' content isn't stored or served anywhere here.
PAST_PAPER_PATTERNS: dict[str, dict] = {
    "uhs-2025-c": {
        "title": "UHS Punjab MDCAT 2025 (Paper ID-C)",
        "total_questions": 180,
        "quiz_minutes": 210,
        "marks_per_correct": 5.0,
        "marks_penalty_per_wrong": 1.0,
        "subject_breakdown": {"Biology": 81, "Chemistry": 45, "Physics": 36, "English": 9, "Logical Reasoning": 9},
    },
    "pmc-2024": {
        "title": "PMC MDCAT 2024",
        "total_questions": 200,
        "quiz_minutes": 210,
        "marks_per_correct": 1.0,
        "marks_penalty_per_wrong": 0.0,
        "subject_breakdown": {"Biology": 88, "Chemistry": 60, "Physics": 40, "English": 8, "Logical Reasoning": 4},
    },
    "pmc-2023": {
        "title": "PMC MDCAT 2023",
        "total_questions": 200,
        "quiz_minutes": 210,
        "marks_per_correct": 1.0,
        "marks_penalty_per_wrong": 0.0,
        "subject_breakdown": {"Biology": 88, "Chemistry": 60, "Physics": 40, "English": 8, "Logical Reasoning": 4},
    },
    "pmc-2020": {
        "title": "PMC MDCAT 2020",
        "total_questions": 200,
        "quiz_minutes": 210,
        "marks_per_correct": 1.0,
        "marks_penalty_per_wrong": 0.0,
        "subject_breakdown": {"Biology": 88, "Chemistry": 60, "Physics": 40, "English": 8, "Logical Reasoning": 4},
    },
    "uhs-2019-b": {
        "title": "UHS MDCAT 2019 - Paper B",
        "total_questions": 200,
        "quiz_minutes": 150,
        "marks_per_correct": 1.0,
        "marks_penalty_per_wrong": 0.0,
        "subject_breakdown": {"Biology": 88, "Chemistry": 60, "Physics": 40, "English": 8, "Logical Reasoning": 4},
    },
    "uhs-2018-c": {
        "title": "UHS MDCAT 2018 - Paper C",
        "total_questions": 200,
        "quiz_minutes": 150,
        "marks_per_correct": 1.0,
        "marks_penalty_per_wrong": 0.0,
        "subject_breakdown": {"Biology": 88, "Chemistry": 60, "Physics": 40, "English": 8, "Logical Reasoning": 4},
    },
}

PAST_PAPER_INSTRUCTIONS = [
    "All questions are compulsory",
    "Each question carries the marks shown above",
    "Marks are deducted for each wrong answer as shown above",
    "No mark is deducted for unanswered questions",
    "Use of calculator is not allowed",
    "This is an AI-generated practice set following this exam's official "
    "pattern — not a reproduction of the original paper's questions.",
]


@router.post("/generate", response_model=QuizSetOut)
def generate_mcqs_endpoint(
    payload: GenerateMCQRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_test_access),
):
    # No upload required by default: if `text` is omitted, MCQs are generated
    # purely from the AI's own MDCAT subject knowledge (optionally focused
    # on `topic`). If `text` IS provided (e.g. from an uploaded file), it's
    # used to ground the questions instead.
    text = payload.text.strip() if payload.text else None

    exam_type = payload.exam_type or current_user.target_exam
    if exam_type not in EXAM_CATALOG:
        raise HTTPException(422, detail="Unsupported exam category")
    questions = generate_large_mcqs(
        total_questions=payload.number_of_questions,
        subject=payload.subject,
        difficulty=payload.difficulty,
        topic=payload.topic,
        text=text,
        exam_type=exam_type,
    )

    _require_exact_questions(questions, payload.number_of_questions)

    quiz_set = QuizSet(
        user_id=current_user.id,
        exam_type=exam_type,
        subject=payload.subject,
        difficulty=payload.difficulty,
        quiz_minutes=payload.quiz_minutes,
        source_filename=payload.source_filename,
        questions=questions,
    )
    db.add(quiz_set)
    db.commit()
    db.refresh(quiz_set)
    return quiz_set


@router.get("/exam-catalog")
def exam_catalog():
    return [
        {"exam": exam, "subjects": subjects}
        for exam, subjects in EXAM_CATALOG.items()
    ]


@router.get("/subjects", response_model=List[TopicListItem])
def list_subjects_and_topics(current_user: User = Depends(get_current_user)):
    """Subjects for the exam category selected during signup."""
    if current_user.target_exam != "MDCAT":
        return [
            TopicListItem(subject=subject, topics=[subject])
            for subject in EXAM_CATALOG[current_user.target_exam]
        ]
    return [
        TopicListItem(subject=subject, topics=topics)
        for subject, topics in MDCAT_SYLLABUS.items()
    ]


@router.post("/mock-test", response_model=QuizSetOut)
def generate_mock_test(
    payload: MockTestRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_test_access),
):
    """
    Generates one full-length mock test mixing all MDCAT subjects,
    proportioned by official subject weightage, with no upload needed.
    """
    all_questions: list[dict] = []

    exam_type = current_user.target_exam
    if exam_type == "MDCAT":
        counts = _allocate_mock_questions(payload.total_questions)
    else:
        subjects = EXAM_CATALOG[exam_type]
        counts = {subject: payload.total_questions // len(subjects) for subject in subjects}
        for subject in subjects[:payload.total_questions % len(subjects)]:
            counts[subject] += 1

    for subject, count in counts.items():

        questions = generate_large_mcqs(
            total_questions=count,
            subject=subject,
            difficulty=payload.difficulty,
            exam_type=exam_type,
        )
        _require_exact_questions(questions, count)
        all_questions.extend(questions)

    _require_exact_questions(all_questions, payload.total_questions)

    quiz_set = QuizSet(
        user_id=current_user.id,
        exam_type=exam_type,
        subject="Mixed (Mock Test)",
        difficulty=payload.difficulty,
        quiz_minutes=payload.quiz_minutes,
        source_filename=None,
        questions=all_questions,
    )
    db.add(quiz_set)
    db.commit()
    db.refresh(quiz_set)
    return quiz_set


@router.get("", response_model=List[QuizSetSummary])
def list_quiz_sets(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    sets = (
        db.query(QuizSet)
        .filter(QuizSet.user_id == current_user.id)
        .order_by(QuizSet.created_at.desc())
        .all()
    )
    return [
        QuizSetSummary(
            id=s.id,
            subject=s.subject,
            difficulty=s.difficulty,
            quiz_minutes=s.quiz_minutes,
            question_count=len(s.questions),
            created_at=s.created_at,
        )
        for s in sets
    ]


# ---------- Past Papers (pattern-based, AI-generated) ----------

@router.get("/past-papers", response_model=List[PastPaperSummary])
def list_past_papers():
    return [
        PastPaperSummary(
            id=paper_id,
            title=p["title"],
            total_questions=p["total_questions"],
            quiz_minutes=p["quiz_minutes"],
        )
        for paper_id, p in PAST_PAPER_PATTERNS.items()
    ]


@router.get("/past-papers/{paper_id}", response_model=PastPaperDetail)
def get_past_paper_detail(paper_id: str):
    paper = PAST_PAPER_PATTERNS.get(paper_id)
    if not paper:
        raise HTTPException(404, detail="Past paper pattern not found")

    total = paper["total_questions"]
    breakdown = [
        SubjectBreakdownItem(
            subject=subject,
            weight_percent=round(count / total * 100, 1),
            mcq_count=count,
        )
        for subject, count in paper["subject_breakdown"].items()
    ]

    return PastPaperDetail(
        id=paper_id,
        title=paper["title"],
        total_questions=total,
        quiz_minutes=paper["quiz_minutes"],
        total_marks=round(total * paper["marks_per_correct"]),
        marks_per_correct=paper["marks_per_correct"],
        marks_penalty_per_wrong=paper["marks_penalty_per_wrong"],
        subject_breakdown=breakdown,
        instructions=PAST_PAPER_INSTRUCTIONS,
    )


@router.post("/past-papers/{paper_id}/generate", response_model=QuizSetOut)
def generate_from_past_paper(
    paper_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Generates a fresh AI practice test following the exact subject
    structure of a well-known past paper's official pattern.
    """
    paper = PAST_PAPER_PATTERNS.get(paper_id)
    if not paper:
        raise HTTPException(404, detail="Past paper pattern not found")

    all_questions: list[dict] = []
    for subject, count in paper["subject_breakdown"].items():
        if count <= 0:
            continue
        questions = generate_large_mcqs(
            total_questions=count,
            subject=subject,
            difficulty="Medium",
        )
        _require_exact_questions(questions, count)
        all_questions.extend(questions)

    _require_exact_questions(all_questions, paper["total_questions"])

    quiz_set = QuizSet(
        user_id=current_user.id,
        subject=f"Past Paper Pattern: {paper['title']}",
        difficulty="Medium",
        quiz_minutes=paper["quiz_minutes"],
        source_filename=None,
        questions=all_questions,
    )
    db.add(quiz_set)
    db.commit()
    db.refresh(quiz_set)
    return quiz_set


@router.get("/{quiz_set_id}", response_model=QuizSetOut)
def get_quiz_set(
    quiz_set_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    quiz_set = (
        db.query(QuizSet)
        .filter(QuizSet.id == quiz_set_id, QuizSet.user_id == current_user.id)
        .first()
    )
    if not quiz_set:
        raise HTTPException(404, detail="Quiz set not found")
    return quiz_set
