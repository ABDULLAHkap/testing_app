# Multi-Exam Preparation App

A Flutter study app backed by FastAPI, Gemini-generated MCQs, JWT authentication,
and PostgreSQL. The Flutter client talks to the API; it never connects directly
to the database.

## Project structure

| Path                 | Purpose                                                      |
| -------------------- | ------------------------------------------------------------ |
| `mdcat_app/`         | Flutter app for Android, web, iOS, macOS, Windows, and Linux |
| `mdcat_backend/`     | FastAPI API, authentication, quiz generation, and grading    |
| `render.yaml`        | One-click Render Blueprint for the API and PostgreSQL        |
| `.github/workflows/` | Backend checks, Flutter checks, and Android APK builds       |

## Deploy the online API and database

These steps create one shared online PostgreSQL database. Users on different
devices can then register, log in, and access their own saved quizzes and
progress.

1. Create a Gemini API key in Google AI Studio. Never commit a real key.
2. Sign in to [Render](https://dashboard.render.com/) and choose
   **New > Blueprint**.
3. Connect this GitHub repository and select the `main` branch. Render reads
   `render.yaml` and creates both `mdcat-backend` and `mdcat-database`.
4. When Render asks for `GEMINI_API_KEY`, enter the new key. `JWT_SECRET_KEY` is
   generated automatically and `DATABASE_URL` is connected automatically.
5. Wait for the deployment to become live, then open:
   `https://YOUR-SERVICE.onrender.com/health`. The response should be
   `{"status":"healthy"}`.
6. Copy the service URL without a trailing slash.

Do not upload `mdcat.db` to GitHub. It is a local SQLite development database,
not the production database. The PostgreSQL service configured in
`render.yaml` is the production data store.

## Publish the web app for any device

1. In this repository, open **Settings > Secrets and variables > Actions**.
2. Open the **Variables** tab and create a repository variable named
   `API_BASE_URL` whose value is your Render URL, for example
   `https://mdcat-backend.onrender.com`.
3. Open **Settings > Pages** and select **GitHub Actions** as the source.
4. Open **Actions > Deploy Web App > Run workflow**.
5. After deployment, open
   `https://abdullahkap.github.io/testing_app/` on any modern phone, tablet, or
   computer browser.

## Build an Android APK on GitHub

After setting `API_BASE_URL` as described above:

1. Open **Actions > Build Android APK > Run workflow**.
2. When the workflow finishes, download the `mdcat-android-apk` artifact.
3. Extract the ZIP and install `app-release.apk` on an Android phone. Android
   may ask you to allow installation from the browser or file manager.

This APK uses development signing so it can be tested on phones. Before a Play
Store release, replace the example Android application ID and configure a
private release signing key. Never commit that signing key or its password.

## Run the Flutter app locally

Install Flutter, then run:

```bash
cd mdcat_app
flutter pub get
flutter run --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com
```

For an Android emulator with a backend running on the same computer, the app's
fallback URL is `http://10.0.2.2:8000`. On a physical device, use the
**Server settings** button on the login screen to enter either the Render HTTPS
URL or your computer's LAN URL.

To build the web version:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com
```

The generated static site is in `mdcat_app/build/web`. Host it on any HTTPS
static host. If you know the final web origin, replace `CORS_ORIGINS: "*"` in
`render.yaml` with that origin for a stricter browser policy.

## Run the backend locally

```bash
cd mdcat_backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Set a real `GEMINI_API_KEY` and a long random `JWT_SECRET_KEY` in the local
`.env`. Local development uses SQLite unless `DATABASE_URL` is changed.

## Security and data behavior

- Passwords are hashed and API access uses seven-day JWT tokens.
- Correct options and explanations stay on the server while a quiz is active.
- Attempts cannot be submitted twice and the server enforces the quiz deadline.
- Generated question batches are de-duplicated and a quiz is saved only when the requested
  number of unique questions was generated.
- `.env`, local databases, uploaded study files, build output, IDE files, and
  signing files are excluded from Git.

The generation endpoints call a paid or rate-limited external question service. Add
per-user rate limits and production monitoring before opening the app to a
large public audience.

## Enable push notifications

The notification code is optional: the app continues to build and run when
Firebase is not configured. To activate announcements and reminders:

1. Create a Firebase project, register Web and Android apps, and enable Cloud
   Messaging.
2. In the Render **static site**, add `FIREBASE_API_KEY`, `FIREBASE_APP_ID`,
   `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`,
   `FIREBASE_STORAGE_BUCKET`, and `FIREBASE_WEB_VAPID_KEY`.
3. In Firebase **Project settings > Service accounts**, create a private key.
   Put the complete one-line JSON into the backend Render variable
   `FIREBASE_SERVICE_ACCOUNT_JSON`. Never commit this JSON.
4. Copy the backend's `NOTIFICATION_CRON_SECRET` value into a GitHub Actions
   repository secret with the same name. The hourly workflow then sends exam
   countdown, study, and subscription-expiry reminders.
5. Redeploy the backend and static site. Sign in and use
   **Settings > Push notifications** on each device.
