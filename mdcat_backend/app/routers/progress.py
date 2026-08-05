from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models.models import User, QuizAttempt, QuizSet
from app.schemas import ProgressPoint

router = APIRouter(prefix="/progress", tags=["progress"])


@router.get("", response_model=List[ProgressPoint])
def get_progress(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    attempts = (
        db.query(QuizAttempt, QuizSet)
        .join(QuizSet, QuizAttempt.quiz_set_id == QuizSet.id)
        .filter(
            QuizAttempt.user_id == current_user.id,
            QuizAttempt.finished_at.isnot(None),
        )
        .order_by(QuizAttempt.finished_at.asc())
        .all()
    )

    return [
        ProgressPoint(
            attempt_id=attempt.id,
            quiz_set_id=quiz_set.id,
            subject=quiz_set.subject,
            difficulty=quiz_set.difficulty,
            percentage=attempt.percentage,
            grade=attempt.grade,
            finished_at=attempt.finished_at,
        )
        for attempt, quiz_set in attempts
    ]
