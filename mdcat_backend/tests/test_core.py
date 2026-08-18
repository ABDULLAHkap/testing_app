import json
import os
import unittest
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from unittest.mock import Mock, patch

import httpx

os.environ.setdefault("GEMINI_API_KEY", "test-placeholder")
os.environ.setdefault("JWT_SECRET_KEY", "test-secret")

from app.routers.mcqs import (
    _build_download_questions,
    _compact_download_breakdown,
    _offline_download_questions,
    _generate_resilient_questions,
    _allocate_exam_practice_questions,
    _allocate_mock_questions,
    _official_format_reference,
    _past_paper_patterns_for,
)
from app.schemas import QuizSetOut
from app.services.batch_generator import generate_large_mcqs
from app.services.pdf_report import create_practice_paper_pdf
from app.services.email_service import _send_with_brevo
from app.services.question_pool import clear_question_pool, question_fingerprint
from app.services.gemini_service import (
    _generate_content,
    generate_mcqs as generate_gemini_mcqs,
)


def _question(text: str) -> dict:
    return {
        "question": text,
        "options": ["A) One", "B) Two", "C) Three", "D) Four"],
        "correct_option": "B",
        "explanation": "Private grading information",
    }


class CoreTests(unittest.TestCase):
    def test_gemini_uses_supported_fallback_when_configured_model_is_missing(self):
        missing = Mock(status_code=404)
        missing.raise_for_status.side_effect = httpx.HTTPStatusError(
            "model missing",
            request=httpx.Request("POST", "https://example.invalid"),
            response=httpx.Response(404),
        )
        accepted = Mock(status_code=200)
        accepted.raise_for_status.return_value = None
        accepted.json.return_value = {
            "candidates": [{"content": {"parts": [{"text": "working"}]}}]
        }

        with patch(
            "app.services.gemini_service.MODEL_NAME", "gemini-missing"
        ), patch(
            "app.services.gemini_service.httpx.post", side_effect=[missing, accepted]
        ) as post:
            result = _generate_content(
                system_prompt="test",
                contents=[{"role": "user", "parts": [{"text": "test"}]}],
                temperature=0,
                max_output_tokens=20,
            )

        self.assertEqual(result, "working")
        self.assertEqual(post.call_count, 2)
        self.assertIn("gemini-3.5-flash-lite", post.call_args.args[0])

    def test_gemini_json_response_is_validated_and_category_scoped(self):
        response = Mock(status_code=200)
        response.raise_for_status.return_value = None
        response.json.return_value = {
            "candidates": [{
                "content": {"parts": [{"text": json.dumps({
                    "questions": [{
                        "question": "Which organelle produces most cellular ATP?",
                        "options": [
                            "A) Nucleus", "B) Mitochondrion",
                            "C) Ribosome", "D) Golgi apparatus",
                        ],
                        "correct_option": "B",
                        "explanation": "Oxidative phosphorylation occurs in mitochondria.",
                        "topic": "Cell Biology",
                        "concept": "Cellular respiration",
                    }]
                })}]}
            }]
        }
        with patch("app.services.gemini_service.httpx.post", return_value=response) as post:
            questions = generate_gemini_mcqs(
                number=1,
                subject="Biology",
                difficulty="Medium",
                exam_type="MDCAT",
            )

        self.assertEqual(len(questions), 1)
        self.assertEqual(questions[0]["subject"], "Biology")
        self.assertEqual(questions[0]["source_type"], "gemini_generated")
        self.assertEqual(
            post.call_args.kwargs["headers"]["x-goog-api-key"],
            "test-placeholder",
        )
        generation_config = post.call_args.kwargs["json"]["generationConfig"]
        self.assertEqual(generation_config["responseMimeType"], "application/json")
        self.assertEqual(
            generation_config["responseJsonSchema"]["properties"]["questions"]["minItems"],
            1,
        )

    def test_brevo_retries_temporary_rate_limit_for_any_email_domain(self):
        rate_limited = Mock(status_code=429)
        rate_limited.raise_for_status.side_effect = httpx.HTTPStatusError(
            "rate limited",
            request=httpx.Request("POST", "https://api.brevo.com/v3/smtp/email"),
            response=httpx.Response(429),
        )
        accepted = Mock(status_code=201)
        accepted.raise_for_status.return_value = None

        with patch(
            "app.services.email_service.httpx.post",
            side_effect=[rate_limited, accepted],
        ) as post, patch("app.services.email_service.time.sleep"):
            _send_with_brevo(
                "Student@Yahoo.com",
                "123456",
                "test-api-key",
                "verified@example.com",
                "verification",
            )

        self.assertEqual(post.call_count, 2)
        self.assertEqual(
            post.call_args.kwargs["json"]["to"],
            [{"email": "student@yahoo.com"}],
        )

    def test_past_papers_match_selected_exam(self):
        ielts_patterns = _past_paper_patterns_for("IELTS")
        self.assertEqual(len(ielts_patterns), 3)
        self.assertTrue(
            all(item["exam_type"] == "IELTS" for item in ielts_patterns.values())
        )
        self.assertTrue(
            all(item["download_available"] for item in ielts_patterns.values())
        )
        _resource_id, resource = _official_format_reference("IELTS")
        self.assertIn("IELTS", resource["title"])
        self.assertNotIn("MDCAT", resource["title"])
        self.assertEqual(
            set(resource["subject_breakdown"]),
            {"Listening", "Reading", "Writing", "Speaking"},
        )
        self.assertFalse(resource["download_available"])

    def test_mock_allocation_is_exact_and_includes_every_subject(self):
        for total in (5, 10, 100, 200):
            allocation = _allocate_mock_questions(total)
            self.assertEqual(sum(allocation.values()), total)
            self.assertTrue(all(count >= 1 for count in allocation.values()))

    def test_every_exam_has_daily_quiz_and_mock_allocation(self):
        from app.exam_catalog import EXAM_CATALOG, get_exam_format

        for exam_type in EXAM_CATALOG:
            daily = _allocate_exam_practice_questions(exam_type, 10)
            self.assertEqual(sum(daily.values()), 10, exam_type)
            self.assertTrue(all(count > 0 for count in daily.values()), exam_type)
            self.assertTrue(get_exam_format(exam_type)["mock_breakdown"], exam_type)
            self.assertTrue(_past_paper_patterns_for(exam_type), exam_type)

    def test_compact_download_preserves_subjects_and_stays_small(self):
        full = {
            "Biology": 81,
            "Chemistry": 45,
            "Physics": 36,
            "English": 9,
            "Logical Reasoning": 9,
        }
        compact = _compact_download_breakdown(full)

        self.assertEqual(set(compact), set(full))
        self.assertEqual(sum(compact.values()), 25)
        self.assertTrue(all(count >= 1 for count in compact.values()))
        self.assertGreater(compact["Biology"], compact["English"])

    @patch("app.routers.mcqs.generate_large_mcqs", side_effect=RuntimeError("quota"))
    def test_download_questions_fall_back_when_provider_fails(self, _generate):
        questions = _build_download_questions(
            exam_type="MDCAT",
            subject_breakdown={"Biology": 81, "Chemistry": 45},
        )
        self.assertEqual(len(questions), 25)
        self.assertTrue(all(len(item["options"]) == 4 for item in questions))
        self.assertEqual(
            len({question_fingerprint(item) for item in questions}),
            25,
        )

    def test_practice_pdf_renders_multiple_paragraphs(self):
        questions = _offline_download_questions(
            exam_type="MDCAT",
            subject="Biology",
            count=2,
        )
        path = create_practice_paper_pdf(
            title="MDCAT compact test",
            exam_type="MDCAT",
            minutes=15,
            questions=questions,
            negative_marking=0,
        )
        try:
            self.assertGreater(os.path.getsize(path), 500)
            with open(path, "rb") as handle:
                self.assertEqual(handle.read(4), b"%PDF")
        finally:
            os.remove(path)

    @patch("app.routers.mcqs.generate_large_mcqs", side_effect=RuntimeError("offline"))
    def test_every_exam_category_generates_when_provider_is_offline(self, _generate):
        from app.exam_catalog import EXAM_CATALOG

        for exam_type, subjects in EXAM_CATALOG.items():
            for subject in subjects:
                questions = _generate_resilient_questions(
                    total_questions=10,
                    subject=subject,
                    difficulty="Medium",
                    exam_type=exam_type,
                )
                self.assertEqual(len(questions), 10, f"{exam_type}: {subject}")
                self.assertTrue(
                    all(len(question["options"]) == 4 for question in questions),
                    f"{exam_type}: {subject}",
                )
                self.assertEqual(
                    len({question_fingerprint(item) for item in questions}),
                    10,
                    f"{exam_type}: {subject}",
                )
                self.assertTrue(
                    all(question["subject"] == subject for question in questions),
                    f"{exam_type}: {subject}",
                )

    @patch("app.routers.mcqs.generate_large_mcqs", side_effect=RuntimeError("quota"))
    def test_fifteen_concurrent_generations_are_complete_and_unique(self, _generate):
        clear_question_pool()

        def generate(_index):
            return _generate_resilient_questions(
                total_questions=10,
                subject="Biology",
                difficulty="Medium",
                exam_type="MDCAT",
            )

        with ThreadPoolExecutor(max_workers=15) as executor:
            quizzes = list(executor.map(generate, range(15)))

        for quiz in quizzes:
            self.assertEqual(len(quiz), 10)
            self.assertEqual(
                len({question_fingerprint(question) for question in quiz}),
                10,
            )
            self.assertTrue(all(question["subject"] == "Biology" for question in quiz))
        signatures = {
            tuple(question_fingerprint(question) for question in quiz)
            for quiz in quizzes
        }
        self.assertGreater(len(signatures), 1)

    def test_public_quiz_schema_hides_answers(self):
        quiz = QuizSetOut.model_validate(
            {
                "id": 1,
                "subject": "Biology",
                "difficulty": "Medium",
                "quiz_minutes": 10,
                "source_filename": None,
                "questions": [_question("Which option is correct?")],
                "created_at": datetime.now(timezone.utc),
            }
        ).model_dump()

        public_question = quiz["questions"][0]
        self.assertNotIn("correct_option", public_question)
        self.assertNotIn("explanation", public_question)

    @patch("app.services.batch_generator.generate_mcqs")
    def test_generation_retries_and_removes_duplicate_questions(self, mocked):
        mocked.side_effect = [
            [_question("Question one"), _question("Question one")],
            [_question("Question two"), _question("Question three")],
        ]

        questions = generate_large_mcqs(3, "Biology", "Medium")

        self.assertEqual(len(questions), 3)
        self.assertEqual(
            {question["question"] for question in questions},
            {"Question one", "Question two", "Question three"},
        )

    @patch("app.services.batch_generator.generate_mcqs")
    def test_large_mock_sections_use_safe_ten_question_batches(self, mocked):
        counter = {"value": 0}

        def generated(*, number, **_kwargs):
            questions = []
            for _ in range(number):
                counter["value"] += 1
                questions.append(_question(f"Generated question {counter['value']}"))
            return questions

        mocked.side_effect = generated
        questions = generate_large_mcqs(81, "Biology", "Medium")

        self.assertEqual(len(questions), 81)
        self.assertEqual(mocked.call_count, 9)
        self.assertTrue(
            all(call.kwargs["number"] <= 10 for call in mocked.call_args_list)
        )

    @patch("app.routers.mcqs._offline_download_questions")
    @patch("app.routers.mcqs.generate_large_mcqs")
    def test_complete_provider_result_is_not_mixed_with_fallbacks(
        self, generated, offline
    ):
        clear_question_pool()
        generated.return_value = [
            _question(f"API question {index}") for index in range(25)
        ]

        questions = _generate_resilient_questions(
            total_questions=25,
            subject="Biology",
            difficulty="Medium",
            exam_type="MDCAT",
        )

        self.assertEqual(len(questions), 25)
        self.assertTrue(all(item["question"].startswith("API question") for item in questions))
        offline.assert_not_called()

    @patch("app.services.batch_generator.generate_mcqs", return_value=[])
    def test_generation_stops_after_empty_provider_response(self, mocked):
        self.assertEqual(generate_large_mcqs(10, "Biology", "Medium"), [])
        self.assertEqual(mocked.call_count, 1)


if __name__ == "__main__":
    unittest.main()
