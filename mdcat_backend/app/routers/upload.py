import os
import uuid

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File

from app.auth import get_current_user
from app.models.models import User
from app.schemas import UploadResponse, TextStats
from app.utils.pdf_reader import extract_pdf_text
from app.utils.docx_reader import extract_docx_text
from app.utils.txt_reader import extract_txt_text
from app.utils.text_processor import clean_text, split_into_chunks, get_text_statistics

router = APIRouter(prefix="/upload", tags=["upload"])

UPLOAD_DIR = "uploads"
ALLOWED_EXTENSIONS = {".pdf", ".docx", ".txt"}
MAX_FILE_SIZE_MB = 20

os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.post("", response_model=UploadResponse)
async def upload_material(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(400, detail="Only PDF, DOCX, and TXT files are supported")

    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE_MB * 1024 * 1024:
        raise HTTPException(400, detail=f"File exceeds {MAX_FILE_SIZE_MB}MB limit")

    # Namespace files per-user with a random suffix to avoid collisions
    # and one user overwriting another's uploaded file.
    safe_name = f"{current_user.id}_{uuid.uuid4().hex}{ext}"
    file_path = os.path.join(UPLOAD_DIR, safe_name)

    with open(file_path, "wb") as f:
        f.write(contents)

    if ext == ".pdf":
        extracted_text = extract_pdf_text(file_path)
    elif ext == ".docx":
        extracted_text = extract_docx_text(file_path)
    else:
        extracted_text = extract_txt_text(file_path)

    cleaned = clean_text(extracted_text)
    if not cleaned:
        raise HTTPException(422, detail="No readable text could be extracted from this file")

    stats = get_text_statistics(cleaned)
    chunks = split_into_chunks(cleaned)

    return UploadResponse(
        filename=file.filename,
        stats=TextStats(**stats),
        cleaned_text=cleaned,
        chunks=chunks,
    )
