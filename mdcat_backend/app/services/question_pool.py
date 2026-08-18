"""Thread-safe reusable question pool helpers.

The production server runs a single Uvicorn process with a thread pool.  A
small in-memory pool lets concurrent students reuse validated questions while
still receiving a random set.  More importantly, only the first request for a
given exam/subject needs to contact the external question provider; the other
requests wait for that pool to be populated instead of causing a burst of
rate-limited provider calls.
"""

from __future__ import annotations

import hashlib
import re
from collections import OrderedDict
from copy import deepcopy
from random import SystemRandom
from threading import Lock
from typing import Hashable


_random = SystemRandom()
_pool_guard = Lock()
_key_locks_guard = Lock()
_pools: OrderedDict[Hashable, list[dict]] = OrderedDict()
_key_locks: dict[Hashable, Lock] = {}

_MAX_POOL_KEYS = 128
_MAX_QUESTIONS_PER_KEY = 120


def question_fingerprint(question: dict | str) -> str:
    """Return a stable fingerprint that ignores punctuation and whitespace."""
    text = question if isinstance(question, str) else str(question.get("question", ""))
    normalized = re.sub(r"[^a-z0-9]+", " ", text.casefold()).strip()
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


def generation_key(
    *, exam_type: str, subject: str, difficulty: str, topic: str | None
) -> tuple[str, str, str, str]:
    return (
        exam_type.strip().casefold(),
        subject.strip().casefold(),
        difficulty.strip().casefold(),
        (topic or "").strip().casefold(),
    )


def lock_for(key: Hashable) -> Lock:
    with _key_locks_guard:
        lock = _key_locks.get(key)
        if lock is None:
            lock = Lock()
            _key_locks[key] = lock
        return lock


def cached_questions(
    key: Hashable,
    *,
    exclude: set[str] | None = None,
    limit: int | None = None,
) -> list[dict]:
    excluded = exclude or set()
    with _pool_guard:
        stored = list(_pools.get(key, ()))
        if key in _pools:
            _pools.move_to_end(key)
    candidates = [
        deepcopy(item)
        for item in stored
        if question_fingerprint(item) not in excluded
    ]
    _random.shuffle(candidates)
    return candidates if limit is None else candidates[:limit]


def add_to_pool(key: Hashable, questions: list[dict]) -> None:
    with _pool_guard:
        existing = list(_pools.get(key, ()))
        seen = {question_fingerprint(item) for item in existing}
        for question in questions:
            fingerprint = question_fingerprint(question)
            if not question.get("question") or fingerprint in seen:
                continue
            existing.append(deepcopy(question))
            seen.add(fingerprint)
        _random.shuffle(existing)
        _pools[key] = existing[:_MAX_QUESTIONS_PER_KEY]
        _pools.move_to_end(key)
        while len(_pools) > _MAX_POOL_KEYS:
            _pools.popitem(last=False)


def clear_question_pool() -> None:
    """Testing hook; production code never needs to clear a warm pool."""
    with _pool_guard:
        _pools.clear()
    with _key_locks_guard:
        _key_locks.clear()
