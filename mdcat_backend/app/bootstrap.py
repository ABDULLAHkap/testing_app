import os

from app.auth import hash_password
from app.database import SessionLocal
from app.models.models import User


def _admin_configs():
    for suffix, default_username in (("", "admin"), ("_2", "admin2")):
        email = os.getenv(f"ADMIN{suffix}_EMAIL")
        password = os.getenv(f"ADMIN{suffix}_PASSWORD")
        username = os.getenv(f"ADMIN{suffix}_USERNAME", default_username)
        if email and password:
            yield email.strip().lower(), password, username.strip()


def ensure_admin() -> None:
    with SessionLocal() as db:
        for email, password, requested_username in _admin_configs():
            user = db.query(User).filter(User.email == email).first()
            if user:
                user.is_admin = True
                user.email_verified = True
                user.hashed_password = hash_password(password)
            else:
                username = requested_username
                counter = 2
                while db.query(User).filter(User.username == username).first():
                    username = f"{requested_username}{counter}"
                    counter += 1
                user = User(
                    username=username,
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
