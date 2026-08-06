from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, EmailStr, Field, field_validator


# ---------- Auth ----------

class UserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(min_length=6)
    gender: str = Field(pattern=r"^(Male|Female|Other|Prefer not to say)$")
    phone: str = Field(min_length=7, max_length=30)
    target_exam: str = Field(min_length=2, max_length=30)
    verification_method: str = Field(default="email", pattern=r"^(email|whatsapp)$")


class UserLogin(BaseModel):
    username: str
    password: str


class UserOut(BaseModel):
    id: int
    username: str
    email: str
    created_at: datetime
    exam_date: Optional[datetime] = None
    gender: Optional[str] = None
    phone: Optional[str] = None
    target_exam: str = "MDCAT"
    email_verified: bool = False
    phone_verified: bool = False
    verification_method: str = "email"
    is_admin: bool = False
    subscription_expires_at: Optional[datetime] = None
    free_tests_remaining: int = 3

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class VerifyEmailRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class VerifyPhoneRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class ResendOtpRequest(BaseModel):
    email: EmailStr


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")
    new_password: str = Field(min_length=8)


class MessageResponse(BaseModel):
    message: str


class EmailChangeRequest(BaseModel):
    new_email: EmailStr


class EmailChangeConfirm(BaseModel):
    new_email: EmailStr
    code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class RegistrationResponse(BaseModel):
    message: str
    email: str


class ExamDateUpdate(BaseModel):
    exam_date: datetime


class UsernameUpdate(BaseModel):
    username: str = Field(min_length=3, max_length=50, pattern=r"^[A-Za-z0-9_.-]+$")


# ---------- Upload ----------

class TextStats(BaseModel):
    words: int
    characters: int
    lines: int


class UploadResponse(BaseModel):
    filename: str
    stats: TextStats
    cleaned_text: str
    chunks: List[str]


# ---------- MCQ generation ----------

class GenerateMCQRequest(BaseModel):
    # Optional now: if omitted, MCQs are generated purely from the AI's own
    # MDCAT knowledge for the given subject/topic — no uploaded material
    # required. If provided (e.g. from an uploaded file), questions are
    # grounded in that text instead.
    text: Optional[str] = None
    number_of_questions: int = Field(default=10, ge=5, le=50)
    subject: str = Field(default="Mixed", min_length=2, max_length=50)
    topic: Optional[str] = Field(default=None, max_length=100)
    difficulty: str = Field(default="Medium", pattern=r"^(Easy|Medium|Hard)$")
    quiz_minutes: int = Field(default=30, ge=1, le=300)
    source_filename: Optional[str] = Field(default=None, max_length=255)
    mode: str = "topic"  # "topic" | "mock_test" | "daily_challenge"
    exam_type: Optional[str] = Field(default=None, max_length=30)


class MCQItem(BaseModel):
    """Question data safe to send before the attempt is submitted."""

    question: str
    options: List[str]


class QuizSetOut(BaseModel):
    id: int
    subject: str
    difficulty: str
    quiz_minutes: int
    source_filename: Optional[str]
    questions: List[MCQItem]
    created_at: datetime

    class Config:
        from_attributes = True


class QuizSetSummary(BaseModel):
    id: int
    subject: str
    difficulty: str
    quiz_minutes: int
    question_count: int
    created_at: datetime

    class Config:
        from_attributes = True


# ---------- Quiz attempt / grading ----------

class SubmitAnswersRequest(BaseModel):
    # keys are question index as string, values are the chosen option letter "A"/"B"/"C"/"D"
    answers: dict[str, str]

    @field_validator("answers")
    @classmethod
    def validate_answers(cls, answers: dict[str, str]) -> dict[str, str]:
        for index, answer in answers.items():
            if not index.isdigit():
                raise ValueError("Answer keys must be question indexes")
            if answer not in {"A", "B", "C", "D"}:
                raise ValueError("Each answer must be A, B, C, or D")
        return answers


class QuestionReview(BaseModel):
    index: int
    question: str
    options: List[str]
    selected_option: Optional[str] = None
    correct_option: str
    correct_answer: str
    is_correct: bool
    explanation: Optional[str] = None


class AttemptResult(BaseModel):
    id: int
    quiz_set_id: int
    correct: int
    wrong: int
    total: int
    percentage: float
    grade: str
    finished_at: Optional[datetime]
    review: List[QuestionReview] = Field(default_factory=list)

    class Config:
        from_attributes = True


class ProgressPoint(BaseModel):
    attempt_id: int
    quiz_set_id: int
    subject: str
    difficulty: str
    percentage: float
    grade: str
    finished_at: Optional[datetime]


# ---------- Dashboard ----------

class DashboardStats(BaseModel):
    exam_date: Optional[datetime]
    tests_done: int
    avg_score: float
    best_score: float
    streak_days: int


class TopicListItem(BaseModel):
    subject: str
    topics: List[str]


# ---------- Past Papers ----------

class SubjectBreakdownItem(BaseModel):
    subject: str
    weight_percent: float
    mcq_count: int


class PastPaperSummary(BaseModel):
    id: str
    title: str
    total_questions: int
    quiz_minutes: int
    is_new: bool = True


class PastPaperDetail(BaseModel):
    id: str
    title: str
    total_questions: int
    quiz_minutes: int
    total_marks: int
    marks_per_correct: float
    marks_penalty_per_wrong: float
    subject_breakdown: List[SubjectBreakdownItem]
    instructions: List[str]
