import os
from datetime import datetime, timedelta, timezone
from typing import Optional

from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.exam_subscription import ExamSubscription
from app.models.models import User

load_dotenv()

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
if not SECRET_KEY:
    raise RuntimeError(
        "JWT_SECRET_KEY is required. Copy .env.example to .env for local use."
    )
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days, good for a mobile app

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise credentials_exception
    return user


def _as_aware(value: datetime | None) -> datetime | None:
    if value is not None and value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value


def _active_exam_subscription(db: Session, user: User) -> ExamSubscription | None:
    now = datetime.now(timezone.utc)
    subscription = (
        db.query(ExamSubscription)
        .filter(
            ExamSubscription.user_id == user.id,
            ExamSubscription.exam_type == user.target_exam,
        )
        .first()
    )
    if subscription and _as_aware(subscription.expires_at) > now:
        return subscription
    return None


def _migrate_legacy_subscription(db: Session, user: User) -> ExamSubscription | None:
    """Move an old global subscription into the student's current category once."""
    now = datetime.now(timezone.utc)
    legacy_expiry = _as_aware(user.subscription_expires_at)
    if not legacy_expiry or legacy_expiry <= now:
        return None

    existing = db.query(ExamSubscription).filter(ExamSubscription.user_id == user.id).count()
    if existing:
        return None

    subscription = ExamSubscription(
        user_id=user.id,
        exam_type=user.target_exam,
        expires_at=legacy_expiry,
    )
    db.add(subscription)
    user.subscription_expires_at = None
    db.commit()
    db.refresh(subscription)
    return subscription


def require_test_access(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> User:
    if current_user.is_admin:
        return current_user
    if current_user.free_tests_remaining > 0:
        return current_user
    if _active_exam_subscription(db, current_user):
        return current_user
    if _migrate_legacy_subscription(db, current_user):
        return current_user
    raise HTTPException(
        status_code=status.HTTP_402_PAYMENT_REQUIRED,
        detail=(
            f"Your 3 free tests are complete. Please subscribe to "
            f"{current_user.target_exam} to continue."
        ),
    )


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user
