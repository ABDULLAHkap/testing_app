import os
import unittest
from datetime import datetime, timezone
from unittest.mock import patch

os.environ.setdefault("GROQ_API_KEY", "test-placeholder")
os.environ.setdefault("JWT_SECRET_KEY", "test-secret")

from app.routers.mcqs import (
    _allocate_exam_practice_questions,
    _allocate_mock_questions,
    _official_format_reference,
    _past_paper_patterns_for,
)
from app.schemas import QuizSetOut
from app.services.batch_generator import generate_large_mcqs


def _question(text: str) -> dict:
    return {
        "question": text,
        "options": ["A) One", "B) Two", "C) Three", "D) Four"],
        "correct_option": "B",
        "explanation": "Private grading information",
    }


class CoreTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
