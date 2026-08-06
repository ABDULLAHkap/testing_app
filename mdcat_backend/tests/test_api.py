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
from app.auth import hash_password


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
                "phone": "03001234567",
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

    def test_student_changes_email_after_old_email_otp(self):
        with SessionLocal() as db:
            from app.models.models import User

            user = User(
                username="email_change_student",
                email="old-email@example.com",
                hashed_password=hash_password("secure-password"),
                email_verified=True,
                target_exam="IELTS",
            )
            db.add(user)
            db.commit()

        login = self.client.post(
            "/auth/login",
            data={
                "username": "email_change_student",
                "password": "secure-password",
            },
        )
        self.assertEqual(login.status_code, 200)
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        with patch("app.routers.auth.secrets.randbelow", return_value=654321), patch(
            "app.routers.auth.send_verification_email"
        ) as send_email:
            response = self.client.post(
                "/auth/email-change/request",
                json={"new_email": "new-email@example.com"},
                headers=headers,
            )
            self.assertEqual(response.status_code, 200)
            send_email.assert_called_once_with(
                "old-email@example.com", "654321", purpose="email change"
            )

        response = self.client.post(
            "/auth/email-change/confirm",
            json={"new_email": "new-email@example.com", "code": "654321"},
            headers=headers,
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["email"], "new-email@example.com")

        response = self.client.post(
            "/auth/login",
            data={"username": "new-email@example.com", "password": "secure-password"},
        )
        self.assertEqual(response.status_code, 200)

    def test_registration_requires_exactly_eleven_phone_digits(self):
        invalid_numbers = [
            "0300123456",
            "030012345678",
            "+923001234567",
            "0300 1234567",
            "03001234abc",
        ]

        for index, phone in enumerate(invalid_numbers):
            with self.subTest(phone=phone):
                response = self.client.post(
                    "/auth/register",
                    json={
                        "username": f"invalid_phone_{index}",
                        "email": f"invalid-phone-{index}@example.com",
                        "password": "secure-password",
                        "gender": "Female",
                        "phone": phone,
                        "target_exam": "IELTS",
                    },
                )
                self.assertEqual(response.status_code, 422, response.text)

    def test_admin_broadcast_and_student_support_chat(self):
        with SessionLocal() as db:
            from app.models.models import User

            admin = db.query(User).filter(User.email == "student@example.com").first()
            admin.is_admin = True
            student = User(
                username="chat_student",
                email="chat@example.com",
                hashed_password=hash_password("secure-password"),
                email_verified=True,
                target_exam="ECAT",
            )
            db.add(student)
            db.commit()
            db.refresh(student)
            student_id = student.id

        response = self.client.post(
            "/communications/admin/announcements",
            json={"title": "Schedule update", "message": "The new test is available."},
            headers=self.headers,
        )
        self.assertEqual(response.status_code, 200)

        login = self.client.post(
            "/auth/login",
            data={"username": "chat_student", "password": "secure-password"},
        )
        student_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
        announcements = self.client.get(
            "/communications/announcements", headers=student_headers
        )
        self.assertEqual(announcements.status_code, 200)
        self.assertEqual(announcements.json()[0]["title"], "Schedule update")

        response = self.client.post(
            "/communications/support/messages",
            json={"message": "I need help with my test."},
            headers=student_headers,
        )
        self.assertEqual(response.status_code, 200)
        response = self.client.post(
            "/communications/support/messages",
            json={"student_id": student_id, "message": "How can we help?"},
            headers=self.headers,
        )
        self.assertEqual(response.status_code, 200)
        messages = self.client.get(
            f"/communications/support/messages?student_id={student_id}",
            headers=self.headers,
        )
        self.assertEqual(len(messages.json()), 2)

        with SessionLocal() as db:
            from app.models.models import User

            admin = db.query(User).filter(User.email == "student@example.com").first()
            admin.is_admin = False
            db.commit()

    def test_admin_can_add_and_remove_subscription(self):
        with SessionLocal() as db:
            from app.models.models import User

            admin = db.query(User).filter(User.email == "student@example.com").first()
            admin.is_admin = True
            target = User(
                username="subscription_target",
                email="subscription@example.com",
                hashed_password=hash_password("secure-password"),
                email_verified=True,
                target_exam="IELTS",
            )
            db.add(target)
            db.commit()
            db.refresh(target)
            target_id = target.id

        response = self.client.post(
            f"/admin/users/{target_id}/subscription",
            json={"days": 30},
            headers=self.headers,
        )
        self.assertEqual(response.status_code, 200)
        self.assertIsNotNone(response.json()["expires_at"])

        response = self.client.delete(
            f"/admin/users/{target_id}/subscription",
            headers=self.headers,
        )
        self.assertEqual(response.status_code, 200)

        with SessionLocal() as db:
            from app.models.models import User

            target = db.query(User).filter(User.id == target_id).first()
            self.assertIsNone(target.subscription_expires_at)
            admin = db.query(User).filter(User.email == "student@example.com").first()
            admin.is_admin = False
            db.commit()

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
