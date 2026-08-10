import hashlib
import hmac
import os
import secrets
from datetime import datetime, timedelta, timezone
from urllib.parse import urlencode

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models.models import Payment, User
from app.services.app_settings import get_subscription_price

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])

PLAN = {"id": "monthly", "name": "30-Day Unlimited Access", "days": 30}


def _plan(db: Session) -> dict:
    return {**PLAN, "price_pkr": get_subscription_price(db)}


def _environment() -> str:
    value = os.getenv("SAFEPAY_ENVIRONMENT", "sandbox").strip().lower()
    if value not in {"sandbox", "production"}:
        raise HTTPException(503, detail="Safepay environment is invalid")
    return value


def _credentials() -> tuple[str, str]:
    public_key = os.getenv("SAFEPAY_PUBLIC_KEY", "").strip()
    secret_key = os.getenv("SAFEPAY_SECRET_KEY", "").strip()
    if not public_key or not secret_key:
        raise HTTPException(503, detail="Safepay checkout is not configured")
    return public_key, secret_key


def _api_base(environment: str) -> str:
    return "https://sandbox.api.getsafepay.com" if environment == "sandbox" else "https://api.getsafepay.com"


def _checkout_base(environment: str) -> str:
    return "https://sandbox.api.getsafepay.com/checkout/pay" if environment == "sandbox" else "https://getsafepay.com/checkout/pay"


def _frontend_url() -> str:
    return os.getenv("FRONTEND_URL", "https://exam-preparation-app.onrender.com").rstrip("/")


@router.get("/plans")
def plans(db: Session = Depends(get_db)):
    return [_plan(db)]


@router.get("/status")
def status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return {
        "free_tests_remaining": current_user.free_tests_remaining,
        "subscription_expires_at": current_user.subscription_expires_at,
        "payment_provider": "Safepay",
        "checkout_configured": bool(os.getenv("SAFEPAY_PUBLIC_KEY") and os.getenv("SAFEPAY_SECRET_KEY")),
        "plan": _plan(db),
        "is_admin": current_user.is_admin,
    }


@router.post("/checkout/{plan_id}")
def checkout(plan_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if plan_id != PLAN["id"]:
        raise HTTPException(404, detail="Plan not found")
    if current_user.is_admin:
        raise HTTPException(400, detail="Administrators already have unlimited access")
    public_key, _secret_key = _credentials()
    environment = _environment()
    plan = _plan(db)
    try:
        response = httpx.post(
            f"{_api_base(environment)}/order/v1/init",
            json={"amount": plan["price_pkr"], "client": public_key, "currency": "PKR", "environment": environment},
            timeout=20.0,
        )
        response.raise_for_status()
        tracker = response.json()["data"]["token"]
    except (httpx.HTTPError, KeyError, TypeError, ValueError) as error:
        raise HTTPException(502, detail="Safepay could not start checkout. Please try again.") from error

    order_id = f"EXAM-{current_user.id}-{secrets.token_hex(6)}"
    payment = Payment(
        user_id=current_user.id, provider="safepay", transaction_ref=tracker,
        amount_pkr=plan["price_pkr"], status="pending",
        provider_response={"order_id": order_id, "environment": environment, "plan_id": PLAN["id"]},
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)
    backend_url = os.getenv("BACKEND_PUBLIC_URL", "https://mdcat-backend.onrender.com").rstrip("/")
    query = urlencode({
        "beacon": tracker,
        "cancel_url": f"{backend_url}/subscriptions/safepay/cancel?payment_id={payment.id}",
        "env": environment,
        "order_id": order_id,
        "redirect_url": f"{backend_url}/subscriptions/safepay/return?payment_id={payment.id}",
        "source": "custom", "webhooks": "false",
    })
    return {"checkout_url": f"{_checkout_base(environment)}?{query}", "payment_id": payment.id, "amount_pkr": plan["price_pkr"], "days": PLAN["days"]}


def _complete_payment(payment_id: int, tracker: str, signature: str, db: Session):
    _public_key, secret_key = _credentials()
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment or payment.provider != "safepay":
        raise HTTPException(404, detail="Payment not found")
    if payment.transaction_ref != tracker:
        raise HTTPException(400, detail="Payment tracker does not match")
    expected = hmac.new(secret_key.encode(), tracker.encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, signature):
        raise HTTPException(400, detail="Invalid Safepay signature")
    if payment.status != "paid":
        user = db.query(User).filter(User.id == payment.user_id).first()
        if not user:
            raise HTTPException(404, detail="Student account not found")
        now = datetime.now(timezone.utc)
        current_expiry = user.subscription_expires_at
        if current_expiry is not None and current_expiry.tzinfo is None:
            current_expiry = current_expiry.replace(tzinfo=timezone.utc)
        start = current_expiry if current_expiry and current_expiry > now else now
        user.subscription_expires_at = start + timedelta(days=PLAN["days"])
        payment.status = "paid"
        payment.completed_at = now
        payment.provider_response = {**(payment.provider_response or {}), "verified": True}
        db.commit()
    return payment


@router.api_route("/safepay/return", methods=["GET", "POST"])
async def safepay_return(request: Request, payment_id: int, db: Session = Depends(get_db)):
    values = dict(request.query_params)
    if request.method == "POST":
        content_type = request.headers.get("content-type", "")
        values.update(await request.json() if "application/json" in content_type else dict(await request.form()))
    tracker = str(values.get("tracker") or values.get("beacon") or "")
    signature = str(values.get("sig") or values.get("signature") or "")
    if not tracker or not signature:
        raise HTTPException(400, detail="Safepay confirmation is incomplete")
    _complete_payment(payment_id, tracker, signature, db)
    return RedirectResponse(f"{_frontend_url()}/?payment=success", status_code=303)


@router.get("/safepay/cancel")
def safepay_cancel(payment_id: int, db: Session = Depends(get_db)):
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if payment and payment.status == "pending":
        payment.status = "cancelled"
        db.commit()
    return RedirectResponse(f"{_frontend_url()}/?payment=cancelled", status_code=303)
