import json
import logging
import os
import re
import secrets
import time
from threading import BoundedSemaphore
from contextvars import ContextVar

import httpx
from dotenv import load_dotenv

load_dotenv()

MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-2.5-flash-lite").strip()
FALLBACK_MODEL_NAMES = ("gemini-2.5-flash-lite", "gemini-2.5-flash")
_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
_provider_slots = BoundedSemaphore(
    max(1, int(os.getenv("QUESTION_PROVIDER_CONCURRENCY", "4")))
)
_generation_source: ContextVar[str] = ContextVar("generation_source", default="gemini_generated")
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
_gemini_discovered_models: tuple[str, ...] = ()
_gemini_discovery_at = 0.0


def current_generation_source() -> str:
    """The provider used by the most recent generation in this request."""
    return _generation_source.get()


def _provider_is_configured(source: str) -> bool:
    """Avoid calling disabled fallbacks and reporting them as real failures."""
    variable = {
        "gemini_generated": "GEMINI_API_KEY",
        "groq_generated": "GROQ_API_KEY",
        "cohere_generated": "COHERE_API_KEY",
        "ollama_generated": "OLLAMA_API_URL",
    }[source]
    return bool(os.getenv(variable, "").strip())


def _discover_gemini_models(api_key: str) -> tuple[str, ...]:
    """Find text Flash models enabled for this API key/project.

    Different Google projects can have different model access. Discovery lets
    the fallback use a supported Flash model rather than failing only because a
    hard-coded model name is unavailable.
    """
    global _gemini_discovered_models, _gemini_discovery_at
    if _gemini_discovered_models and time.time() - _gemini_discovery_at < 900:
        return _gemini_discovered_models
    try:
        response = httpx.get(
            f"{_BASE_URL}/models",
            headers={"x-goog-api-key": api_key},
            timeout=httpx.Timeout(10, connect=5),
        )
        response.raise_for_status()
        names: list[str] = []
        for item in response.json().get("models", []):
            methods = item.get("supportedGenerationMethods", [])
            name = str(item.get("name", "")).rsplit("/", 1)[-1]
            normalized = name.casefold()
            if (
                "generateContent" in methods
                and "flash" in normalized
                and not any(blocked in normalized for blocked in ("image", "tts", "audio", "live"))
            ):
                names.append(name)
        names.sort(key=lambda name: ("flash-lite" not in name.casefold(), name))
        _gemini_discovered_models = tuple(dict.fromkeys(names))
        _gemini_discovery_at = time.time()
        return _gemini_discovered_models
    except (httpx.HTTPError, ValueError, TypeError, KeyError) as exc:
        logger.warning("Gemini model discovery failed: %s", exc)
        return ()


def _generate_content(
    *,
    system_prompt: str,
    contents: list[dict],
    temperature: float,
    max_output_tokens: int,
    json_mode: bool = False,
    response_schema: dict | None = None,
    allow_cohere: bool = False,
    allow_ollama: bool = True,
) -> str:
    """Try configured providers; Cohere is allowed only for MCQ generation."""
    errors: list[Exception] = []
    providers = [
        (_generate_with_gemini, "gemini_generated"),
        (_generate_with_groq, "groq_generated"),
    ]
    if allow_cohere:
        # Tutor conversations can contain personal student content. Cohere is
        # intentionally restricted to the explicitly requested MCQ fallback.
        providers.append((_generate_with_cohere, "cohere_generated"))
    if allow_ollama:
        providers.append((_generate_with_ollama, "ollama_generated"))
    for generator, source in providers:
        if not _provider_is_configured(source):
            continue
        try:
            result = generator(
                system_prompt=system_prompt, contents=contents,
                temperature=temperature, max_output_tokens=max_output_tokens,
                json_mode=json_mode, response_schema=response_schema,
            )
            _generation_source.set(source)
            # Render's default app logger can hide INFO records. This message
            # is deliberately visible so deployments can prove which provider
            # supplied each newly generated MCQ batch.
            logger.warning("MCQ provider succeeded: %s", source)
            return result
        except (RuntimeError, httpx.HTTPError, KeyError, IndexError, TypeError, ValueError) as exc:
            errors.append(exc)
            # The message contains provider/status details only, never an API key.
            logger.warning("MCQ provider unavailable: %s — %s", source, exc)
    if not errors:
        raise RuntimeError("No MCQ provider is configured")
    raise RuntimeError("All configured question providers are unavailable") from errors[-1]


