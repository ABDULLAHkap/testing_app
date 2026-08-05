from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models.models import User, QuizSet, QuizAttempt
from app.schemas import AttemptResult, SubmitAnswersRequest
from app.services.pdf_report import create_result_pdf

router = APIRouter(prefix="/quiz", tags=["quiz"])


def _grade(quiz_set: QuizSet, answers: dict[str, str]) -> dict:
    """
    Server-side grading — never trust a client to self-report its own
    score. `answers` maps question index (as string) -> chosen letter.
    """
    correct = 0
    wrong = 0

    for i, question in enumerate(quiz_set.questions):
        chosen = answers.get(str(i))
        if chosen is None:
            continue
        if chosen == question["correct_option"]:
            correct += 1
        else:
            wrong += 1

    total = len(quiz_set.questions)
    percentage = (correct / total * 100) if total else 0.0

    if percentage >= 90:
        grade = "A+"
    elif percentage >= 80:
        grade = "A"
    elif percentage >= 70:
        grade = "B"
    elif percentage >= 60:
        grade = "C"
    else:
        grade = "F"

    return {
        "correct": correct,
        "wrong": wrong,
        "total": total,
        "percentage": percentage,
        "grade": grade,
    }


@router.post("/{quiz_set_id}/start", response_model=AttemptResult)
def start_attempt(
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

    attempt = QuizAttempt(
        quiz_set_id=quiz_set.id,
        user_id=current_user.id,
        answers={},
        total=len(quiz_set.questions),
    )
    db.add(attempt)
    db.commit()
    db.refresh(attempt)
    return attempt


@router.post("/attempts/{attempt_id}/submit", response_model=AttemptResult)
def submit_attempt(
    attempt_id: int,
    payload: SubmitAnswersRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    attempt = (
        db.query(QuizAttempt)
        .filter(QuizAttempt.id == attempt_id, QuizAttempt.user_id == current_user.id)
        .first()
    )
    if not attempt:
        raise HTTPException(404, detail="Attempt not found")

    if attempt.finished_at is not None:
        raise HTTPException(409, detail="This attempt has already been submitted")

    quiz_set = db.query(QuizSet).filter(QuizSet.id == attempt.quiz_set_id).first()
    if not quiz_set:
        raise HTTPException(404, detail="Quiz set not found")

    invalid_indexes = [
        index for index in payload.answers
        if int(index) >= len(quiz_set.questions)
    ]
    if invalid_indexes:
        raise HTTPException(422, detail="One or more answer indexes are invalid")

    started_at = attempt.started_at
    if started_at.tzinfo is None:
        started_at = started_at.replace(tzinfo=timezone.utc)
    deadline = started_at + timedelta(minutes=quiz_set.quiz_minutes, seconds=30)
    if datetime.now(timezone.utc) > deadline:
        raise HTTPException(409, detail="Quiz time has expired")

    grading = _grade(quiz_set, payload.answers)

    attempt.answers = payload.answers
    attempt.correct = grading["correct"]
    attempt.wrong = grading["wrong"]
    attempt.total = grading["total"]
    attempt.percentage = grading["percentage"]
    attempt.grade = grading["grade"]
    attempt.finished_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(attempt)
    return attempt


@router.get("/attempts/{attempt_id}", response_model=AttemptResult)
def get_attempt(
    attempt_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    attempt = (
        db.query(QuizAttempt)
        .filter(QuizAttempt.id == attempt_id, QuizAttempt.user_id == current_user.id)
        .first()
    )
    if not attempt:
        raise HTTPException(404, detail="Attempt not found")
    return attempt


@router.get("/attempts/{attempt_id}/pdf")
def download_result_pdf(
    attempt_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    attempt = (
        db.query(QuizAttempt)
        .filter(QuizAttempt.id == attempt_id, QuizAttempt.user_id == current_user.id)
        .first()
    )
    if not attempt or not attempt.finished_at:
        raise HTTPException(404, detail="Finished attempt not found")

    quiz_set = db.query(QuizSet).filter(QuizSet.id == attempt.quiz_set_id).first()

    result = {
        "correct": attempt.correct,
        "wrong": attempt.wrong,
        "total": attempt.total,
        "percentage": attempt.percentage,
        "grade": attempt.grade,
    }
    path = create_result_pdf(result, quiz_set.subject, quiz_set.difficulty)
    return FileResponse(path, media_type="application/pdf", filename="Exam_Result.pdf")
