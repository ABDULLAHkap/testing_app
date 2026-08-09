import logging
import math
import os
import time
import uuid
from collections import Counter
from threading import Lock
from typing import List

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.auth import get_current_user, require_test_access
from app.exam_catalog import (
    EXAM_CATALOG,
    get_exam_format,
    get_exam_topics,
)
from app.database import get_db
from app.models.models import User, QuizSet
from app.schemas import (
    GenerateMCQRequest, QuizSetOut, QuizSetSummary, TopicListItem,
    PastPaperSummary, PastPaperDetail, SubjectBreakdownItem,
    AdaptivePracticeRequest,
)
from app.services.analytics_service import learning_breakdown
from app.services.batch_generator import generate_large_mcqs
from app.services.pdf_report import create_practice_paper_pdf

router = APIRouter(prefix="/mcqs", tags=["mcqs"])
logger = logging.getLogger(__name__)


_download_jobs: dict[str, dict] = {}
_download_jobs_lock = Lock()
_DOWNLOAD_JOB_TTL_SECONDS = 60 * 60
_DOWNLOAD_PACK_MAX_QUESTIONS = 25


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
                f"The question service produced {len(questions)} unique questions "
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


def _allocate_exam_practice_questions(
    exam_type: str,
    total: int,
) -> dict[str, int]:
    """Allocate quiz questions across sections that support objective practice.

    Some examinations also contain essays, interviews or audio tasks. Their
    ``mock_breakdown`` deliberately contains only the sections that this quiz
    engine can grade reliably, so every category can still offer a daily quiz
    without pretending that an MCQ set reproduces the entire examination.
    """
    if exam_type == "MDCAT":
        return _allocate_mock_questions(total)

    subjects = list(get_exam_format(exam_type)["mock_breakdown"])
    if not subjects:
        raise HTTPException(
            422,
            detail=f"No objective practice sections are configured for {exam_type}",
        )
    counts = {subject: total // len(subjects) for subject in subjects}
    for subject in subjects[: total % len(subjects)]:
        counts[subject] += 1
    return {subject: count for subject, count in counts.items() if count > 0}


def _compact_download_breakdown(subject_breakdown: dict[str, int]) -> dict[str, int]:
    """Scale a full paper pattern into a reliable offline practice pack.

    Generating 180-200 explained questions on demand requires dozens of model
    requests and regularly exceeds provider rate limits. A compact pack keeps
    the paper's subject proportions, includes every represented subject, and
    can be prepared within normal API limits.
    """
    positive = {name: count for name, count in subject_breakdown.items() if count > 0}
    if not positive:
        return {}
    target = min(_DOWNLOAD_PACK_MAX_QUESTIONS, sum(positive.values()))
    if target < len(positive):
        return {name: 1 for name in list(positive)[:target]}

    counts = {name: 1 for name in positive}
    remaining = target - len(positive)
    total_weight = sum(positive.values())
    raw = {
        name: remaining * weight / total_weight
        for name, weight in positive.items()
    }
    for name, value in raw.items():
        counts[name] += math.floor(value)
    assigned = sum(counts.values())
    for name in sorted(raw, key=lambda item: raw[item] % 1, reverse=True):
        if assigned >= target:
            break
        counts[name] += 1
        assigned += 1
    return counts


def _offline_download_questions(
    *, exam_type: str, subject: str, count: int, start_index: int = 0
) -> list[dict]:
    """Return honest, deterministic revision checks when the model is unavailable.

    A downloadable file must not fail merely because the question provider is
    rate-limited.  These are deliberately labelled revision checkpoints rather
    than being presented as official past-paper questions.
    """
    topics = get_exam_topics(exam_type).get(subject) or [subject]
    questions: list[dict] = []
    for offset in range(count):
        topic = topics[(start_index + offset) % len(topics)]
        questions.append(
            {
                "question": (
                    f"Revision checkpoint: Which listed area belongs to the "
                    f"{subject} preparation section for {exam_type}?"
                ),
                "options": [
                    f"A. {topic}",
                    "B. Payment account setup",
                    "C. Application form printing",
                    "D. Test-centre administration",
                ],
                "correct_option": "A",
                "explanation": (
                    f"{topic} is included in the app's {subject} preparation "
                    f"outline for {exam_type}. Revise this topic before attempting "
                    "a timed test."
                ),
                "subject": subject,
                "topic": topic,
                "concept": topic,
                "section": subject,
            }
        )
    return questions


def _build_download_questions(
    *, exam_type: str, subject_breakdown: dict[str, int]
) -> list[dict]:
    """Build a complete compact pack, tolerating provider errors/partial output."""
    questions: list[dict] = []
    for subject, count in _compact_download_breakdown(subject_breakdown).items():
        if count <= 0:
            continue
        generated: list[dict] = []
        try:
            generated = generate_large_mcqs(
                total_questions=count,
                subject=subject,
                difficulty="Medium",
                exam_type=exam_type,
            )
        except Exception:
            logger.warning(
                "Question provider unavailable for %s download section %s",
                exam_type,
                subject,
                exc_info=True,
            )
        questions.extend(generated[:count])
        missing = count - min(len(generated), count)
        if missing:
            questions.extend(
                _offline_download_questions(
                    exam_type=exam_type,
                    subject=subject,
                    count=missing,
                    start_index=len(generated),
                )
            )
    return questions


class MockTestRequest(BaseModel):
    total_questions: int = Field(default=100, ge=5, le=200)
    difficulty: str = "Medium"
    quiz_minutes: int = 150
    exam_type: str | None = None
    official_format: bool = False


def _exam_for_request(current_user: User, requested_exam: str | None) -> str:
    """Admins may test any catalog category; students stay in their category."""
    if not requested_exam:
        return current_user.target_exam
    if requested_exam not in EXAM_CATALOG:
        raise HTTPException(422, detail="Unsupported exam category")
    if not current_user.is_admin and requested_exam != current_user.target_exam:
        raise HTTPException(403, detail="Only administrators can change test category")
    return requested_exam


def _require_objective_section(exam_type: str, subject: str) -> None:
    """Prevent descriptive/audio sections from silently becoming generic MCQs."""
    section = next(
        (
            item for item in get_exam_format(exam_type)["sections"]
            if item["name"].casefold() == subject.strip().casefold()
        ),
        None,
    )
    if section and section["kind"] != "mcq":
        raise HTTPException(
            422,
            detail=(
                f"{exam_type} {section['name']} is a {section['kind']} section, "
                "not a generic MCQ quiz. Open Exam Format to practise it in "
                "the correct section mode."
            ),
        )


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


EXAM_PRACTICE_SETTINGS: dict[str, dict] = {
    "IELTS": {"questions": 40, "minutes": 165, "marks": 1.0},
    "SAT": {"questions": 98, "minutes": 134, "marks": 1.0},
    "ECAT": {"questions": 100, "minutes": 100, "marks": 1.0},
    "NUST NET": {"questions": 200, "minutes": 180, "marks": 1.0},
    "NTS": {"questions": 100, "minutes": 120, "marks": 1.0},
    "CSS": {"questions": 100, "minutes": 120, "marks": 1.0},
    "LAT": {"questions": 75, "minutes": 100, "marks": 1.0},
    "PMS": {"questions": 100, "minutes": 120, "marks": 1.0},
    "General Knowledge": {"questions": 100, "minutes": 120, "marks": 1.0},
}


def _balanced_subject_breakdown(exam_type: str, total: int) -> dict[str, int]:
    subjects = EXAM_CATALOG[exam_type]
    counts = {subject: total // len(subjects) for subject in subjects}
    for subject in subjects[:total % len(subjects)]:
        counts[subject] += 1
    return counts


def _past_paper_patterns_for(exam_type: str) -> dict[str, dict]:
    if exam_type == "MDCAT":
        result = {}
        for paper_id, paper in PAST_PAPER_PATTERNS.items():
            year = next(
                (int(token) for token in paper["title"].split() if token.isdigit() and len(token) == 4),
                2025,
            )
            result[paper_id] = {
                **paper,
                "exam_type": exam_type,
                "year": year,
                "subject": "All Subjects",
                "board": "UHS" if "UHS" in paper["title"] else "PM&DC",
                "source_type": "practice",
                "is_official": False,
                "download_available": True,
                "official_source": get_exam_format(exam_type)["official_source"],
            }
        return result

    settings = EXAM_PRACTICE_SETTINGS[exam_type]
    slug = exam_type.lower().replace(" ", "-")
    if exam_type == "IELTS":
        names = [
            "IELTS Academic Practice Pattern 2025",
            "IELTS General Training Practice Pattern 2025",
            "IELTS Academic Practice Pattern 2024",
        ]
    else:
        names = [
            f"{exam_type} Practice Pattern 2025",
            f"{exam_type} Practice Pattern 2024",
            f"{exam_type} Practice Pattern 2023",
        ]
    return {
        f"{slug}-practice-{index + 1}": {
            "title": title,
            "total_questions": settings["questions"],
            "quiz_minutes": settings["minutes"],
            "marks_per_correct": settings["marks"],
            "marks_penalty_per_wrong": 0.0,
            "subject_breakdown": _balanced_subject_breakdown(
                exam_type, settings["questions"]
            ),
            "exam_type": exam_type,
            "year": 2025 - index,
            "subject": "All Subjects",
            "board": "Official exam format",
            "source_type": "practice",
            "is_official": False,
            "download_available": True,
            "official_source": get_exam_format(exam_type)["official_source"],
        }
        for index, title in enumerate(names)
    }


def _official_format_reference(exam_type: str) -> tuple[str, dict] | None:
    profile = get_exam_format(exam_type)
    if not profile.get("official_source"):
        return None
    slug = exam_type.lower().replace(" ", "-")
    breakdown = {
        section["name"]: section["questions"]
        for section in profile["sections"]
        if section.get("questions")
    }
    total = sum(breakdown.values()) or profile["total_questions"]
    resource_source = {
        "IELTS": (
            "https://ielts.org/take-a-test/preparation-resources/"
            "sample-test-questions/academic-test"
        ),
    }.get(exam_type, profile["official_source"])
    return f"official-{slug}", {
        "title": f"{profile['title']} — official format and resources",
        "total_questions": total,
        "quiz_minutes": profile["duration_minutes"],
        "marks_per_correct": 1.0,
        "marks_penalty_per_wrong": profile["negative_marking"],
        "subject_breakdown": breakdown,
        "exam_type": exam_type,
        "year": int(profile["version"]) if str(profile["version"]).isdigit() else 2026,
        "subject": "All Sections",
        "board": "Official authority",
        "source_type": "official",
        "is_official": True,
        "download_available": False,
        "official_source": resource_source,
    }

PAST_PAPER_INSTRUCTIONS = [
    "All questions are compulsory",
    "Each question carries the marks shown above",
    "Marks are deducted for each wrong answer as shown above",
    "No mark is deducted for unanswered questions",
    "Use of calculator is not allowed",
    "This is an original practice set following this exam's official "
    "pattern — not a reproduction of the original paper's questions.",
]

OFFICIAL_RESOURCE_INSTRUCTIONS = [
    "This entry links to the examination authority's own format or sample resources.",
    "Always check the authority page again before registration because rules can change.",
    "Official material is linked, not copied or republished by this app.",
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

    exam_type = _exam_for_request(current_user, payload.exam_type)
    _require_objective_section(exam_type, payload.subject)
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
        mode=payload.mode,
        negative_marking=0.0,
        format_version=get_exam_format(exam_type)["version"],
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


@router.get("/exam-format")
def current_exam_format(
    exam_type: str | None = Query(default=None),
    current_user: User = Depends(get_current_user),
):
    selected_exam = _exam_for_request(current_user, exam_type)
    return {"exam_type": selected_exam, **get_exam_format(selected_exam)}


@router.get("/subjects", response_model=List[TopicListItem])
def list_subjects_and_topics(
    exam_type: str | None = Query(default=None),
    current_user: User = Depends(get_current_user),
):
    """Subjects for the exam category selected during signup."""
    selected_exam = _exam_for_request(current_user, exam_type)
    if selected_exam != "MDCAT":
        return [
            TopicListItem(subject=subject, topics=topics)
            for subject, topics in get_exam_topics(selected_exam).items()
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

    exam_type = _exam_for_request(current_user, payload.exam_type)
    profile = get_exam_format(exam_type)
    if payload.official_format:
        counts = dict(profile["mock_breakdown"])
        expected_total = sum(counts.values())
        quiz_minutes = int(profile["duration_minutes"])
    else:
        expected_total = payload.total_questions
        quiz_minutes = payload.quiz_minutes
        counts = _allocate_exam_practice_questions(exam_type, expected_total)

    # Daily challenges use a small mixed test. Generating each section in a
    # separate provider request makes the browser wait for five sequential
    # network calls. Use one mixed request, then fall back locally if needed.
    if not payload.official_format and expected_total <= 20:
        subjects = ", ".join(counts)
        try:
            all_questions = generate_large_mcqs(
                total_questions=expected_total,
                subject=f"Mixed sections: {subjects}",
                difficulty=payload.difficulty,
                exam_type=exam_type,
            )
        except Exception:
            logger.warning("Mixed daily quiz provider request failed", exc_info=True)
            all_questions = []
        missing = expected_total - min(len(all_questions), expected_total)
        if missing:
            fallback: list[dict] = []
            for subject, count in counts.items():
                fallback.extend(
                    _offline_download_questions(
                        exam_type=exam_type,
                        subject=subject,
                        count=count,
                    )
                )
            all_questions.extend(fallback[:missing])
        all_questions = all_questions[:expected_total]
    else:
        for subject, count in counts.items():
            questions = generate_large_mcqs(
                total_questions=count,
                subject=subject,
                difficulty=payload.difficulty,
                exam_type=exam_type,
            )
            _require_exact_questions(questions, count)
            all_questions.extend(questions)

    _require_exact_questions(all_questions, expected_total)

    quiz_set = QuizSet(
        user_id=current_user.id,
        exam_type=exam_type,
        subject="Mixed (Mock Test)",
        difficulty=payload.difficulty,
        quiz_minutes=quiz_minutes,
        mode=(
            "official_mock"
            if payload.official_format and profile["supports_full_mcq_mock"]
            else "structured_practice_mock"
            if payload.official_format
            else "mock_test"
        ),
        negative_marking=profile["negative_marking"] if payload.official_format else 0.0,
        format_version=profile["version"],
        section_config=profile["sections"] if payload.official_format else None,
        source_filename=None,
        questions=all_questions,
    )
    db.add(quiz_set)
    db.commit()
    db.refresh(quiz_set)
    return quiz_set


@router.post("/adaptive-practice", response_model=QuizSetOut)
def generate_adaptive_practice(
    payload: AdaptivePracticeRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_test_access),
):
    """Generate a test weighted toward weak topics and away from mastered ones."""
    exam_type = current_user.target_exam
    if not get_exam_format(exam_type)["supports_full_mcq_mock"]:
        raise HTTPException(
            422,
            detail=(
                f"Adaptive MCQ practice is not available for {exam_type}. "
                "Open Exam Format for skill-specific practice."
            ),
        )
    topic_catalog = get_exam_topics(exam_type)
    analysis = learning_breakdown(db, current_user)
    measured = analysis["topic_scores"]

    candidates: list[dict] = []
    if measured:
        # A low accuracy produces a higher allocation weight. Mastered topics
        # remain represented, but receive far fewer questions.
        for item in measured:
            accuracy = float(item["accuracy"])
            weight = 4 if accuracy < 50 else 3 if accuracy < 70 else 1
            candidates.extend([item] * weight)
    else:
        candidates = [
            {"subject": subject, "topic": topic, "accuracy": 0.0}
            for subject, topics in topic_catalog.items()
            for topic in topics[:2]
        ]

    if not candidates:
        raise HTTPException(422, detail="No syllabus topics are available for this exam")

    allocation = Counter()
    for index in range(payload.number_of_questions):
        item = candidates[index % len(candidates)]
        allocation[(item["subject"], item["topic"])] += 1

    questions: list[dict] = []
    plan = []
    for (subject, topic), count in allocation.items():
        generated = generate_large_mcqs(
            total_questions=count,
            subject=subject,
            topic=topic,
            difficulty=payload.difficulty,
            exam_type=exam_type,
        )
        _require_exact_questions(generated, count)
        questions.extend(generated)
        plan.append({"subject": subject, "topic": topic, "questions": count})

    _require_exact_questions(questions, payload.number_of_questions)
    quiz_set = QuizSet(
        user_id=current_user.id,
        exam_type=exam_type,
        subject="Adaptive Practice",
        difficulty=payload.difficulty,
        quiz_minutes=payload.quiz_minutes,
        mode="adaptive",
        negative_marking=0.0,
        format_version=get_exam_format(exam_type)["version"],
        section_config=plan,
        source_filename=None,
        questions=questions,
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
def list_past_papers(
    exam_type: str | None = Query(default=None),
    year: int | None = Query(default=None),
    subject: str | None = Query(default=None),
    board: str | None = Query(default=None),
    source_type: str | None = Query(default=None, pattern="^(official|practice)$"),
    current_user: User = Depends(get_current_user),
):
    selected_exam = _exam_for_request(current_user, exam_type)
    patterns = _past_paper_patterns_for(selected_exam)
    reference = _official_format_reference(selected_exam)
    if reference:
        patterns[reference[0]] = reference[1]
    rows = [
        PastPaperSummary(
            id=paper_id,
            title=p["title"],
            total_questions=p["total_questions"],
            quiz_minutes=p["quiz_minutes"],
            exam_type=p["exam_type"],
            year=p["year"],
            subject=p["subject"],
            board=p["board"],
            source_type=p["source_type"],
            is_official=p["is_official"],
            download_available=p["download_available"],
            official_source=p.get("official_source"),
        )
        for paper_id, p in patterns.items()
    ]
    if year is not None:
        rows = [item for item in rows if item.year == year]
    if subject:
        rows = [item for item in rows if subject.lower() in item.subject.lower()]
    if board:
        rows = [item for item in rows if board.lower() in item.board.lower()]
    if source_type:
        rows = [item for item in rows if item.source_type == source_type]
    return rows


@router.get("/past-papers/{paper_id}", response_model=PastPaperDetail)
def get_past_paper_detail(
    paper_id: str,
    current_user: User = Depends(get_current_user),
):
    exam_type = current_user.target_exam
    patterns = _past_paper_patterns_for(exam_type)
    reference = _official_format_reference(exam_type)
    if reference:
        patterns[reference[0]] = reference[1]
    paper = patterns.get(paper_id)
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
        instructions=(
            OFFICIAL_RESOURCE_INSTRUCTIONS
            if paper["is_official"]
            else PAST_PAPER_INSTRUCTIONS
        ),
        exam_type=paper["exam_type"],
        year=paper["year"],
        subject=paper["subject"],
        board=paper["board"],
        source_type=paper["source_type"],
        is_official=paper["is_official"],
        official_source=paper.get("official_source"),
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
    exam_type = current_user.target_exam
    paper = _past_paper_patterns_for(exam_type).get(paper_id)
    if not paper:
        raise HTTPException(404, detail="Past paper pattern not found")
    if paper.get("is_official"):
        raise HTTPException(422, detail="Open the official source instead of generating it")

    all_questions: list[dict] = []
    for subject, count in paper["subject_breakdown"].items():
        if count <= 0:
            continue
        questions = generate_large_mcqs(
            total_questions=count,
            subject=subject,
            difficulty="Medium",
            exam_type=exam_type,
        )
        _require_exact_questions(questions, count)
        all_questions.extend(questions)

    _require_exact_questions(all_questions, paper["total_questions"])

    quiz_set = QuizSet(
        user_id=current_user.id,
        exam_type=exam_type,
        subject=f"Past Paper Pattern: {paper['title']}",
        difficulty="Medium",
        quiz_minutes=paper["quiz_minutes"],
        mode="past_paper_practice",
        negative_marking=paper["marks_penalty_per_wrong"],
        format_version=get_exam_format(exam_type)["version"],
        section_config=[
            {"subject": subject, "questions": count}
            for subject, count in paper["subject_breakdown"].items()
        ],
        source_filename=None,
        questions=all_questions,
    )
    db.add(quiz_set)
    db.commit()
    db.refresh(quiz_set)
    return quiz_set


@router.get("/past-papers/{paper_id}/download")
def download_practice_paper(
    paper_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_test_access),
):
    """Create an original practice paper PDF for offline study."""
    exam_type = current_user.target_exam
    paper = _past_paper_patterns_for(exam_type).get(paper_id)
    if not paper or not paper.get("download_available", True):
        raise HTTPException(404, detail="A downloadable practice paper is not available")

    questions = _build_download_questions(
        exam_type=exam_type,
        subject_breakdown=paper["subject_breakdown"],
    )
    path = create_practice_paper_pdf(
        title=f"{paper['title']} - Compact Offline Practice Pack",
        exam_type=exam_type,
        minutes=paper["quiz_minutes"],
        questions=questions,
        negative_marking=paper["marks_penalty_per_wrong"],
    )
    filename = f"{exam_type.replace(' ', '_')}_Practice_{paper['year']}.pdf"
    return FileResponse(path, media_type="application/pdf", filename=filename)


def _remove_expired_download_jobs() -> None:
    cutoff = time.time() - _DOWNLOAD_JOB_TTL_SECONDS
    expired_paths: list[str] = []
    with _download_jobs_lock:
        expired_ids = [
            job_id
            for job_id, job in _download_jobs.items()
            if job["created_at"] < cutoff
        ]
        for job_id in expired_ids:
            job = _download_jobs.pop(job_id)
            if job.get("path"):
                expired_paths.append(job["path"])
    for path in expired_paths:
        try:
            os.remove(path)
        except FileNotFoundError:
            pass


def _prepare_practice_paper_download(
    job_id: str,
    paper: dict,
    exam_type: str,
) -> None:
    try:
        questions = _build_download_questions(
            exam_type=exam_type,
            subject_breakdown=paper["subject_breakdown"],
        )
        path = create_practice_paper_pdf(
            title=f"{paper['title']} - Compact Offline Practice Pack",
            exam_type=exam_type,
            minutes=paper["quiz_minutes"],
            questions=questions,
            negative_marking=paper["marks_penalty_per_wrong"],
        )
        with _download_jobs_lock:
            job = _download_jobs.get(job_id)
            if job:
                job.update(status="ready", path=path)
    except Exception:
        logger.exception("Practice-paper download job %s failed", job_id)
        # Avoid exposing provider or infrastructure details to the client.
        with _download_jobs_lock:
            job = _download_jobs.get(job_id)
            if job:
                job.update(
                    status="failed",
                    error="The practice paper could not be prepared. Please try again.",
                )


@router.post("/past-papers/{paper_id}/download-jobs", status_code=202)
def start_practice_paper_download(
    paper_id: str,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(require_test_access),
):
    """Prepare a large PDF outside the browser request to avoid proxy timeouts."""
    _remove_expired_download_jobs()
    exam_type = current_user.target_exam
    paper = _past_paper_patterns_for(exam_type).get(paper_id)
    if not paper or not paper.get("download_available", True):
        raise HTTPException(404, detail="A downloadable practice paper is not available")

    job_id = uuid.uuid4().hex
    filename = f"{exam_type.replace(' ', '_')}_Practice_{paper['year']}.pdf"
    with _download_jobs_lock:
        _download_jobs[job_id] = {
            "user_id": current_user.id,
            "status": "preparing",
            "created_at": time.time(),
            "filename": filename,
            "path": None,
            "error": None,
        }
    background_tasks.add_task(
        _prepare_practice_paper_download,
        job_id,
        dict(paper),
        exam_type,
    )
    return {"job_id": job_id, "status": "preparing"}


@router.get("/past-papers/download-jobs/{job_id}")
def get_practice_paper_download(
    job_id: str,
    current_user: User = Depends(get_current_user),
):
    with _download_jobs_lock:
        job = _download_jobs.get(job_id)
        snapshot = dict(job) if job else None
    if not snapshot or snapshot["user_id"] != current_user.id:
        raise HTTPException(404, detail="Download preparation was not found")
    if snapshot["status"] == "failed":
        raise HTTPException(502, detail=snapshot["error"])
    if snapshot["status"] != "ready":
        return {"job_id": job_id, "status": "preparing"}
    return FileResponse(
        snapshot["path"],
        media_type="application/pdf",
        filename=snapshot["filename"],
    )


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
