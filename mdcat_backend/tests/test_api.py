import os
import unittest
from unittest.mock import patch

os.environ.setdefault("GROQ_API_KEY", "test-placeholder")
os.environ.setdefault("JWT_SECRET_KEY", "test-secret")
os.environ.setdefault("EMAIL_OTP_DEBUG", "true")

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
                "gender": "Male",
                "phone": "+923001234567",
                "target_exam": "MDCAT",
            },
        )
        assert response.status_code == 201, response.text

        with SessionLocal() as db:
            from app.models.models import User
            user = db.query(User).filter(User.username == "student_one").first()
            user.email_verified = True
            db.commit()

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

    def test_forgot_password_code_resets_password_once(self):
        with patch("app.routers.auth.secrets.randbelow", return_value=123456), patch(
            "app.routers.auth.send_verification_email"
        ) as send_email:
            response = self.client.post(
                "/auth/forgot-password",
                json={"email": "student@example.com"},
            )
            self.assertEqual(response.status_code, 200)
            send_email.assert_called_once_with(
                "student@example.com", "123456", purpose="password reset"
            )

        response = self.client.post(
            "/auth/reset-password",
            json={
                "email": "student@example.com",
                "code": "123456",
                "new_password": "new-secure-password",
            },
        )
        self.assertEqual(response.status_code, 200)

        response = self.client.post(
            "/auth/login",
            data={"username": "student_one", "password": "new-secure-password"},
        )
        self.assertEqual(response.status_code, 200)

        response = self.client.post(
            "/auth/reset-password",
            json={
                "email": "student@example.com",
                "code": "123456",
                "new_password": "another-password",
            },
        )
        self.assertEqual(response.status_code, 400)

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
        review = response.json()["review"]
        self.assertEqual(len(review), 1)
        self.assertTrue(review[0]["is_correct"])
        self.assertEqual(review[0]["correct_option"], "B")
        self.assertIn("Only the API", review[0]["explanation"])

        response = self.client.post(
            f"/quiz/attempts/{attempt_id}/submit",
            json={"answers": {"0": "A"}},
            headers=self.headers,
        )
        self.assertEqual(response.status_code, 409)


if __name__ == "__main__":
    unittest.main()
