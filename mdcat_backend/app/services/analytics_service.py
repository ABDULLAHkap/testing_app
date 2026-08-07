from collections import defaultdict
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.models.models import QuizAttempt, QuizSet, User


def completed_attempt_rows(db: Session, user: User):
    return (
        db.query(QuizAttempt, QuizSet)
        .join(QuizSet, QuizAttempt.quiz_set_id == QuizSet.id)
        .filter(
            QuizAttempt.user_id == user.id,
            QuizAttempt.finished_at.isnot(None),
            QuizSet.exam_type == user.target_exam,
        )
        .order_by(QuizAttempt.finished_at.asc())
        .all()
    )


def _bucket():
    return {"correct": 0, "attempted": 0, "seconds": 0, "questions": 0}


def learning_breakdown(db: Session, user: User) -> dict:
    """Build reusable, server-trusted subject and topic performance data."""
    rows = completed_attempt_rows(db, user)
    subjects = defaultdict(_bucket)
    topics = defaultdict(_bucket)

    for attempt, quiz_set in rows:
        answers = attempt.answers or {}
        times = attempt.question_times or {}
        for index, question in enumerate(quiz_set.questions or []):
            key = str(index)
            subject = str(question.get("subject") or quiz_set.subject)
            topic = str(question.get("topic") or subject)
            chosen = answers.get(key)
            correct = chosen == question.get("correct_option")
            seconds = max(0, int(times.get(key, 0) or 0))

            for bucket in (subjects[subject], topics[f"{subject}|||{topic}"]):
                bucket["questions"] += 1
                bucket["seconds"] += seconds
                if chosen is not None:
                    bucket["attempted"] += 1
                if correct:
                    bucket["correct"] += 1

    def finalized(items, include_subject=False):
        result = []
        for label, values in items.items():
            questions = max(1, values["questions"])
            row = {
                "name": label,
                "accuracy": round(values["correct"] / questions * 100, 1),
                "correct": values["correct"],
                "questions": values["questions"],
                "attempted": values["attempted"],
                "average_time_seconds": round(values["seconds"] / questions, 1),
            }
            if include_subject:
                subject, topic = label.split("|||", 1)
                row.update({"name": topic, "topic": topic, "subject": subject})
            result.append(row)
        return sorted(result, key=lambda item: (item["accuracy"], item["name"]))

    return {
        "rows": rows,
        "subject_scores": finalized(subjects),
        "topic_scores": finalized(topics, include_subject=True),
    }


def advanced_analytics(db: Session, user: User) -> dict:
    data = learning_breakdown(db, user)
    rows = data.pop("rows")
    now = datetime.now(timezone.utc)
    week_starts = []
    current_start = (now - timedelta(days=now.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    for offset in range(7, -1, -1):
        week_starts.append(current_start - timedelta(weeks=offset))

    weekly = []
    for start in week_starts:
        end = start + timedelta(days=7)
        attempts = []
        for attempt, _quiz_set in rows:
            finished = attempt.finished_at
            if finished and finished.tzinfo is None:
                finished = finished.replace(tzinfo=timezone.utc)
            if finished and start <= finished < end:
                attempts.append(attempt)
        weekly.append({
            "week_start": start.date().isoformat(),
            "average_score": round(
                sum(item.percentage for item in attempts) / len(attempts), 1
            ) if attempts else 0.0,
            "tests": len(attempts),
        })

    completed = [attempt for attempt, _quiz_set in rows]
    latest = completed[-1] if completed else None
    previous = completed[-2] if len(completed) > 1 else None
    topic_scores = data["topic_scores"]
    strongest = sorted(
        [item for item in topic_scores if item["questions"] >= 2],
        key=lambda item: (-item["accuracy"], item["name"]),
    )[:5]
    weakest = sorted(
        [item for item in topic_scores if item["questions"] >= 1],
        key=lambda item: (item["accuracy"], -item["questions"]),
    )[:5]
    total_seconds = sum(
        sum((attempt.question_times or {}).values()) for attempt in completed
    )

    return {
        **data,
        "weekly_improvement": weekly,
        "strongest_topics": strongest,
        "weakest_topics": weakest,
        "summary": {
            "tests_completed": len(completed),
            "average_score": round(
                sum(item.percentage for item in completed) / len(completed), 1
            ) if completed else 0.0,
            "best_score": round(max((item.percentage for item in completed), default=0.0), 1),
            "total_time_seconds": total_seconds,
        },
        "latest_comparison": {
            "latest_score": round(latest.percentage, 1) if latest else None,
            "previous_score": round(previous.percentage, 1) if previous else None,
            "change": round(latest.percentage - previous.percentage, 1)
            if latest and previous else None,
        },
    }
