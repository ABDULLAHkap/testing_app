import os
import smtplib
from email.message import EmailMessage

import httpx


def _email_content(code: str, purpose: str) -> tuple[str, str]:
    if purpose == "password reset":
        return (
            "Your password reset code",
            f"Your password reset code is {code}. It expires in 10 minutes. "
            "Do not share this code with anyone.",
        )
    if purpose == "email change":
        return (
            "Confirm your email address change",
            f"Your email change confirmation code is {code}. It expires in "
            "10 minutes. Do not share this code with anyone. If you did not "
            "request this change, you can safely ignore this email.",
        )
    return (
        "Your verification code",
        f"Your verification code is {code}. It expires in 10 minutes. "
        "Do not share this code with anyone.",
    )


def _send_with_brevo(
    email: str, code: str, api_key: str, sender: str, purpose: str
) -> None:
    subject, content = _email_content(code, purpose)
    response = httpx.post(
        "https://api.brevo.com/v3/smtp/email",
        headers={
            "accept": "application/json",
            "api-key": api_key,
            "content-type": "application/json",
        },
        json={
            "sender": {
                "name": os.getenv("EMAIL_FROM_NAME", "Exam Preparation"),
                "email": sender,
            },
            "to": [{"email": email}],
            "subject": subject,
            "textContent": content,
        },
        timeout=20,
    )
    response.raise_for_status()


def send_verification_email(
    email: str, code: str, purpose: str = "verification"
) -> None:
    host = os.getenv("SMTP_HOST")
    username = os.getenv("SMTP_USERNAME")
    password = os.getenv("SMTP_PASSWORD")
    sender = os.getenv("SMTP_FROM", username or "")
    port = int(os.getenv("SMTP_PORT", "587"))
    brevo_api_key = os.getenv("BREVO_API_KEY")

    # HTTPS email APIs work on Render Free, where outbound SMTP ports are
    # blocked. SMTP remains available for local development or paid hosting.
    if brevo_api_key and sender:
        _send_with_brevo(email, code, brevo_api_key, sender, purpose)
        return

    if not all((host, username, password, sender)):
        if os.getenv("EMAIL_OTP_DEBUG") == "true":
            print(f"Email OTP for {email} ({purpose}): {code}")
            return
        raise RuntimeError("Brevo email API is not configured")

    message = EmailMessage()
    subject, content = _email_content(code, purpose)
    message["Subject"] = subject
    message["From"] = sender
    message["To"] = email
    message.set_content(content)

    with smtplib.SMTP(host, port, timeout=20) as server:
        server.starttls()
        server.login(username, password.replace(" ", ""))
        server.send_message(message)
