import os
import smtplib
from email.message import EmailMessage

import httpx


def _send_with_brevo(email: str, code: str, api_key: str, sender: str) -> None:
    response = httpx.post(
        "https://api.brevo.com/v3/smtp/email",
        headers={
            "accept": "application/json",
            "api-key": api_key,
            "content-type": "application/json",
        },
        json={
            "sender": {
                "name": os.getenv("EMAIL_FROM_NAME", "AI Exam Preparation"),
                "email": sender,
            },
            "to": [{"email": email}],
            "subject": "Your verification code",
            "textContent": (
                f"Your verification code is {code}. It expires in 10 minutes. "
                "Do not share this code with anyone."
            ),
        },
        timeout=20,
    )
    response.raise_for_status()


def send_verification_email(email: str, code: str) -> None:
    host = os.getenv("SMTP_HOST")
    username = os.getenv("SMTP_USERNAME")
    password = os.getenv("SMTP_PASSWORD")
    sender = os.getenv("SMTP_FROM", username or "")
    port = int(os.getenv("SMTP_PORT", "587"))
    brevo_api_key = os.getenv("BREVO_API_KEY")

    # HTTPS email APIs work on Render Free, where outbound SMTP ports are
    # blocked. SMTP remains available for local development or paid hosting.
    if brevo_api_key and sender:
        _send_with_brevo(email, code, brevo_api_key, sender)
        return

    if not all((host, username, password, sender)):
        if os.getenv("EMAIL_OTP_DEBUG") == "true":
            print(f"Email OTP for {email}: {code}")
            return
        raise RuntimeError("Brevo email API is not configured")

    message = EmailMessage()
    message["Subject"] = "Your preparation app verification code"
    message["From"] = sender
    message["To"] = email
    message.set_content(
        f"Your verification code is {code}. It expires in 10 minutes. "
        "Do not share this code with anyone."
    )

    with smtplib.SMTP(host, port, timeout=20) as server:
        server.starttls()
        server.login(username, password.replace(" ", ""))
        server.send_message(message)
