from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.auth import get_current_user, require_admin
from app.database import get_db
from app.models.models import (
    User, Announcement, AnnouncementRead, SupportMessage,
)

router = APIRouter(prefix="/communications", tags=["communications"])


class AnnouncementCreate(BaseModel):
    title: str = Field(min_length=3, max_length=120)
    message: str = Field(min_length=3, max_length=4000)


class SupportMessageCreate(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    student_id: Optional[int] = None


def _announcement_data(item: Announcement, read_ids: set[int]) -> dict:
    return {
        "id": item.id,
        "title": item.title,
        "message": item.message,
        "created_at": item.created_at,
        "is_read": item.id in read_ids,
    }


@router.get("/announcements")
def announcements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    items = db.query(Announcement).order_by(Announcement.created_at.desc()).limit(200).all()
    read_ids = {
        row.announcement_id
        for row in db.query(AnnouncementRead).filter(
            AnnouncementRead.user_id == current_user.id
        ).all()
    }
    return [_announcement_data(item, read_ids) for item in items]


@router.get("/announcements/unread-count")
def unread_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    total = db.query(Announcement).count()
    read = db.query(AnnouncementRead).filter(
        AnnouncementRead.user_id == current_user.id
    ).count()
    return {"unread_count": max(0, total - read)}


@router.post("/announcements/read-all")
def read_all_announcements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    announcement_ids = [row.id for row in db.query(Announcement.id).all()]
    existing = {
        row.announcement_id
        for row in db.query(AnnouncementRead).filter(
            AnnouncementRead.user_id == current_user.id
        ).all()
    }
    for announcement_id in announcement_ids:
        if announcement_id not in existing:
            db.add(AnnouncementRead(
                user_id=current_user.id,
                announcement_id=announcement_id,
            ))
    db.commit()
    return {"message": "Announcements marked as read"}


@router.post("/admin/announcements")
def create_announcement(
    payload: AnnouncementCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    item = Announcement(
        admin_id=admin.id,
        title=payload.title.strip(),
        message=payload.message.strip(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return {"id": item.id, "message": "Announcement sent to all students"}


@router.get("/support/messages")
def support_messages(
    student_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.is_admin:
        if student_id is None:
            raise HTTPException(422, detail="student_id is required for admins")
        student = db.query(User).filter(User.id == student_id, User.is_admin.is_(False)).first()
        if not student:
            raise HTTPException(404, detail="Student not found")
        target_id = student.id
    else:
        target_id = current_user.id
    rows = db.query(SupportMessage).filter(
        SupportMessage.student_id == target_id
    ).order_by(SupportMessage.created_at.asc()).limit(500).all()
    return [{
        "id": row.id,
        "student_id": row.student_id,
        "sender_id": row.sender_id,
        "sender_is_admin": row.sender_id != row.student_id,
        "message": row.message,
        "created_at": row.created_at,
    } for row in rows]


@router.post("/support/messages")
def send_support_message(
    payload: SupportMessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.is_admin:
        if payload.student_id is None:
            raise HTTPException(422, detail="student_id is required for admins")
        student = db.query(User).filter(
            User.id == payload.student_id, User.is_admin.is_(False)
        ).first()
        if not student:
            raise HTTPException(404, detail="Student not found")
        student_id = student.id
    else:
        student_id = current_user.id
    row = SupportMessage(
        student_id=student_id,
        sender_id=current_user.id,
        message=payload.message.strip(),
    )
    db.add(row)
    db.commit()
    return {"message": "Message sent"}


@router.get("/admin/support/conversations")
def support_conversations(
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    rows = db.query(SupportMessage).order_by(SupportMessage.created_at.desc()).all()
    latest_by_student = {}
    for row in rows:
        latest_by_student.setdefault(row.student_id, row)
    result = []
    for student_id, latest in latest_by_student.items():
        student = db.query(User).filter(User.id == student_id).first()
        if student:
            result.append({
                "student_id": student.id,
                "username": student.username,
                "email": student.email,
                "last_message": latest.message,
                "last_message_at": latest.created_at,
            })
    return result
