import os
import unittest

os.environ.setdefault("GROQ_API_KEY", "test-placeholder")
os.environ.setdefault("JWT_SECRET_KEY", "test-secret")

from fastapi.testclient import TestClient

from app.database import Base, SessionLocal, engine
from app.main import app
from app.models.models import QuizSet


class ApiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        Base.metadata.drop_all(bind=engine)
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

        response = cls.client.post(
            "/auth/register",
            json={
                "username": "student_one",
                "email": "student@example.com",
                "password": "secure-password",
            },
        )
        assert response.status_code == 201, response.text

        response = cls.client.post(
            "/auth/login",
            data={"username": "student_one", "password": "secure-password"},
        )
        assert response.status_code == 200, response.text
        cls.headers = {
            "Authorization": f"Bearer {response.json()['access_token']}"
        }

    def test_username_update_route(self):
        response = self.client.put(
            "/auth/username",
            json={"username": "student_updated"},
            headers=self.headers,
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["username"], "student_updated")

    def test_quiz_answers_are_private_and_attempt_is_single_use(self):
        with SessionLocal() as db:
            user_id = self.client.get("/auth/me", headers=self.headers).json()["id"]
            quiz = QuizSet(
                user_id=user_id,
                subject="Biology",
                difficulty="Medium",
                quiz_minutes=10,
                questions=[
                    {
                        "question": "Which option is correct?",
                        "options": ["A) One", "B) Two", "C) Three", "D) Four"],
                        "correct_option": "B",
                        "explanation": "Only the API should know this.",
                    }
                ],
            )
            db.add(quiz)
            db.commit()
            db.refresh(quiz)
            quiz_id = quiz.id

        response = self.client.get(f"/mcqs/{quiz_id}", headers=self.headers)
        self.assertEqual(response.status_code, 200)
        public_question = response.json()["questions"][0]
        self.assertNotIn("correct_option", public_question)
        self.assertNotIn("explanation", public_question)

        response = self.client.post(
            f"/quiz/{quiz_id}/start", headers=self.headers
        )
        self.assertEqual(response.status_code, 200)
        attempt_id = response.json()["id"]

        response = self.client.post(
            f"/quiz/attempts/{attempt_id}/submit",
            json={"answers": {"0": "B"}},
            headers=self.headers,
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["correct"], 1)

        response = self.client.post(
            f"/quiz/attempts/{attempt_id}/submit",
            json={"answers": {"0": "A"}},
            headers=self.headers,
        )
        self.assertEqual(response.status_code, 409)


if __name__ == "__main__":
    unittest.main()
