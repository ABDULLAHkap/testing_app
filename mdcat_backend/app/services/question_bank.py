"""Persistent, syllabus-versioned MCQ bank with bounded background refill."""

from __future__ import annotations

import logging
import os
from concurrent.futures import ThreadPoolExecutor
from threading import Lock

from sqlalchemy import func
from sqlalchemy.exc import IntegrityError

from app.database import SessionLocal
from app.models.models import QuestionBankItem, QuizSet, now_utc
from app.services.question_pool import question_fingerprint


logger = logging.getLogger(__name__)
_executor = ThreadPoolExecutor(
    max_workers=max(1, int(os.getenv("QUESTION_BANK_BACKGROUND_WORKERS", "1")))
)
_pending_guard = Lock()
_pending: set[tuple[str, str, str, str, str]] = set()


def store_questions(
    questions: list[dict],
    *,
    exam_type: str,
    subject: str,
    difficulty: str,
    format_version: str,
    topic: str | None = None,
) -> int:
    """Persist provider questions idempotently and return the inserted count."""
    candidate_map = {
        question_fingerprint(question): question
        for question in questions
        if str(question.get("source_type", "")).endswith("_generated")
    }
    candidates = list(candidate_map.values())
    if not candidates:
        return 0
    fingerprints = {question_fingerprint(item) for item in candidates}
    with SessionLocal() as db:
        existing = {
            value for (value,) in db.query(QuestionBankItem.fingerprint).filter(
                QuestionBankItem.exam_type == exam_type,
                QuestionBankItem.format_version == format_version,
                QuestionBankItem.fingerprint.in_(fingerprints),
            ).all()
        }
        items = [QuestionBankItem(
                exam_type=exam_type,
                subject=subject,
                topic=str(topic or question.get("topic") or ""),
                difficulty=difficulty,
                format_version=format_version,
                fingerprint=question_fingerprint(question),
                question=question,
                source_type=str(question.get("source_type") or "ai_generated"),
            ) for question in candidates
            if question_fingerprint(question) not in existing]
        try:
            db.add_all(items)
            db.commit()
            return len(items)
        except IntegrityError:
            # Another worker may have inserted the same generated batch.
            db.rollback()
            return 0


def select_questions(
    *,
    count: int,
    exam_type: str,
    subject: str,
    difficulty: str,
    format_version: str,
    topic: str | None = None,
    exclude_fingerprints: set[str] | None = None,
) -> list[dict]:
    """Return a randomized, exact-category sample not recently seen by a user."""
    if count <= 0:
        return []
    excluded = set(exclude_fingerprints or ())
    with SessionLocal() as db:
        query = db.query(QuestionBankItem).filter(
            QuestionBankItem.active.is_(True),
            QuestionBankItem.exam_type == exam_type,
            QuestionBankItem.subject == subject,
            QuestionBankItem.difficulty == difficulty,
            QuestionBankItem.format_version == format_version,
        )
        if topic:
            query = query.filter(QuestionBankItem.topic == topic)
        if excluded:
            query = query.filter(~QuestionBankItem.fingerprint.in_(excluded))
        items = query.order_by(func.random()).limit(count).all()
        now = now_utc()
        for item in items:
            item.last_used_at = now
            item.use_count = int(item.use_count or 0) + 1
        db.commit()
        return [dict(item.question) for item in items]


def available_count(
    *, exam_type: str, subject: str, difficulty: str,
    format_version: str, topic: str | None = None,
) -> int:
    with SessionLocal() as db:
        query = db.query(func.count(QuestionBankItem.id)).filter(
            QuestionBankItem.active.is_(True),
            QuestionBankItem.exam_type == exam_type,
            QuestionBankItem.subject == subject,
            QuestionBankItem.difficulty == difficulty,
            QuestionBankItem.format_version == format_version,
        )
        if topic:
            query = query.filter(QuestionBankItem.topic == topic)
        return int(query.scalar() or 0)


def schedule_refill(
    *, exam_type: str, subject: str, difficulty: str,
    format_version: str, topic: str | None = None, target: int = 60,
) -> None:
    """Queue one refill per category without blocking the student's request."""
    if not any(os.getenv(key, "").strip() not in {"", "test-placeholder"}
               for key in ("GEMINI_API_KEY", "GROQ_API_KEY", "OLLAMA_API_URL")):
        return
    key = (exam_type, subject, difficulty, format_version, topic or "")
    with _pending_guard:
        if key in _pending:
            return
        _pending.add(key)

    def refill() -> None:
        try:
            missing = max(0, target - available_count(
                exam_type=exam_type,
                subject=subject,
                difficulty=difficulty,
                format_version=format_version,
                topic=topic,
            ))
            if not missing:
                return
            from app.services.batch_generator import generate_large_mcqs
            questions = generate_large_mcqs(
                total_questions=missing,
                subject=subject,
                difficulty=difficulty,
                topic=topic,
                exam_type=exam_type,
            )
            store_questions(
                questions,
                exam_type=exam_type,
                subject=subject,
                difficulty=difficulty,
                format_version=format_version,
                topic=topic,
            )
        except Exception:
            logger.warning("Question-bank refill failed for %s / %s", exam_type, subject, exc_info=True)
        finally:
            with _pending_guard:
                _pending.discard(key)

    _executor.submit(refill)


def backfill_from_recent_quizzes(limit_sets: int = 200) -> int:
    """Seed the bank from recent successful Gemini quizzes already in PostgreSQL."""
    with SessionLocal() as db:
        quiz_sets = (
            db.query(QuizSet)
            .order_by(QuizSet.created_at.desc())
            .limit(limit_sets)
            .all()
        )
    grouped: dict[tuple[str, str, str, str, str], list[dict]] = {}
    for quiz_set in quiz_sets:
        version = str(quiz_set.format_version or "legacy")
        for question in quiz_set.questions or []:
            if not str(question.get("source_type", "")).endswith("_generated"):
                continue
            subject = str(question.get("subject") or quiz_set.subject)
            topic = str(question.get("topic") or "")
            key = (
                quiz_set.exam_type,
                subject,
                quiz_set.difficulty,
                version,
                topic,
            )
            grouped.setdefault(key, []).append(question)
    inserted = 0
    for (exam_type, subject, difficulty, version, topic), questions in grouped.items():
        inserted += store_questions(
            questions,
            exam_type=exam_type,
            subject=subject,
            difficulty=difficulty,
            format_version=version,
            topic=topic or None,
        )
    return inserted
