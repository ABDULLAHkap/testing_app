import json
import os
from functools import lru_cache


@lru_cache(maxsize=1)
def _firebase_app():
    raw = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()
    if not raw:
        return None
    try:
        import firebase_admin
        from firebase_admin import credentials

        try:
            return firebase_admin.get_app()
        except ValueError:
            return firebase_admin.initialize_app(
                credentials.Certificate(json.loads(raw))
            )
    except (ImportError, json.JSONDecodeError, ValueError, TypeError):
        return None


def push_is_configured() -> bool:
    return _firebase_app() is not None


def send_push(
    tokens: list[str],
    *,
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> dict:
    tokens = list(dict.fromkeys(token for token in tokens if token))
    app = _firebase_app()
    if not app or not tokens:
        return {
            "configured": app is not None,
            "requested": len(tokens),
            "sent": 0,
            "failed": 0,
        }

    from firebase_admin import messaging

    sent = 0
    failed = 0
    for start in range(0, len(tokens), 500):
        batch = tokens[start:start + 500]
        message = messaging.MulticastMessage(
            tokens=batch,
            notification=messaging.Notification(title=title, body=body),
            data={key: str(value) for key, value in (data or {}).items()},
            android=messaging.AndroidConfig(priority="high"),
        )
        try:
            response = messaging.send_each_for_multicast(message, app=app)
            sent += response.success_count
            failed += response.failure_count
        except Exception:
            failed += len(batch)
    return {
        "configured": True,
        "requested": len(tokens),
        "sent": sent,
        "failed": failed,
    }
