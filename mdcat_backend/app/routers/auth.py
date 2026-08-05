from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.auth import create_access_token, hash_password, verify_password, get_current_user
from app.database import get_db
from app.models.models import User
from app.schemas import UserCreate, UserOut, Token, ExamDateUpdate, UsernameUpdate

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter(
        (User.username == payload.username) | (User.email == payload.email)
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username or email already registered")

    user = User(
        username=payload.username,
        email=payload.email,
        hashed_password=hash_password(payload.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == form_data.username).first()

    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = create_access_token(data={"sub": str(user.id)})
    return Token(access_token=token)


@router.get("/me", response_model=UserOut)
def me(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/exam-date", response_model=UserOut)
def set_exam_date(
    payload: ExamDateUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Sets/updates the student's MDCAT exam date, used for the dashboard countdown."""
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
