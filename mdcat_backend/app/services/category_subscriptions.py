from datetime import datetime, timedelta, timezone

from sqlalchemy import text
from sqlalchemy.orm import Session


def _aware(value):
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value


def subscription_expiry(db: Session, user_id: int, exam_type: str):
    row = db.execute(
        text(
            "SELECT expires_at FROM exam_subscriptions "
            "WHERE user_id = :user_id AND exam_type = :exam_type"
        ),
        {"user_id": user_id, "exam_type": exam_type},
    ).first()
    return _aware(row[0]) if row else None


def has_active_subscription(db: Session, user_id: int, exam_type: str) -> bool:
    expires = subscription_expiry(db, user_id, exam_type)
    return bool(expires and expires > datetime.now(timezone.utc))


def extend_subscription(db: Session, user_id: int, exam_type: str, days: int):
    now = datetime.now(timezone.utc)
    current = subscription_expiry(db, user_id, exam_type)
    start = current if current and current > now else now
    expires = start + timedelta(days=days)
    db.execute(
        text(
            "INSERT INTO exam_subscriptions (user_id, exam_type, expires_at, created_at, updated_at) "
            "VALUES (:user_id, :exam_type, :expires_at, :now, :now) "
            "ON CONFLICT (user_id, exam_type) DO UPDATE SET "
            "expires_at = EXCLUDED.expires_at, updated_at = EXCLUDED.updated_at"
        ),
        {
            "user_id": user_id,
            "exam_type": exam_type,
            "expires_at": expires,
            "now": now,
        },
    )
    return expires


def subscription_map(db: Session, user_id: int) -> dict[str, datetime]:
    rows = db.execute(
        text(
            "SELECT exam_type, expires_at FROM exam_subscriptions "
            "WHERE user_id = :user_id ORDER BY exam_type"
        ),
        {"user_id": user_id},
    ).all()
    return {str(exam): _aware(expires) for exam, expires in rows}
