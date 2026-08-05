from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.auth import require_admin
from app.database import get_db
from app.models.models import User, QuizAttempt, Payment

router = APIRouter(prefix="/admin", tags=["admin"])


class SubscriptionGrant(BaseModel):
    days: int = Field(default=30, ge=1, le=366)


@router.get("/overview")
def overview(db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    return {
        "users": db.query(User).count(),
        "verified_users": db.query(User).filter(User.email_verified.is_(True)).count(),
        "completed_tests": db.query(QuizAttempt).filter(QuizAttempt.finished_at.isnot(None)).count(),
        "successful_payments": db.query(Payment).filter(Payment.status == "paid").count(),
    }


@router.get("/users")
def list_users(db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    users = db.query(User).order_by(User.created_at.desc()).limit(500).all()
    return [
        {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "phone": user.phone,
            "gender": user.gender,
            "target_exam": user.target_exam,
            "email_verified": user.email_verified,
            "is_admin": user.is_admin,
            "free_tests_remaining": user.free_tests_remaining,
            "subscription_expires_at": user.subscription_expires_at,
            "created_at": user.created_at,
        }
        for user in users
    ]


@router.post("/users/{user_id}/subscription")
def grant_subscription(
    user_id: int,
    payload: SubscriptionGrant,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(404, detail="User not found")
    now = datetime.now(timezone.utc)
    start = user.subscription_expires_at or now
    if start.tzinfo is None:
        start = start.replace(tzinfo=timezone.utc)
    if start < now:
        start = now
    user.subscription_expires_at = start + timedelta(days=payload.days)
    db.commit()
    return {"message": "Subscription activated", "expires_at": user.subscription_expires_at}
