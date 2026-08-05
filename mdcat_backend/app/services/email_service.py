import os
import smtplib
from email.message import EmailMessage


def send_verification_email(email: str, code: str) -> None:
    host = os.getenv("SMTP_HOST")
    username = os.getenv("SMTP_USERNAME")
    password = os.getenv("SMTP_PASSWORD")
    sender = os.getenv("SMTP_FROM", username or "")
    port = int(os.getenv("SMTP_PORT", "587"))

    if not all((host, username, password, sender)):
        if os.getenv("EMAIL_OTP_DEBUG") == "true":
            print(f"Email OTP for {email}: {code}")
            return
        raise RuntimeError("Email service is not configured")

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
        server.login(username, password)
        server.send_message(message)
