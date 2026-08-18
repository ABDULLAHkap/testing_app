import json
import os
import re
import secrets
import time
from threading import BoundedSemaphore

import httpx
from dotenv import load_dotenv

load_dotenv()

MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-3.5-flash-lite").strip()
FALLBACK_MODEL_NAMES = ("gemini-3.5-flash-lite", "gemini-2.5-flash")
_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
_provider_slots = BoundedSemaphore(
    max(1, int(os.getenv("QUESTION_PROVIDER_CONCURRENCY", "4")))
)


def _generate_content(
    *,
    system_prompt: str,
    contents: list[dict],
    temperature: float,
    max_output_tokens: int,
    json_mode: bool = False,
    response_schema: dict | None = None,
) -> str:
    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is required for AI generation")

    generation_config: dict = {
        "temperature": temperature,
        "maxOutputTokens": max_output_tokens,
    }
    if json_mode:
        generation_config["responseMimeType"] = "application/json"
        if response_schema:
            generation_config["responseJsonSchema"] = response_schema

    request = {
        "systemInstruction": {"parts": [{"text": system_prompt}]},
        "contents": contents,
        "generationConfig": generation_config,
    }
    with _provider_slots:
        model_names = tuple(dict.fromkeys((MODEL_NAME, *FALLBACK_MODEL_NAMES)))
        last_error: Exception | None = None
        for model_name in model_names:
            url = f"{_BASE_URL}/models/{model_name}:generateContent"
            for attempt in range(3):
                try:
                    response = httpx.post(
                        url,
                        headers={
                            "Content-Type": "application/json",
                            "x-goog-api-key": api_key,
                        },
                        json=request,
                        timeout=httpx.Timeout(25, connect=5),
                    )
                    # A configured model can be unavailable to a particular
                    # API key/project. Try the supported fallback models rather
                    # than silently replacing the requested quiz with offline
                    # syllabus placeholders.
                    if response.status_code == 404:
                        response.raise_for_status()
                    if response.status_code == 429 or response.status_code >= 500:
                        response.raise_for_status()
                    response.raise_for_status()
                    payload = response.json()
                    parts = payload["candidates"][0]["content"]["parts"]
                    text = "".join(
                        str(part.get("text", "")) for part in parts
                    ).strip()
                    if not text:
                        raise RuntimeError("Gemini returned an empty response")
                    return text
                except httpx.HTTPStatusError as exc:
                    last_error = exc
                    if exc.response.status_code == 404:
                        break
                    if attempt == 2:
                        raise
                    time.sleep(0.6 * (2 ** attempt))
                except (httpx.HTTPError, KeyError, IndexError, TypeError, ValueError) as exc:
                    last_error = exc
                    if attempt == 2:
                        raise
                    time.sleep(0.6 * (2 ** attempt))

    raise RuntimeError("No configured Gemini model is available") from last_error


