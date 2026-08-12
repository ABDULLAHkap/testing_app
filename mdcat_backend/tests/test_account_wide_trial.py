from types import SimpleNamespace

from app.models.models import User


def test_free_tests_are_shared_across_finished_attempts():
    user = User(username="trial-user", email="trial@example.com", hashed_password="x")
    user.attempts = [
        SimpleNamespace(finished_at=object()),
        SimpleNamespace(finished_at=object()),
        SimpleNamespace(finished_at=None),
    ]
    assert user.free_tests_remaining == 1


def test_free_tests_never_go_below_zero():
    user = User(username="trial-user-2", email="trial2@example.com", hashed_password="x")
    user.attempts = [SimpleNamespace(finished_at=object()) for _ in range(5)]
    assert user.free_tests_remaining == 0
