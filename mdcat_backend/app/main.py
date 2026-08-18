import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.routers import (
    auth, upload, mcqs, quiz, progress, dashboard, admin, subscriptions,
    communications, tutor, category, category_quizzes,
)
from app.bootstrap import ensure_admin
from app.migrations import apply_compatibility_migrations
from app.services.question_bank import backfill_from_recent_quizzes

# Creates tables on first run. For schema changes later, switch to
# Alembic migrations instead of relying on create_all.
Base.metadata.create_all(bind=engine)
apply_compatibility_migrations()
ensure_admin()
backfill_from_recent_quizzes()

app = FastAPI(
    title="Exam Preparation API",
    description="Backend API for the multi-exam preparation Flutter app",
    version="1.0.0",
)

cors_origins = [
    origin.strip()
    for origin in os.getenv("CORS_ORIGINS", "*").split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials="*" not in cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(category.router)
app.include_router(upload.router)
# Register the exact GET /mcqs category-history route before the legacy
# /mcqs router so saved student quizzes never mix exam categories.
app.include_router(category_quizzes.router)
app.include_router(mcqs.router)
app.include_router(quiz.router)
app.include_router(progress.router)
app.include_router(dashboard.router)
app.include_router(admin.router)
app.include_router(subscriptions.router)
app.include_router(communications.router)
app.include_router(tutor.router)


@app.get("/")
def root():
    return {"status": "ok", "service": "Exam Preparation API"}


@app.get("/health")
def health():
    return {"status": "healthy"}
