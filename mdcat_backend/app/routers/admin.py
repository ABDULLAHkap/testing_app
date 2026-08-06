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
    result = []
    for user in users:
        finished = [attempt for attempt in user.attempts if attempt.finished_at is not None]
        tests_done = len(finished)
        average = round(sum(attempt.percentage for attempt in finished) / tests_done, 1) if tests_done else 0.0
        best = round(max((attempt.percentage for attempt in finished), default=0.0), 1)
        last_test = max((attempt.finished_at for attempt in finished), default=None)
        result.append({
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
            "exam_date": user.exam_date,
            "tests_done": tests_done,
            "average_score": average,
            "best_score": best,
            "last_test_at": last_test,
        })
    return result


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


@router.delete("/users/{user_id}/subscription")
def remove_subscription(
    user_id: int,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(404, detail="User not found")
    if user.is_admin:
        raise HTTPException(400, detail="An administrator's access cannot be removed")

    user.subscription_expires_at = None
    db.commit()
    return {
        "message": "Subscription removed",
        "free_tests_remaining": user.free_tests_remaining,
    }
