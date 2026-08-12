from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.auth import require_admin
from app.database import get_db
from app.exam_catalog import ensure_exam
from app.models.exam_subscription import ExamSubscription
from app.models.models import (
    Announcement,
    AnnouncementRead,
    EmailChangeCode,
    EmailVerificationCode,
    PasswordResetCode,
    Payment,
    QuizAttempt,
    QuizSet,
    SupportMessage,
    User,
)
from app.services.app_settings import get_subscription_price, set_subscription_price

router = APIRouter(prefix="/admin", tags=["admin"])


class SubscriptionGrant(BaseModel):
    days: int = Field(default=30, ge=1, le=366)
    exam_type: str | None = Field(default=None, min_length=2, max_length=30)


class SubscriptionPriceUpdate(BaseModel):
    price_pkr: int = Field(ge=1, le=1_000_000)


def _aware(value: datetime | None) -> datetime | None:
    if value is not None and value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value


def _selected_subscription(db: Session, user: User) -> ExamSubscription | None:
    return (
        db.query(ExamSubscription)
        .filter(
            ExamSubscription.user_id == user.id,
            ExamSubscription.exam_type == user.target_exam,
        )
        .first()
    )


@router.get("/subscription-settings")
def subscription_settings(
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    return {
        "price_pkr": get_subscription_price(db),
        "currency": "PKR",
        "days": 30,
    }


@router.put("/subscription-settings")
def update_subscription_settings(
    payload: SubscriptionPriceUpdate,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    price = set_subscription_price(db, payload.price_pkr)
    return {
        "message": "Subscription price updated",
        "price_pkr": price,
        "currency": "PKR",
        "days": 30,
    }


@router.get("/overview")
def overview(db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    online_since = datetime.now(timezone.utc) - timedelta(minutes=2)
    return {
        "users": db.query(User).count(),
        "verified_users": db.query(User).filter(User.email_verified.is_(True)).count(),
        "completed_tests": db.query(QuizAttempt).filter(QuizAttempt.finished_at.isnot(None)).count(),
        "successful_payments": db.query(Payment).filter(Payment.status == "paid").count(),
        "online_users": db.query(User).filter(
            User.is_admin.is_(False), User.last_seen_at >= online_since
        ).count(),
    }


@router.get("/users")
def list_users(db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    online_since = datetime.now(timezone.utc) - timedelta(minutes=2)
    users = db.query(User).order_by(User.created_at.desc()).limit(500).all()
    result = []
    for user in users:
        finished = [attempt for attempt in user.attempts if attempt.finished_at is not None]
        tests_done = len(finished)
        average = round(sum(attempt.percentage for attempt in finished) / tests_done, 1) if tests_done else 0.0
        best = round(max((attempt.percentage for attempt in finished), default=0.0), 1)
        last_test = max((attempt.finished_at for attempt in finished), default=None)
        subscriptions = (
            db.query(ExamSubscription)
            .filter(ExamSubscription.user_id == user.id)
            .order_by(ExamSubscription.exam_type.asc())
            .all()
        )
        selected = next(
            (item for item in subscriptions if item.exam_type == user.target_exam),
            None,
        )
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
            "subscription_expires_at": selected.expires_at if selected else None,
            "category_subscriptions": [
                {"exam_type": item.exam_type, "expires_at": item.expires_at}
                for item in subscriptions
            ],
            "created_at": user.created_at,
            "exam_date": user.exam_date,
            "tests_done": tests_done,
            "average_score": average,
            "best_score": best,
            "last_test_at": last_test,
            "last_seen_at": user.last_seen_at,
            "is_online": bool(
                user.last_seen_at and user.last_seen_at.replace(tzinfo=timezone.utc) >= online_since
            ),
        })
    return result


@router.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(404, detail="User not found")
    if user.id == admin.id:
        raise HTTPException(400, detail="You cannot delete your own administrator account")
    if user.is_admin:
        raise HTTPException(400, detail="Administrator accounts cannot be deleted here")

    authored_announcement_ids = [
        row[0]
        for row in db.query(Announcement.id).filter(Announcement.admin_id == user.id).all()
    ]
    reads = db.query(AnnouncementRead).filter(AnnouncementRead.user_id == user.id)
    if authored_announcement_ids:
        reads = db.query(AnnouncementRead).filter(
            (AnnouncementRead.user_id == user.id)
            | (AnnouncementRead.announcement_id.in_(authored_announcement_ids))
        )
    reads.delete(synchronize_session=False)
    db.query(SupportMessage).filter(
        (SupportMessage.student_id == user.id) | (SupportMessage.sender_id == user.id)
    ).delete(synchronize_session=False)
    db.query(Payment).filter(Payment.user_id == user.id).delete(synchronize_session=False)
    db.query(ExamSubscription).filter(ExamSubscription.user_id == user.id).delete(synchronize_session=False)
    db.query(EmailChangeCode).filter(EmailChangeCode.user_id == user.id).delete(synchronize_session=False)
    db.query(PasswordResetCode).filter(PasswordResetCode.user_id == user.id).delete(synchronize_session=False)
    db.query(EmailVerificationCode).filter(EmailVerificationCode.user_id == user.id).delete(synchronize_session=False)
    db.query(QuizAttempt).filter(QuizAttempt.user_id == user.id).delete(synchronize_session=False)
    db.query(QuizSet).filter(QuizSet.user_id == user.id).delete(synchronize_session=False)
    if authored_announcement_ids:
        db.query(Announcement).filter(Announcement.id.in_(authored_announcement_ids)).delete(
            synchronize_session=False
        )
    db.delete(user)
    db.commit()
    return {"message": "Student profile deleted"}


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
    try:
        exam_type = ensure_exam(payload.exam_type or user.target_exam)
    except ValueError as exc:
        raise HTTPException(422, detail=str(exc)) from exc

    subscription = (
        db.query(ExamSubscription)
        .filter(
            ExamSubscription.user_id == user.id,
            ExamSubscription.exam_type == exam_type,
        )
        .first()
    )
    now = datetime.now(timezone.utc)
    current_expiry = _aware(subscription.expires_at) if subscription else None
    start = current_expiry if current_expiry and current_expiry > now else now
    expires_at = start + timedelta(days=payload.days)
    if subscription:
        subscription.expires_at = expires_at
    else:
        db.add(
            ExamSubscription(
                user_id=user.id,
                exam_type=exam_type,
                expires_at=expires_at,
            )
        )
    db.commit()
    return {
        "message": "Subscription activated",
        "exam_type": exam_type,
        "expires_at": expires_at,
    }


@router.delete("/users/{user_id}/subscription")
def remove_subscription(
    user_id: int,
    exam_type: str | None = None,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(404, detail="User not found")
    if user.is_admin:
        raise HTTPException(400, detail="An administrator's access cannot be removed")
    try:
        selected_exam = ensure_exam(exam_type or user.target_exam)
    except ValueError as exc:
        raise HTTPException(422, detail=str(exc)) from exc

    db.query(ExamSubscription).filter(
        ExamSubscription.user_id == user.id,
        ExamSubscription.exam_type == selected_exam,
    ).delete(synchronize_session=False)
    db.commit()
    return {
        "message": "Subscription removed",
        "exam_type": selected_exam,
        "free_tests_remaining": user.free_tests_remaining,
    }
