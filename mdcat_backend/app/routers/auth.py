import hashlib
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.auth import create_access_token, hash_password, verify_password, get_current_user
from app.database import get_db
from app.models.models import (
    User, EmailVerificationCode, PasswordResetCode, EmailChangeCode,
)
from app.schemas import (
    UserCreate, UserOut, Token, ExamDateUpdate, UsernameUpdate,
    RegistrationResponse, VerifyEmailRequest, ResendOtpRequest,
    ForgotPasswordRequest, ResetPasswordRequest, MessageResponse,
    EmailChangeRequest, EmailChangeConfirm,
)
from app.exam_catalog import ensure_exam
from app.services.email_service import send_verification_email

router = APIRouter(prefix="/auth", tags=["auth"])


def _otp_hash(code: str) -> str:
    return hashlib.sha256(code.encode()).hexdigest()


def _issue_otp(user: User, db: Session) -> None:
    code = f"{secrets.randbelow(1_000_000):06d}"
    db.query(EmailVerificationCode).filter(
        EmailVerificationCode.user_id == user.id,
        EmailVerificationCode.used_at.is_(None),
    ).delete()
    db.add(EmailVerificationCode(
        user_id=user.id,
        code_hash=_otp_hash(code),
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
    ))
    db.commit()
    send_verification_email(user.email, code)


def _issue_password_reset_otp(user: User, db: Session) -> None:
    code = f"{secrets.randbelow(1_000_000):06d}"
    db.query(PasswordResetCode).filter(
        PasswordResetCode.user_id == user.id,
        PasswordResetCode.used_at.is_(None),
    ).delete()
    db.add(PasswordResetCode(
        user_id=user.id,
        code_hash=_otp_hash(code),
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
    ))
    db.commit()
    send_verification_email(user.email, code, purpose="password reset")


def _issue_email_change_otp(user: User, new_email: str, db: Session) -> None:
    code = f"{secrets.randbelow(1_000_000):06d}"
    db.query(EmailChangeCode).filter(
        EmailChangeCode.user_id == user.id,
        EmailChangeCode.used_at.is_(None),
    ).delete()
    record = EmailChangeCode(
        user_id=user.id,
        new_email=new_email,
        code_hash=_otp_hash(code),
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
    )
    db.add(record)
    db.commit()
    try:
        send_verification_email(user.email, code, purpose="email change")
    except Exception:
        db.delete(record)
        db.commit()
        raise


