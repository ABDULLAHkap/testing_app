import os

from fastapi import APIRouter, Depends, HTTPException

from app.auth import get_current_user
from app.models.models import User

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])

PLANS = [
    {"id": "monthly", "name": "Monthly", "days": 30, "price_pkr": 999},
    {"id": "quarterly", "name": "3 Months", "days": 90, "price_pkr": 2499},
    {"id": "yearly", "name": "Yearly", "days": 365, "price_pkr": 7999},
]


@router.get("/plans")
def plans():
    return PLANS


@router.get("/status")
def status(current_user: User = Depends(get_current_user)):
    return {
        "free_tests_remaining": current_user.free_tests_remaining,
        "subscription_expires_at": current_user.subscription_expires_at,
        "payment_provider": "JazzCash",
        "checkout_configured": bool(
            os.getenv("JAZZCASH_MERCHANT_ID")
            and os.getenv("JAZZCASH_PASSWORD")
            and os.getenv("JAZZCASH_INTEGRITY_SALT")
        ),
    }


@router.post("/checkout/{plan_id}")
def checkout(plan_id: str, current_user: User = Depends(get_current_user)):
    if plan_id not in {plan["id"] for plan in PLANS}:
        raise HTTPException(404, detail="Plan not found")
    if not (
        os.getenv("JAZZCASH_MERCHANT_ID")
        and os.getenv("JAZZCASH_PASSWORD")
        and os.getenv("JAZZCASH_INTEGRITY_SALT")
    ):
        raise HTTPException(
            503,
            detail="JazzCash merchant checkout is awaiting merchant credentials",
        )
    raise HTTPException(
        501,
        detail="Checkout signing will be enabled after JazzCash confirms the merchant integration version",
    )
