import json
import os
from functools import lru_cache

from dotenv import load_dotenv
from groq import Groq

load_dotenv()

MODEL_NAME = "llama-3.3-70b-versatile"


@lru_cache(maxsize=1)
def _get_client() -> Groq:
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        raise RuntimeError("GROQ_API_KEY is required for MCQ generation")
    # Web clients should receive the app's local fallback promptly when the
    # provider is slow or rate-limited, rather than waiting two minutes and
    # surfacing an opaque `Failed to fetch` error.
    return Groq(api_key=api_key, timeout=6, max_retries=0)


def generate_mcqs(
    number: int = 10,
    subject: str = "Mixed",
    difficulty: str = "Medium",
    topic: str | None = None,
    text: str | None = None,
    exam_type: str = "MDCAT",
) -> list[dict]:
    """
    Ask Groq for MCQs and get back a clean Python list of dicts.
    Using response_format=json_object avoids the fragile regex-parsing
    that a plain-text response would require.

    Two modes:
    - `text` provided: questions are grounded strictly in that uploaded
    study material (legacy "upload your own notes" flow).
    - `text` omitted: questions are generated from the model's own MDCAT
    subject-matter knowledge, optionally focused on a specific `topic`
    (e.g. subject="Biology", topic="Cell Biology"). This is the default,
    no-upload-required flow.
    """

    system_prompt = (
        f"You are an expert {exam_type} exam preparation question generator "
        "with deep knowledge of that exam's current syllabus and style. "
        "You always respond with valid JSON only, matching the "
        "exact schema you are given. No prose, no markdown fences, no "
        "commentary."
    )

    difficulty_guide = """Difficulty guide:
- Easy: basic conceptual recall questions.
- Medium: standard exam-level questions.
- Hard: application-based, analytical, multi-step reasoning questions."""

    base_rules = """Rules:
- Each question must have exactly 4 options (A, B, C, D).
- Exactly one correct option.
- Include a concise explanation for the correct answer.
- Include one concise explanation for every option. State why the correct
  choice is right and why each distractor is wrong.
- Identify the subject, the specific topic, and the core concept a student
  should revise after missing the question.
- Follow the official exam style and syllabus scope.
- Do not include an introduction, conclusion, or any text outside the JSON."""

    schema_block = """Respond with ONLY a JSON object of this exact shape:
{
    "questions": [
    {
    "question": "string",
    "options": ["A) ...", "B) ...", "C) ...", "D) ..."],
    "correct_option": "A",
    "explanation": "string",
    "option_explanations": {
        "A": "why A is right or wrong",
        "B": "why B is right or wrong",
        "C": "why C is right or wrong",
        "D": "why D is right or wrong"
    },
    "subject": "string",
    "topic": "specific syllabus topic",
    "concept": "concept to revise"
    }
    ]
}"""

    if text:
        # Grounded generation from uploaded material.
        topic_line = f' on the topic "{topic}"' if topic else ""
        user_prompt = f"""
Generate {number} high-quality {exam_type} MCQs for the subject "{subject}"{topic_line}
at "{difficulty}" difficulty, based ONLY on the study material provided below.

{difficulty_guide}

{base_rules}
- Base every question strictly on the study material below; do not invent
  facts that aren't supported by it.

{schema_block}

Study Material:
\"\"\"
{text}
\"\"\"
"""
    else:
        # No-upload generation, purely from the model's own MDCAT knowledge.
        topic_line = f' focused specifically on the topic "{topic}"' if topic else ""
        user_prompt = f"""
Generate {number} high-quality, original {exam_type} MCQs for the subject
"{subject}"{topic_line} at "{difficulty}" difficulty, drawing on the official
{exam_type} syllabus and your own subject-matter knowledge.

{difficulty_guide}

{base_rules}
- Cover a good spread of concepts within the subject/topic rather than
  repeating the same idea across questions.

{schema_block}
"""

    response = _get_client().chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        temperature=0.3,
        response_format={"type": "json_object"},
    )

    raw = response.choices[0].message.content

    try:
        parsed = json.loads(raw)
        questions = parsed.get("questions", [])
    except (json.JSONDecodeError, AttributeError):
        # Fall back to an empty list rather than crashing the request;
        # the caller/route can decide how to surface this to the client.
        questions = []

    # Basic shape validation so a malformed model response can't
    # silently corrupt a QuizSet's stored questions.
    valid_questions = []
    for q in questions:
        if (
            isinstance(q, dict)
            and q.get("question")
            and isinstance(q.get("options"), list)
            and len(q["options"]) == 4
            and q.get("correct_option") in ("A", "B", "C", "D")
        ):
            explanations = q.get("option_explanations")
            if not isinstance(explanations, dict):
                explanations = {}
            correct = q["correct_option"]
            fallback_explanation = str(q.get("explanation") or "Review this concept.")
            q["option_explanations"] = {
                letter: str(
                    explanations.get(letter)
                    or (
                        fallback_explanation
                        if letter == correct
                        else f"Option {letter} does not match the tested concept."
                    )
                )
                for letter in ("A", "B", "C", "D")
            }
            q["subject"] = str(q.get("subject") or subject)
            q["topic"] = str(q.get("topic") or topic or subject)
            q["concept"] = str(q.get("concept") or q["topic"])
            q["section"] = str(q.get("section") or subject)
            valid_questions.append(q)

    return valid_questions