def generate_mcqs(
    number: int = 10,
    subject: str = "Mixed",
    difficulty: str = "Medium",
    topic: str | None = None,
    text: str | None = None,
    exam_type: str = "MDCAT",
) -> list[dict]:
    batch_id = secrets.token_hex(6)
    system_prompt = (
        f"You are an expert {exam_type} examination question writer. "
        "Return valid JSON only and follow the requested schema exactly."
    )
    source_rule = (
        "Use only the supplied study material." if text else
        f"Use the official {exam_type} syllabus and established public past-paper patterns."
    )
    topic_line = f' Topic: "{topic}".' if topic else ""
    material = f'\nStudy material:\n"""{text}"""' if text else ""
    prompt = f"""
Generate exactly {number} original {difficulty} MCQs for {exam_type}, subject
"{subject}".{topic_line} Generation batch: {batch_id}.

{source_rule}
- Test {number} genuinely different facts, calculations, applications or concepts.
- Do not repeat, lightly reword, or reuse the same answer pattern.
- Follow past-paper difficulty and style, but never copy questions verbatim.
- Each question must have four distinct options labelled A), B), C), D).
- Exactly one option is correct.
- Include a concise explanation and an explanation for each option.

Return only this JSON shape:
{{"questions":[{{"question":"...","options":["A) ...","B) ...","C) ...","D) ..."],"correct_option":"A","explanation":"...","option_explanations":{{"A":"...","B":"...","C":"...","D":"..."}},"subject":"{subject}","topic":"specific topic","concept":"specific concept"}}]}}
{material}
""".strip()

    response_schema = {
        "type": "object",
        "required": ["questions"],
        "properties": {
            "questions": {
                "type": "array",
                "minItems": number,
                "maxItems": number,
                "items": {
                    "type": "object",
                    "required": [
                        "question", "options", "correct_option", "explanation"
                    ],
                    "properties": {
                        "question": {"type": "string"},
                        "options": {
                            "type": "array",
                            "minItems": 4,
                            "maxItems": 4,
                            "items": {"type": "string"},
                        },
                        "correct_option": {
                            "type": "string",
                            "enum": ["A", "B", "C", "D"],
                        },
                        "explanation": {"type": "string"},
                        "option_explanations": {
                            "type": "object",
                            "properties": {
                                letter: {"type": "string"}
                                for letter in ("A", "B", "C", "D")
                            },
                        },
                        "subject": {"type": "string"},
                        "topic": {"type": "string"},
                        "concept": {"type": "string"},
                    },
                },
            }
        },
    }
    raw = _generate_content(
        system_prompt=system_prompt,
        contents=[{"role": "user", "parts": [{"text": prompt}]}],
        temperature=0.8,
        max_output_tokens=max(4096, number * 700),
        json_mode=True,
        response_schema=response_schema,
    )
    raw = re.sub(r"^```(?:json)?\s*|\s*```$", "", raw.strip(), flags=re.I)
    try:
        questions = json.loads(raw).get("questions", [])
    except (json.JSONDecodeError, AttributeError):
        return []

    valid: list[dict] = []
    seen: set[str] = set()
    for question in questions:
        if not isinstance(question, dict):
            continue
        question_text = str(question.get("question", "")).strip()
        options = question.get("options")
        correct = str(question.get("correct_option", "")).strip().upper()
        normalized = re.sub(r"[^a-z0-9]+", " ", question_text.casefold()).strip()
        if (
            not normalized or normalized in seen or
            not isinstance(options, list) or len(options) != 4 or
            correct not in {"A", "B", "C", "D"}
        ):
            continue

        cleaned_options: list[str] = []
        option_bodies: set[str] = set()
        for index, option in enumerate(options):
            letter = chr(ord("A") + index)
            body = re.sub(
                rf"^\s*{letter}\s*[\)\.\:\-]\s*", "", str(option), flags=re.I
            ).strip()
            comparable = re.sub(r"\s+", " ", body.casefold())
            if not body or comparable in option_bodies:
                cleaned_options = []
                break
            option_bodies.add(comparable)
            cleaned_options.append(f"{letter}) {body}")
        if len(cleaned_options) != 4:
            continue

        explanations = question.get("option_explanations")
        explanations = explanations if isinstance(explanations, dict) else {}
        main_explanation = str(question.get("explanation") or "Review this concept.")
        question.update({
            "question": question_text,
            "options": cleaned_options,
            "correct_option": correct,
            "explanation": main_explanation,
            "option_explanations": {
                letter: str(explanations.get(letter) or (
                    main_explanation if letter == correct
                    else f"Option {letter} does not match the tested concept."
                ))
                for letter in ("A", "B", "C", "D")
            },
            "subject": subject,
            "topic": str(topic or question.get("topic") or subject),
            "concept": str(question.get("concept") or topic or subject),
            "section": subject,
            "source_type": "gemini_generated",
        })
        seen.add(normalized)
        valid.append(question)
    return valid


def generate_tutor_text(
    *, system_prompt: str, message: str, history: list[dict]
) -> str:
    contents: list[dict] = []
    for item in history[-12:]:
        if item.get("role") in {"user", "assistant"} and item.get("content"):
            contents.append({
                "role": "model" if item["role"] == "assistant" else "user",
                "parts": [{"text": str(item["content"])[:6000]}],
            })
    contents.append({"role": "user", "parts": [{"text": message}]})
    return _generate_content(
        system_prompt=system_prompt,
        contents=contents,
        temperature=0.25,
        max_output_tokens=900,
    )