def _generate_with_gemini(
    *, system_prompt: str, contents: list[dict], temperature: float,
    max_output_tokens: int, json_mode: bool = False,
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
    request_variants = [request]
    if json_mode and response_schema:
        # Some Gemini projects/models reject responseJsonSchema even though
        # they support JSON output. Retry with JSON MIME mode only.
        relaxed = dict(request)
        relaxed_config = dict(generation_config)
        relaxed_config.pop("responseJsonSchema", None)
        relaxed["generationConfig"] = relaxed_config
        request_variants.append(relaxed)
    with _provider_slots:
        discovered = _discover_gemini_models(api_key)
        model_names = tuple(dict.fromkeys((
            MODEL_NAME, *FALLBACK_MODEL_NAMES, *discovered,
        )))
        last_error: Exception | None = None
        for model_name in model_names:
            url = f"{_BASE_URL}/models/{model_name}:generateContent"
            for attempt in range(3):
                try:
                    response = None
                    for request_variant in request_variants:
                        response = httpx.post(
                            url,
                            headers={
                                "Content-Type": "application/json",
                                "x-goog-api-key": api_key,
                            },
                            json=request_variant,
                            timeout=httpx.Timeout(25, connect=5),
                        )
                        # Only a strict-schema validation error gets the
                        # relaxed JSON retry; other statuses follow normal
                        # provider fallback behavior.
                        if response.status_code != 400 or request_variant is request_variants[-1]:
                            break
                    assert response is not None
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


def _plain_prompt(system_prompt: str, contents: list[dict]) -> str:
    message = "\n".join(
        str(part.get("text", ""))
        for item in contents for part in item.get("parts", [])
    )
    return f"{system_prompt}\n\n{message}"


def _generate_with_groq(
    *, system_prompt: str, contents: list[dict], temperature: float,
    max_output_tokens: int, json_mode: bool = False,
    response_schema: dict | None = None,
) -> str:
    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError("GROQ_API_KEY is not configured")
    model = os.getenv("GROQ_MODEL", "openai/gpt-oss-20b").strip()
    request: dict = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": _plain_prompt("", contents)},
        ],
        "temperature": temperature,
        "max_tokens": max_output_tokens,
    }
    if json_mode:
        request["response_format"] = {"type": "json_object"}
    request_variants = [request]
    if json_mode:
        relaxed = dict(request)
        relaxed.pop("response_format", None)
        request_variants.append(relaxed)
    try:
        with _provider_slots:
            response = None
            for request_variant in request_variants:
                response = httpx.post(
                    "https://api.groq.com/openai/v1/chat/completions",
                    headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                    json=request_variant, timeout=httpx.Timeout(30, connect=5),
                )
                if response.status_code != 400 or request_variant is request_variants[-1]:
                    break
            assert response is not None
            response.raise_for_status()
            text = str(response.json()["choices"][0]["message"]["content"] or "").strip()
            if not text:
                raise RuntimeError("Groq returned an empty response")
            return text
    except httpx.HTTPStatusError as exc:
        raise RuntimeError(f"Groq question provider HTTP {exc.response.status_code}") from exc
    except (httpx.HTTPError, KeyError, IndexError, TypeError, ValueError) as exc:
        raise RuntimeError("Groq question provider failed") from exc


def _generate_with_cohere(
    *, system_prompt: str, contents: list[dict], temperature: float,
    max_output_tokens: int, json_mode: bool = False,
    response_schema: dict | None = None,
) -> str:
    """Generate through Cohere's v2 Chat API."""
    api_key = os.getenv("COHERE_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError("COHERE_API_KEY is not configured")
    model = os.getenv("COHERE_MODEL", "command-a-plus-05-2026").strip()
    request: dict = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": _plain_prompt("", contents)},
        ],
        "temperature": temperature,
        "max_tokens": max_output_tokens,
    }
    if json_mode:
        # Cohere v2 supports JSON-object output, including an optional schema.
        # The app still validates every returned question before storage.
        request["response_format"] = {"type": "json_object"}
        if response_schema:
            request["response_format"]["schema"] = response_schema
    request_variants = [request]
    if json_mode:
        relaxed = dict(request)
        relaxed.pop("response_format", None)
        request_variants.append(relaxed)
    try:
        with _provider_slots:
            response = None
            for request_variant in request_variants:
                response = httpx.post(
                    "https://api.cohere.com/v2/chat",
                    headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                    # Free Cohere requests can queue briefly, especially for
                    # structured MCQ batches; allow enough time to complete.
                    json=request_variant, timeout=httpx.Timeout(60, connect=8),
                )
                if response.status_code != 400 or request_variant is request_variants[-1]:
                    break
            assert response is not None
            response.raise_for_status()
            payload = response.json()
            message = payload.get("message", {}) if isinstance(payload, dict) else {}
            content = message.get("content", []) if isinstance(message, dict) else []
            if isinstance(content, str):
                text = content.strip()
            elif isinstance(content, dict):
                text = str(content.get("text", "")).strip()
            elif isinstance(content, list):
                text = "".join(
                    str(part.get("text", ""))
                    for part in content if isinstance(part, dict)
                ).strip()
            else:
                text = ""
            if not text:
                raise RuntimeError("Cohere returned an empty response")
            return text
    except httpx.HTTPStatusError as exc:
        raise RuntimeError(f"Cohere question provider HTTP {exc.response.status_code}") from exc
    except (httpx.HTTPError, KeyError, IndexError, TypeError, ValueError) as exc:
        raise RuntimeError(
            f"Cohere question provider failed ({type(exc).__name__})"
        ) from exc


def _generate_with_ollama(
    *, system_prompt: str, contents: list[dict], temperature: float,
    max_output_tokens: int, json_mode: bool = False,
    response_schema: dict | None = None,
) -> str:
    base_url = os.getenv("OLLAMA_API_URL", "").strip().rstrip("/")
    if not base_url:
        raise RuntimeError("OLLAMA_API_URL is not configured")
    model = os.getenv("OLLAMA_MODEL", "llama3.1:8b").strip()
    request: dict = {
        "model": model,
        "prompt": _plain_prompt(system_prompt, contents),
        "stream": False,
        "options": {"temperature": temperature, "num_predict": max_output_tokens},
    }
    if json_mode:
        request["format"] = response_schema or "json"
    headers = {"Content-Type": "application/json"}
    token = os.getenv("OLLAMA_API_TOKEN", "").strip()
    if token:
        headers["Authorization"] = f"Bearer {token}"
    try:
        with _provider_slots:
            response = httpx.post(
                f"{base_url}/api/generate", headers=headers, json=request,
                timeout=httpx.Timeout(90, connect=8),
            )
            response.raise_for_status()
            text = str(response.json().get("response", "")).strip()
            if not text:
                raise RuntimeError("Ollama returned an empty response")
            return text
    except (httpx.HTTPError, TypeError, ValueError) as exc:
        raise RuntimeError("Ollama question provider failed") from exc


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
        allow_cohere=True,
        allow_ollama=False,
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
            "source_type": current_generation_source(),
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
