import os
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, BackgroundTasks, Depends, Header, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.auth import get_current_user, require_admin
from app.database import get_db
from app.models.models import (
    User, Announcement, AnnouncementRead, SupportMessage,
    PushDevice,
)
from app.schemas import PushDeviceRegistration, PushDeviceUnregister
from app.services.push_service import push_is_configured, send_push

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
    background_tasks: BackgroundTasks,
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
    tokens = [
        row.token for row in db.query(PushDevice).filter(
            PushDevice.active.is_(True),
            PushDevice.announcements_enabled.is_(True),
        ).all()
    ]
    background_tasks.add_task(
        send_push,
        tokens,
        title=item.title,
        body=item.message,
        data={"type": "announcement", "announcement_id": str(item.id)},
    )
    return {
        "id": item.id,
        "message": "Announcement saved and push delivery queued",
        "registered_devices": len(tokens),
        "push_configured": push_is_configured(),
    }


@router.post("/notifications/devices")
def register_push_device(
    payload: PushDeviceRegistration,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    device = db.query(PushDevice).filter(PushDevice.token == payload.token).first()
    if device is None:
        device = PushDevice(token=payload.token, user_id=current_user.id)
        db.add(device)
    device.user_id = current_user.id
    device.platform = payload.platform
    device.timezone_offset_minutes = payload.timezone_offset_minutes
    device.announcements_enabled = payload.announcements_enabled
    device.study_reminders_enabled = payload.study_reminders_enabled
    device.exam_alerts_enabled = payload.exam_alerts_enabled
    device.subscription_alerts_enabled = payload.subscription_alerts_enabled
    device.active = True
    db.commit()
    return {
        "message": "This device is registered for notifications",
        "push_configured": push_is_configured(),
    }


@router.delete("/notifications/devices")
def unregister_push_device(
    payload: PushDeviceUnregister,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    device = db.query(PushDevice).filter(
        PushDevice.token == payload.token,
        PushDevice.user_id == current_user.id,
    ).first()
    if device:
        device.active = False
        db.commit()
    return {"message": "Notifications disabled on this device"}


@router.get("/notifications/status")
def notification_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    devices = db.query(PushDevice).filter(
        PushDevice.user_id == current_user.id,
        PushDevice.active.is_(True),
    ).count()
    return {"push_configured": push_is_configured(), "active_devices": devices}


def _as_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value


@router.post("/notifications/process")
def process_scheduled_notifications(
    x_notification_secret: str = Header(default=""),
    db: Session = Depends(get_db),
):
    """Called by a trusted hourly scheduler to deliver personal reminders."""
    expected = os.getenv("NOTIFICATION_CRON_SECRET", "")
    if not expected:
        raise HTTPException(503, detail="Notification scheduler is not configured")
    if not secrets.compare_digest(x_notification_secret, expected):
        raise HTTPException(401, detail="Invalid notification scheduler secret")

    now = datetime.now(timezone.utc)
    sent = 0
    devices = db.query(PushDevice).filter(PushDevice.active.is_(True)).all()
    for device in devices:
        user = db.query(User).filter(User.id == device.user_id).first()
        if not user or user.is_admin:
            continue
        local_now = now + timedelta(minutes=device.timezone_offset_minutes)

        if device.study_reminders_enabled and 18 <= local_now.hour <= 20:
            day_key = local_now.date().isoformat()
            if device.last_study_reminder_date != day_key:
                result = send_push(
                    [device.token],
                    title=f"Time for {user.target_exam} practice",
                    body="Complete a short adaptive practice set and strengthen a weak topic.",
                    data={"type": "study_reminder"},
                )
                if result["sent"]:
                    device.last_study_reminder_date = day_key
                    sent += result["sent"]

        exam_date = _as_utc(user.exam_date)
        if device.exam_alerts_enabled and exam_date:
            days = max(0, (exam_date.date() - local_now.date()).days)
            key = f"exam-{exam_date.date()}-{days}"
            if days in {30, 14, 7, 3, 1, 0} and device.last_exam_alert_key != key:
                result = send_push(
                    [device.token],
                    title=f"{user.target_exam} countdown",
                    body="Your exam is today." if days == 0 else f"{days} days remain. Keep your preparation focused.",
                    data={"type": "exam_countdown", "days": str(days)},
                )
                if result["sent"]:
                    device.last_exam_alert_key = key
                    sent += result["sent"]

        expiry = _as_utc(user.subscription_expires_at)
        if device.subscription_alerts_enabled and expiry and expiry >= now:
            days = max(0, (expiry.date() - local_now.date()).days)
            key = f"subscription-{expiry.date()}-{days}"
            if days in {7, 3, 1, 0} and device.last_subscription_alert_key != key:
                result = send_push(
                    [device.token],
                    title="Subscription reminder",
                    body="Your subscription expires today." if days == 0 else f"Your subscription expires in {days} days.",
                    data={"type": "subscription_expiry", "days": str(days)},
                )
                if result["sent"]:
                    device.last_subscription_alert_key = key
                    sent += result["sent"]

    db.commit()
    return {"message": "Notification cycle complete", "sent": sent}


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
