import os

from app.auth import hash_password
from app.database import SessionLocal
from app.models.models import User


def ensure_admin() -> None:
    email = os.getenv("ADMIN_EMAIL")
    password = os.getenv("ADMIN_PASSWORD")
    if not email or not password:
        return
    with SessionLocal() as db:
        user = db.query(User).filter(User.email == email).first()
        if user:
            user.is_admin = True
            user.email_verified = True
            user.hashed_password = hash_password(password)
        else:
            user = User(
                username=os.getenv("ADMIN_USERNAME", "admin"),
                email=email,
                hashed_password=hash_password(password),
                gender="Prefer not to say",
                phone="not-set",
                target_exam="MDCAT",
                email_verified=True,
                is_admin=True,
            )
            db.add(user)
        db.commit()
