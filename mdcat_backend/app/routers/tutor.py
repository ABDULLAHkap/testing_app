from fastapi import APIRouter, Depends, HTTPException

from app.auth import get_current_user
from app.models.models import User
from app.schemas import TutorChatRequest, TutorChatResponse
from app.services.tutor_service import generate_tutor_reply

router = APIRouter(prefix="/tutor", tags=["tutor"])


@router.post("/chat", response_model=TutorChatResponse)
def tutor_chat(
    payload: TutorChatRequest,
    current_user: User = Depends(get_current_user),
):
    exam_type = (current_user.target_exam or "Exam").strip()
    try:
        reply = generate_tutor_reply(
            exam_type=exam_type,
            username=current_user.username,
            message=payload.message.strip(),
            history=[item.model_dump() for item in payload.history],
        )
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail="The tutor is temporarily unavailable. Please try again shortly.",
        ) from exc
    return TutorChatResponse(reply=reply, exam_type=exam_type)
