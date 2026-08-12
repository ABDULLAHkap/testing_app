from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models.models import QuizSet, User
from app.schemas import QuizSetSummary

router = APIRouter(prefix="/mcqs", tags=["mcqs"])


@router.get("", response_model=List[QuizSetSummary])
def list_category_quiz_sets(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(QuizSet).filter(QuizSet.user_id == current_user.id)
    if not current_user.is_admin:
        query = query.filter(QuizSet.exam_type == current_user.target_exam)
    sets = query.order_by(QuizSet.created_at.desc()).all()
    return [
        QuizSetSummary(
            id=item.id,
            subject=item.subject,
            difficulty=item.difficulty,
            quiz_minutes=item.quiz_minutes,
            question_count=len(item.questions),
            created_at=item.created_at,
        )
        for item in sets
    ]
