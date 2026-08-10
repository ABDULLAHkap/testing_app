from sqlalchemy.orm import Session

from app.models.models import AppSetting


SUBSCRIPTION_PRICE_KEY = "subscription_price_pkr"
DEFAULT_SUBSCRIPTION_PRICE_PKR = 2000


def get_subscription_price(db: Session) -> int:
    setting = db.query(AppSetting).filter(
        AppSetting.key == SUBSCRIPTION_PRICE_KEY
    ).first()
    if setting is None:
        return DEFAULT_SUBSCRIPTION_PRICE_PKR
    try:
        price = int(setting.value)
    except (TypeError, ValueError):
        return DEFAULT_SUBSCRIPTION_PRICE_PKR
    return price if price > 0 else DEFAULT_SUBSCRIPTION_PRICE_PKR


def set_subscription_price(db: Session, price_pkr: int) -> int:
    setting = db.query(AppSetting).filter(
        AppSetting.key == SUBSCRIPTION_PRICE_KEY
    ).first()
    if setting is None:
        setting = AppSetting(key=SUBSCRIPTION_PRICE_KEY, value=str(price_pkr))
        db.add(setting)
    else:
        setting.value = str(price_pkr)
    db.commit()
    return price_pkr
