from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest

from app.auth import require_test_access


class _FakeDb:
    def execute(self, *_args, **_kwargs):
        raise AssertionError("DB subscription lookup should not run for admin/free access")


def test_admin_always_has_test_access():
    user = SimpleNamespace(is_admin=True, free_tests_remaining=0, target_exam="MDCAT")
    assert require_test_access(current_user=user, db=_FakeDb()) is user


def test_account_wide_free_trial_allows_access_before_subscription_lookup():
    user = SimpleNamespace(is_admin=False, free_tests_remaining=1, target_exam="ECAT")
    assert require_test_access(current_user=user, db=_FakeDb()) is user
