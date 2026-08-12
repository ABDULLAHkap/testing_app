from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.exam_catalog import ensure_exam
from app.models.models import User
from app.services.category_subscriptions import subscription_expiry

router = APIRouter(prefix="/account", tags=["account"])


class ExamCategoryUpdate(BaseModel):
    target_exam: str = Field(min_length=2, max_length=30)


@router.put("/exam-category")
def update_exam_category(
    payload: ExamCategoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.is_admin:
        raise HTTPException(403, detail="Admin accounts select test categories inside testing screens")
    try:
        exam_type = ensure_exam(payload.target_exam)
    except ValueError as exc:
        raise HTTPException(422, detail=str(exc)) from exc

    current_user.target_exam = exam_type
    db.commit()
    db.refresh(current_user)
    expires = subscription_expiry(db, current_user.id, exam_type)
    return {
        "id": current_user.id,
        "target_exam": current_user.target_exam,
        "free_tests_remaining": current_user.free_tests_remaining,
        "subscription_expires_at": expires,
    }