@router.post("/register", response_model=RegistrationResponse, status_code=status.HTTP_201_CREATED)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    email = str(payload.email).strip().lower()
    username = payload.username.strip()
    existing = db.query(User).filter(
        (func.lower(User.username) == username.lower())
        | (func.lower(User.email) == email)
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username or email already registered")

    try:
        target_exam = ensure_exam(payload.target_exam)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc

    user = User(
        username=username,
        email=email,
        hashed_password=hash_password(payload.password),
        gender=payload.gender,
        phone=payload.phone,
        target_exam=target_exam,
        email_verified=False,
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Username or email already registered",
        ) from exc
    db.refresh(user)
    try:
        _issue_otp(user, db)
    except Exception as exc:
        db.delete(user)
        db.commit()
        raise HTTPException(503, detail="Verification code could not be sent") from exc
    return RegistrationResponse(message="Verification code sent", email=user.email)


@router.post("/verify-email", response_model=UserOut)
def verify_email(payload: VerifyEmailRequest, db: Session = Depends(get_db)):
    email = str(payload.email).strip().lower()
    user = db.query(User).filter(func.lower(User.email) == email).first()
    if not user:
        raise HTTPException(404, detail="Account not found")
    record = (
        db.query(EmailVerificationCode)
        .filter(
            EmailVerificationCode.user_id == user.id,
            EmailVerificationCode.used_at.is_(None),
        )
        .order_by(EmailVerificationCode.created_at.desc())
        .with_for_update()
        .first()
    )
    now = datetime.now(timezone.utc)
    if not record or record.expires_at.replace(tzinfo=timezone.utc) < now:
        raise HTTPException(400, detail="Code expired; request a new code")
    if not secrets.compare_digest(record.code_hash, _otp_hash(payload.code)):
        raise HTTPException(400, detail="Incorrect verification code")
    record.used_at = now
    user.email_verified = True
    db.commit()
    db.refresh(user)
    return user


@router.post("/resend-otp", response_model=RegistrationResponse)
def resend_otp(payload: ResendOtpRequest, db: Session = Depends(get_db)):
    email = str(payload.email).strip().lower()
    user = db.query(User).filter(func.lower(User.email) == email).first()
    if not user:
        raise HTTPException(404, detail="Account not found")
    if user.email_verified:
        raise HTTPException(409, detail="Email is already verified")
    try:
        _issue_otp(user, db)
    except Exception as exc:
        raise HTTPException(503, detail="Verification code could not be sent") from exc
    return RegistrationResponse(message="Verification code sent", email=user.email)


@router.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    credential = form_data.username.strip()
    user = db.query(User).filter(
        (User.username == credential)
        | (func.lower(User.email) == credential.lower())
    ).first()

    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.email_verified:
        raise HTTPException(status_code=403, detail="Verify your email before login")

    token = create_access_token(data={"sub": str(user.id)})
    return Token(access_token=token)


@router.post("/forgot-password", response_model=MessageResponse)
def forgot_password(payload: ForgotPasswordRequest, db: Session = Depends(get_db)):
    email = str(payload.email).strip().lower()
    user = db.query(User).filter(func.lower(User.email) == email).first()
    if user:
        try:
            _issue_password_reset_otp(user, db)
        except Exception:
            # Keep the response identical so this endpoint does not reveal
            # whether an email address has an account.
            pass
    return MessageResponse(
        message="If an account exists for this email, a reset code has been sent."
    )


@router.post("/reset-password", response_model=MessageResponse)
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    email = str(payload.email).strip().lower()
    user = db.query(User).filter(func.lower(User.email) == email).first()
    record = None
    if user:
        record = (
            db.query(PasswordResetCode)
            .filter(
                PasswordResetCode.user_id == user.id,
                PasswordResetCode.used_at.is_(None),
            )
            .order_by(PasswordResetCode.created_at.desc())
            .with_for_update()
            .first()
        )

    now = datetime.now(timezone.utc)
    expired = not record or record.expires_at.replace(tzinfo=timezone.utc) < now
    incorrect = not record or not secrets.compare_digest(
        record.code_hash, _otp_hash(payload.code)
    )
    if not user or expired or incorrect:
        raise HTTPException(status_code=400, detail="Invalid or expired reset code")

    user.hashed_password = hash_password(payload.new_password)
    record.used_at = now
    db.commit()
    return MessageResponse(message="Password reset successfully")


@router.get("/me", response_model=UserOut)
def me(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    current_user.last_seen_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/heartbeat", response_model=MessageResponse)
def heartbeat(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Records activity so administrators can see who is currently online."""
    current_user.last_seen_at = datetime.now(timezone.utc)
    db.commit()
    return MessageResponse(message="Activity recorded")


@router.put("/exam-date", response_model=UserOut)
def set_exam_date(
    payload: ExamDateUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Sets or updates the student's selected exam date for the countdown."""
    current_user.exam_date = payload.exam_date
    db.commit()
    db.refresh(current_user)
    return current_user


@router.put("/username", response_model=UserOut)
def update_username(
    payload: UsernameUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Updates the signed-in user's username after checking uniqueness."""
    username = payload.username.strip()
    existing = (
        db.query(User)
        .filter(User.username == username, User.id != current_user.id)
        .first()
    )
    if existing:
        raise HTTPException(status_code=409, detail="Username is already taken")

    current_user.username = username
    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/email-change/request", response_model=MessageResponse)
def request_email_change(
    payload: EmailChangeRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.is_admin:
        raise HTTPException(403, detail="This option is available to student accounts")
    new_email = str(payload.new_email).strip().lower()
    if new_email == current_user.email.lower():
        raise HTTPException(400, detail="Enter a different email address")
    existing = db.query(User).filter(func.lower(User.email) == new_email).first()
    if existing:
        raise HTTPException(409, detail="This email address is already registered")
    try:
        _issue_email_change_otp(current_user, new_email, db)
    except Exception as exc:
        raise HTTPException(503, detail="Email change code could not be sent") from exc
    return MessageResponse(message="Confirmation code sent to your current email")


@router.post("/email-change/confirm", response_model=UserOut)
def confirm_email_change(
    payload: EmailChangeConfirm,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.is_admin:
        raise HTTPException(403, detail="This option is available to student accounts")
    new_email = str(payload.new_email).strip().lower()
    record = (
        db.query(EmailChangeCode)
        .filter(
            EmailChangeCode.user_id == current_user.id,
            EmailChangeCode.new_email == new_email,
            EmailChangeCode.used_at.is_(None),
        )
        .order_by(EmailChangeCode.created_at.desc())
        .with_for_update()
        .first()
    )
    now = datetime.now(timezone.utc)
    if (
        not record
        or record.expires_at.replace(tzinfo=timezone.utc) < now
        or not secrets.compare_digest(record.code_hash, _otp_hash(payload.code))
    ):
        raise HTTPException(400, detail="Invalid or expired confirmation code")
    existing = db.query(User).filter(
        func.lower(User.email) == new_email,
        User.id != current_user.id,
    ).first()
    if existing:
        raise HTTPException(409, detail="This email address is already registered")

    current_user.email = new_email
    current_user.email_verified = True
    record.used_at = now
    db.commit()
    db.refresh(current_user)
    return current_user
