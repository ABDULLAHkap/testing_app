import os
import smtplib
import time
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
    request = {
        "url": "https://api.brevo.com/v3/smtp/email",
        "headers": {
            "accept": "application/json",
            "api-key": api_key,
            "content-type": "application/json",
        },
        "json": {
            "sender": {
                "name": os.getenv("EMAIL_FROM_NAME", "BrainBoost"),
                "email": sender,
            },
            "to": [{"email": email.strip().lower()}],
            "subject": subject,
            "textContent": content,
        },
        "timeout": httpx.Timeout(20, connect=5),
    }
    last_error: Exception | None = None
    for attempt in range(3):
        try:
            response = httpx.post(**request)
            if response.status_code == 429 or response.status_code >= 500:
                response.raise_for_status()
            response.raise_for_status()
            return
        except (httpx.TimeoutException, httpx.NetworkError, httpx.HTTPStatusError) as exc:
            last_error = exc
            retryable_status = (
                not isinstance(exc, httpx.HTTPStatusError)
                or exc.response.status_code == 429
                or exc.response.status_code >= 500
            )
            if not retryable_status or attempt == 2:
                raise
            time.sleep(0.25 * (2 ** attempt))
    if last_error:
        raise last_error


def send_verification_email(
    email: str, code: str, purpose: str = "verification"
) -> None:
    host = os.getenv("SMTP_HOST")
    username = os.getenv("SMTP_USERNAME")
    password = os.getenv("SMTP_PASSWORD")
    sender = os.getenv("BREVO_SENDER_EMAIL") or os.getenv(
        "SMTP_FROM", username or ""
    )
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
