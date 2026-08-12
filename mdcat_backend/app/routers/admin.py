from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.auth import require_admin
from app.database import get_db
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
from app.services.category_subscriptions import (
    extend_subscription,
    subscription_expiry,
    subscription_map,
)

router = APIRouter(prefix="/admin", tags=["admin"])


class SubscriptionGrant(BaseModel):
    days: int = Field(default=30, ge=1, le=366)


class SubscriptionPriceUpdate(BaseModel):
    price_pkr: int = Field(ge=1, le=1_000_000)


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
        category_subscriptions = {} if user.is_admin else {
            exam: expires.isoformat() if expires else None
            for exam, expires in subscription_map(db, user.id).items()
        }
        selected_expiry = None if user.is_admin else subscription_expiry(
            db, user.id, user.target_exam
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
            "subscription_expires_at": selected_expiry,
            "category_subscriptions": category_subscriptions,
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
    db.query(EmailChangeCode).filter(EmailChangeCode.user_id == user.id).delete(synchronize_session=False)
    db.query(PasswordResetCode).filter(PasswordResetCode.user_id == user.id).delete(synchronize_session=False)
    db.query(EmailVerificationCode).filter(EmailVerificationCode.user_id == user.id).delete(synchronize_session=False)
    db.query(QuizAttempt).filter(QuizAttempt.user_id == user.id).delete(synchronize_session=False)
    db.query(QuizSet).filter(QuizSet.user_id == user.id).delete(synchronize_session=False)
    db.execute(text("DELETE FROM exam_subscriptions WHERE user_id = :user_id"), {"user_id": user.id})
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
    if user.is_admin:
        raise HTTPException(400, detail="Administrators already have unlimited access")
    expires = extend_subscription(db, user.id, user.target_exam, payload.days)
    db.commit()
    return {
        "message": f"{user.target_exam} subscription activated",
        "exam_type": user.target_exam,
        "expires_at": expires,
    }


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

    db.execute(
        text(
            "DELETE FROM exam_subscriptions "
            "WHERE user_id = :user_id AND exam_type = :exam_type"
        ),
        {"user_id": user.id, "exam_type": user.target_exam},
    )
    db.commit()
    return {
        "message": f"{user.target_exam} subscription removed",
        "exam_type": user.target_exam,
        "free_tests_remaining": user.free_tests_remaining,
    }
