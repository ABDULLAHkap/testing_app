from datetime import datetime, timedelta, timezone

from app.services.category_subscriptions import _aware


def test_aware_keeps_timezone_aware_datetime():
    value = datetime.now(timezone.utc)
    assert _aware(value) is value


def test_aware_converts_naive_datetime_to_utc():
    value = datetime.now().replace(microsecond=0)
    converted = _aware(value)
    assert converted.tzinfo == timezone.utc
    assert converted.replace(tzinfo=None) == value
