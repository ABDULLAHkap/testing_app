from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models.models import User, QuizAttempt
from app.schemas import DashboardStats

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("", response_model=DashboardStats)
def get_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    finished_attempts = (
        db.query(QuizAttempt)
        .filter(
            QuizAttempt.user_id == current_user.id,
            QuizAttempt.finished_at.isnot(None),
        )
        .all()
    )

    tests_done = len(finished_attempts)
    avg_score = (
        sum(a.percentage for a in finished_attempts) / tests_done
        if tests_done > 0
        else 0.0
    )
    best_score = max((a.percentage for a in finished_attempts), default=0.0)

    # Simple streak: consecutive days (including today) with at least one
    # finished attempt. Kept lightweight — recomputed each request rather
    # than stored, since attempt history is already available.
    streak_days = _compute_streak(finished_attempts)

    return DashboardStats(
        exam_date=current_user.exam_date,
        tests_done=tests_done,
        avg_score=round(avg_score, 1),
        best_score=round(best_score, 1),
        streak_days=streak_days,
    )


def _compute_streak(attempts: list[QuizAttempt]) -> int:
    """Counts consecutive days (ending today or yesterday) with >=1 finished attempt."""
    if not attempts:
        return 0

    from datetime import timedelta, datetime, timezone

    dates = sorted({a.finished_at.date() for a in attempts if a.finished_at}, reverse=True)
    if not dates:
        return 0

    today = datetime.now(timezone.utc).date()

    # If the most recent activity isn't today or yesterday, the streak is broken.
    if dates[0] not in (today, today - timedelta(days=1)):
        return 0

    streak = 1
    expected = dates[0] - timedelta(days=1)

    for d in dates[1:]:
        if d == expected:
            streak += 1
            expected -= timedelta(days=1)
        elif d == dates[0]:
            continue  # duplicate date guard (shouldn't happen with a set, but safe)
        else:
            break

    return streak