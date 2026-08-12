from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models.models import User, QuizAttempt, QuizSet
from app.schemas import ProgressPoint
from app.services.analytics_service import advanced_analytics

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
            QuizSet.exam_type == current_user.target_exam,
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
            exam_type=quiz_set.exam_type,
            total_time_seconds=sum((attempt.question_times or {}).values()),
            percentage=attempt.percentage,
            grade=attempt.grade,
            finished_at=attempt.finished_at,
        )
        for attempt, quiz_set in attempts
    ]


@router.get("/analytics")
def get_advanced_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return advanced_analytics(db, current_user)
