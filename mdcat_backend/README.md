# Multi-Exam Preparation API

FastAPI backend for the MDCAT AI Preparation System, built to be consumed by
a Flutter mobile app (or any HTTP client). This replaces the Streamlit
prototype — all core logic (file extraction, text processing, MCQ
generation, quiz grading) is carried over and reused.

## Setup

```bash
cd mdcat_backend
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env
# then edit .env and set GROQ_API_KEY and JWT_SECRET_KEY
```

Run the dev server:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Interactive API docs: http://localhost:8000/docs

To let a physical phone on the same Wi-Fi reach your laptop during Flutter
development, use `--host 0.0.0.0` and point the Flutter app at
`http://<your-computer-LAN-IP>:8000` (not `localhost`, which on a phone
refers to the phone itself). Android emulators specifically use
`10.0.2.2` to reach the host machine's localhost.

## Environment variables

| Variable        | Purpose                                             |
|-----------------|------------------------------------------------------|
| `GROQ_API_KEY`  | Your Groq API key (same as the original Streamlit app) |
| `JWT_SECRET_KEY`| Required long random secret used to sign auth tokens. |
| `DATABASE_URL`  | Defaults to local SQLite. Swap for a Postgres URL in production, e.g. `postgresql://user:pass@host/db` |
| `CORS_ORIGINS`  | Comma-separated allowed web origins, or `*` while testing. |

## What changed vs. the Streamlit version

- **Auth**: real registration + hashed passwords + JWT tokens, replacing
  the hardcoded `admin` / `1234` check.
- **MCQ format**: Groq is now asked to return structured JSON directly
  (`response_format: json_object`), so there's no more regex-parsing of
  `**Question 1**` / `A)` / `Correct Answer:` text blocks. This is far more
  robust against the model varying its formatting.
- **Grading**: happens entirely server-side (`_grade()` in
  `app/routers/quiz.py`). A client can't fake or tamper with its own score.
- **Persistence**: generated quizzes (`QuizSet`) and completed attempts
  (`QuizAttempt`) are saved in a database per user, enabling history,
  progress tracking, and revisiting old quiz sets — none of which was
  possible with Streamlit's `st.session_state` (which resets whenever the
  browser tab is refreshed or closed).

## API reference

All endpoints except `/auth/register` and `/auth/login` require
`Authorization: Bearer <token>`.

### Auth
- `POST /auth/register` — `{username, email, password}` → user object
- `POST /auth/login` — form fields `username`, `password` → `{access_token, token_type}`
- `GET /auth/me` — current user

### Upload
- `POST /upload` — multipart file upload (`.pdf` / `.docx` / `.txt`, max 20MB)
  → extracted + cleaned text, stats, and chunk preview. **This does not
  persist anything to the database** — pass the returned `cleaned_text`
  straight into `/mcqs/generate`.

### MCQs
- `POST /mcqs/generate` — `{text, number_of_questions, subject, difficulty, quiz_minutes, source_filename?}`
  → a saved `QuizSet` with structured questions
  (`{question, options[4]}`); answers remain private on the server
- `GET /mcqs` — list of the current user's past quiz sets (summary only)
- `GET /mcqs/{quiz_set_id}` — full quiz set with all questions

### Quiz attempts
- `POST /quiz/{quiz_set_id}/start` — creates a new attempt, returns its id
- `POST /quiz/attempts/{attempt_id}/submit` — `{answers: {"0": "B", "1": "A", ...}}`
  (question index → chosen option letter) → graded result
- `GET /quiz/attempts/{attempt_id}` — fetch a result again later
- `GET /quiz/attempts/{attempt_id}/pdf` — download the result as a PDF

### Progress
- `GET /progress` — chronological list of all finished attempts, useful for
  charting improvement over time in the Flutter app

## Suggested Flutter-side flow

1. Login screen → `POST /auth/login`, store the token (e.g. `flutter_secure_storage`).
2. Generate screen → subject/difficulty/count selectors →
   `POST /mcqs/generate`. Uploaded text is optional.
3. Quiz screen → `POST /quiz/{id}/start`, render questions one at a time
   from the returned `QuizSet.questions`, keep a local `Map<int, String>`
   of answers, run your own countdown timer client-side using
   `quiz_minutes`, and call `submit` either when the timer hits zero or the
   user finishes.
4. Result screen → show the returned grade/percentage, offer a button that
   hits `/quiz/attempts/{id}/pdf` and opens/shares the file.
5. Progress screen → `GET /progress` and display improvement over time.

## Notes / things to revisit before shipping

- `uploads/` currently stores files on local disk. Fine for a single-server
  deployment; move to S3/Cloud Storage if you scale beyond one instance.
- No rate limiting on `/mcqs/generate` yet — since this calls a paid Groq
  API per request, you'll likely want per-user daily/hourly limits before
  a public launch.
- `CORS_ORIGINS=*` is convenient for testing; set the exact HTTPS web origin
  before a public web release.
