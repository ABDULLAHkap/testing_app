import os
import re

import httpx


def normalize_whatsapp_number(phone: str) -> str:
    digits = re.sub(r"\D", "", phone)
    if digits.startswith("0"):
        digits = "92" + digits[1:]
    if len(digits) < 10:
        raise ValueError("Enter a valid WhatsApp number with country code")
    return digits


def send_whatsapp_otp(phone: str, code: str) -> None:
    token = os.getenv("WHATSAPP_ACCESS_TOKEN")
    phone_number_id = os.getenv("WHATSAPP_PHONE_NUMBER_ID")
    template = os.getenv("WHATSAPP_OTP_TEMPLATE", "exam_verification_code")
    language = os.getenv("WHATSAPP_TEMPLATE_LANGUAGE", "en_US")
    graph_version = os.getenv("WHATSAPP_GRAPH_VERSION", "v23.0")
    if not token or not phone_number_id:
        if os.getenv("WHATSAPP_OTP_DEBUG") == "true":
            print(f"WhatsApp OTP for {phone}: {code}")
            return
        raise RuntimeError("WhatsApp Cloud API is not configured")

    response = httpx.post(
        f"https://graph.facebook.com/{graph_version}/{phone_number_id}/messages",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        json={
            "messaging_product": "whatsapp",
            "to": normalize_whatsapp_number(phone),
            "type": "template",
            "template": {
                "name": template,
                "language": {"code": language},
                "components": [{
                    "type": "body",
                    "parameters": [{"type": "text", "text": code}],
                }],
            },
        },
        timeout=20,
    )
    response.raise_for_status()
