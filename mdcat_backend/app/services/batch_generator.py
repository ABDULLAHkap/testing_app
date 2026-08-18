import math
import re
from difflib import SequenceMatcher

from app.services.groq_service import generate_mcqs


def _normalized_question(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", text.casefold()).strip()


def _is_near_duplicate(candidate: str, existing: list[str]) -> bool:
    candidate_tokens = set(candidate.split())
    for prior in existing:
        if candidate == prior:
            return True
        prior_tokens = set(prior.split())
        union = candidate_tokens | prior_tokens
        if union and len(candidate_tokens & prior_tokens) / len(union) >= 0.9:
            return True
        if SequenceMatcher(None, candidate, prior).ratio() >= 0.92:
            return True
    return False


def generate_large_mcqs(
    total_questions: int,
    subject: str,
    difficulty: str,
    topic: str | None = None,
    text: str | None = None,
    exam_type: str = "MDCAT",
) -> list[dict]:
    """
    Groq (like most LLM APIs) gets less reliable generating very large
    batches of structured items in one call, so we batch in chunks of 20
    and concatenate the resulting lists.
    """
    batch_size = 20
    # One repair call is enough; route-level fallbacks fill any remainder.
    # The previous three extra calls could keep a web request open until the
    # Flutter client timed out when the provider returned empty JSON.
    max_calls = math.ceil(total_questions / batch_size) + 1
    all_mcqs: list[dict] = []
    normalized_questions: list[str] = []

    for _ in range(max_calls):
        remaining = total_questions - len(all_mcqs)
        if remaining <= 0:
            break
        current_batch = min(batch_size, remaining)

        result = generate_mcqs(
            number=current_batch,
            subject=subject,
            difficulty=difficulty,
            topic=topic,
            text=text,
            exam_type=exam_type,
        )
        if not result:
            break
        for question in result:
            normalized = _normalized_question(question["question"])
            if not normalized or _is_near_duplicate(normalized, normalized_questions):
                continue
            normalized_questions.append(normalized)
            all_mcqs.append(question)
            if len(all_mcqs) == total_questions:
                break

    return all_mcqs[:total_questions]
