from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.exam_catalog import ensure_exam
from app.models.exam_subscription import ExamSubscription
from app.models.models import User

router = APIRouter(prefix="/auth", tags=["auth"])


class ExamCategoryUpdate(BaseModel):
    target_exam: str = Field(min_length=2, max_length=30)


@router.put("/exam-category")
def update_exam_category(
    payload: ExamCategoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.is_admin:
        raise HTTPException(400, detail="Admins choose test categories from the dashboard")
    try:
        target_exam = ensure_exam(payload.target_exam)
    except ValueError as exc:
        raise HTTPException(422, detail=str(exc)) from exc

    subscription = (
        db.query(ExamSubscription)
        .filter(
            ExamSubscription.user_id == current_user.id,
            ExamSubscription.exam_type == target_exam,
        )
        .first()
    )
    current_user.target_exam = target_exam
    # Keep the legacy field as a mirror of the currently selected category.
    # Access checks use ExamSubscription, so this never unlocks other exams.
    current_user.subscription_expires_at = (
        subscription.expires_at if subscription else None
    )
    db.commit()
    db.refresh(current_user)

    return {
        "message": "Exam category updated",
        "target_exam": current_user.target_exam,
        "free_tests_remaining": current_user.free_tests_remaining,
        "subscription_expires_at": subscription.expires_at if subscription else None,
    }
