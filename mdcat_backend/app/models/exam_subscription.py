from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, UniqueConstraint

from app.database import Base


def now_utc():
    return datetime.now(timezone.utc)


class ExamSubscription(Base):
    """Paid access for one exam category on one student account."""

    __tablename__ = "exam_subscriptions"
    __table_args__ = (UniqueConstraint("user_id", "exam_type", name="uq_exam_subscription_user_exam"),)

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    exam_type = Column(String(30), nullable=False, index=True)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=now_utc, nullable=False)
