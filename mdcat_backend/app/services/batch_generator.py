import math

from app.services.groq_service import generate_mcqs


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
    seen_questions: set[str] = set()

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
            normalized = " ".join(question["question"].lower().split())
            if normalized in seen_questions:
                continue
            seen_questions.add(normalized)
            all_mcqs.append(question)
            if len(all_mcqs) == total_questions:
                break

    return all_mcqs[:total_questions]
