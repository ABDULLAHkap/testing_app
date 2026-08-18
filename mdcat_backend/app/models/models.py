from datetime import datetime, timezone

from sqlalchemy import (
    Column, Integer, String, Text, Float, ForeignKey, DateTime, JSON, Boolean,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from app.database import Base


def now_utc():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(120), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=now_utc)
    exam_date = Column(DateTime, nullable=True)
    gender = Column(String(20), nullable=True)
    phone = Column(String(30), nullable=True)
    target_exam = Column(String(30), default="MDCAT", nullable=False)
    email_verified = Column(Boolean, default=False, nullable=False)
    is_admin = Column(Boolean, default=False, nullable=False)
    subscription_expires_at = Column(DateTime, nullable=True)
    last_seen_at = Column(DateTime, nullable=True, index=True)

    quiz_sets = relationship("QuizSet", back_populates="owner", cascade="all, delete-orphan")
    attempts = relationship("QuizAttempt", back_populates="user", cascade="all, delete-orphan")
    verification_codes = relationship("EmailVerificationCode", cascade="all, delete-orphan")
    password_reset_codes = relationship("PasswordResetCode", cascade="all, delete-orphan")
    email_change_codes = relationship("EmailChangeCode", cascade="all, delete-orphan")
    push_devices = relationship("PushDevice", cascade="all, delete-orphan")

    @property
    def free_tests_remaining(self):
        completed = sum(1 for attempt in self.attempts if attempt.finished_at is not None)
        return max(0, 3 - completed)


class EmailVerificationCode(Base):
    __tablename__ = "email_verification_codes"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    code_hash = Column(String(64), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    used_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=now_utc)


class PasswordResetCode(Base):
    __tablename__ = "password_reset_codes"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    code_hash = Column(String(64), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    used_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=now_utc)


class EmailChangeCode(Base):
    __tablename__ = "email_change_codes"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    new_email = Column(String(120), nullable=False)
    code_hash = Column(String(64), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    used_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=now_utc)


class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(Integer, primary_key=True)
    admin_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(120), nullable=False)
    message = Column(Text, nullable=False)
    created_at = Column(DateTime, default=now_utc, index=True)


class AnnouncementRead(Base):
    __tablename__ = "announcement_reads"
    __table_args__ = (UniqueConstraint("user_id", "announcement_id"),)

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    announcement_id = Column(Integer, ForeignKey("announcements.id"), nullable=False)
    read_at = Column(DateTime, default=now_utc)


class SupportMessage(Base):
    __tablename__ = "support_messages"

    id = Column(Integer, primary_key=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message = Column(Text, nullable=False)
    created_at = Column(DateTime, default=now_utc, index=True)


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    provider = Column(String(30), default="jazzcash", nullable=False)
    transaction_ref = Column(String(80), unique=True, nullable=False, index=True)
    amount_pkr = Column(Integer, nullable=False)
    status = Column(String(20), default="pending", nullable=False)
    provider_response = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=now_utc)
    completed_at = Column(DateTime, nullable=True)


class AppSetting(Base):
    """Database-backed application settings editable by administrators."""

    __tablename__ = "app_settings"

    key = Column(String(100), primary_key=True)
    value = Column(String(500), nullable=False)
    updated_at = Column(DateTime, default=now_utc, onupdate=now_utc)


class QuizSet(Base):
    """A generated batch of MCQs (one 'Generate MCQs' click)."""
    __tablename__ = "quiz_sets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Past-paper display titles include the authority, year and paper ID and
    # can legitimately exceed the original 50-character limit.
    subject = Column(String(255), nullable=False)
    exam_type = Column(String(30), default="MDCAT", nullable=False)
    difficulty = Column(String(20), nullable=False)
    quiz_minutes = Column(Integer, default=30)
    mode = Column(String(30), default="topic", nullable=False)
    negative_marking = Column(Float, default=0.0, nullable=False)
    format_version = Column(String(80), nullable=True)
    section_config = Column(JSON, nullable=True)

    source_filename = Column(String(255), nullable=True)
    # Structured MCQs stored as JSON list of:
    # {question, options: [a,b,c,d], correct_option: "A", explanation}
    questions = Column(JSON, nullable=False)

    created_at = Column(DateTime, default=now_utc)

    owner = relationship("User", back_populates="quiz_sets")
    attempts = relationship("QuizAttempt", back_populates="quiz_set", cascade="all, delete-orphan")


class QuizAttempt(Base):
    """A student's completed (or in-progress) attempt at a QuizSet."""
    __tablename__ = "quiz_attempts"

    id = Column(Integer, primary_key=True, index=True)
    quiz_set_id = Column(Integer, ForeignKey("quiz_sets.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # answers: {"0": "A) ...", "1": "B) ..."} keyed by question index
    answers = Column(JSON, default=dict)
    # Seconds spent on each question: {"0": 18, "1": 42, ...}.
    question_times = Column(JSON, default=dict)

    correct = Column(Integer, default=0)
    wrong = Column(Integer, default=0)
    total = Column(Integer, default=0)
    percentage = Column(Float, default=0.0)
    grade = Column(String(5), default="")

    started_at = Column(DateTime, default=now_utc)
    finished_at = Column(DateTime, nullable=True)

    quiz_set = relationship("QuizSet", back_populates="attempts")
    user = relationship("User", back_populates="attempts")


class PushDevice(Base):
    """A device/browser registered to receive Firebase Cloud Messaging."""

    __tablename__ = "push_devices"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    token = Column(String(512), unique=True, nullable=False, index=True)
    platform = Column(String(20), default="unknown", nullable=False)
    timezone_offset_minutes = Column(Integer, default=0, nullable=False)
    announcements_enabled = Column(Boolean, default=True, nullable=False)
    study_reminders_enabled = Column(Boolean, default=True, nullable=False)
    exam_alerts_enabled = Column(Boolean, default=True, nullable=False)
    subscription_alerts_enabled = Column(Boolean, default=True, nullable=False)
    active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=now_utc)
    updated_at = Column(DateTime, default=now_utc, onupdate=now_utc)
    last_study_reminder_date = Column(String(10), nullable=True)
    last_exam_alert_key = Column(String(40), nullable=True)
    last_subscription_alert_key = Column(String(40), nullable=True)
