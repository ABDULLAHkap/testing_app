from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, EmailStr, Field, field_validator


# ---------- Auth ----------

class UserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(min_length=6)
    gender: str = Field(pattern=r"^(Male|Female|Other|Prefer not to say)$")
    phone: str = Field(pattern=r"^\d{11}$")
    target_exam: str = Field(min_length=2, max_length=30)


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


# ---------- Exam tutor ----------

class TutorHistoryMessage(BaseModel):
    role: str = Field(pattern=r"^(user|assistant)$")
    # Tutor explanations and study plans can be detailed. Keep a generous but
    # bounded history size so the API never rejects its own previous reply.
    content: str = Field(min_length=1, max_length=6000)


class TutorChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    history: List[TutorHistoryMessage] = Field(default_factory=list, max_length=12)


class TutorChatResponse(BaseModel):
    reply: str
    exam_type: str


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
    subject: Optional[str] = None
    topic: Optional[str] = None
    section: Optional[str] = None


class QuizSetOut(BaseModel):
    id: int
    subject: str
    difficulty: str
    quiz_minutes: int
    exam_type: str = "MDCAT"
    mode: str = "topic"
    negative_marking: float = 0.0
    format_version: Optional[str] = None
    section_config: Optional[List[Dict[str, Any]]] = None
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
    time_spent_seconds: dict[str, int] = Field(default_factory=dict)

    @field_validator("answers")
    @classmethod
    def validate_answers(cls, answers: dict[str, str]) -> dict[str, str]:
        for index, answer in answers.items():
            if not index.isdigit():
                raise ValueError("Answer keys must be question indexes")
            if answer not in {"A", "B", "C", "D"}:
                raise ValueError("Each answer must be A, B, C, or D")
        return answers

    @field_validator("time_spent_seconds")
    @classmethod
    def validate_question_times(
        cls, values: dict[str, int]
    ) -> dict[str, int]:
        for index, seconds in values.items():
            if not index.isdigit():
                raise ValueError("Time keys must be question indexes")
            if seconds < 0 or seconds > 86400:
                raise ValueError("Question time must be between 0 and 86400 seconds")
        return values


class QuestionReview(BaseModel):
    index: int
    question: str
    options: List[str]
    selected_option: Optional[str] = None
    correct_option: str
    correct_answer: str
    is_correct: bool
    explanation: Optional[str] = None
    option_explanations: Dict[str, str] = Field(default_factory=dict)
    subject: Optional[str] = None
    topic: Optional[str] = None
    concept: Optional[str] = None
    time_spent_seconds: int = 0


class AttemptResult(BaseModel):
    id: int
    quiz_set_id: int
    correct: int
    wrong: int
    total: int
    percentage: float
    grade: str
    score: float = 0.0
    max_score: float = 0.0
    negative_marking: float = 0.0
    total_time_seconds: int = 0
    finished_at: Optional[datetime]
    review: List[QuestionReview] = Field(default_factory=list)

    class Config:
        from_attributes = True


class ProgressPoint(BaseModel):
    attempt_id: int
    quiz_set_id: int
    subject: str
    difficulty: str
    exam_type: str = "MDCAT"
    total_time_seconds: int = 0
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
    exam_type: str = "MDCAT"
    year: int
    subject: str = "All Subjects"
    board: str
    source_type: str = "practice"
    is_official: bool = False
    download_available: bool = True
    official_source: Optional[str] = None


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
    exam_type: str = "MDCAT"
    year: int
    subject: str = "All Subjects"
    board: str
    source_type: str = "practice"
    is_official: bool = False
    official_source: Optional[str] = None


# ---------- Adaptive practice and push notifications ----------

class AdaptivePracticeRequest(BaseModel):
    number_of_questions: int = Field(default=15, ge=5, le=50)
    difficulty: str = Field(default="Medium", pattern=r"^(Easy|Medium|Hard)$")
    quiz_minutes: int = Field(default=25, ge=5, le=120)


class PushDeviceRegistration(BaseModel):
    token: str = Field(min_length=20, max_length=512)
    platform: str = Field(default="unknown", max_length=20)
    timezone_offset_minutes: int = Field(default=0, ge=-840, le=840)
    announcements_enabled: bool = True
    study_reminders_enabled: bool = True
    exam_alerts_enabled: bool = True
    subscription_alerts_enabled: bool = True


class PushDeviceUnregister(BaseModel):
    token: str = Field(min_length=20, max_length=512)
