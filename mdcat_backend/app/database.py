"""
Database configuration.
Uses SQLite by default (file: mdcat.db) — swap DATABASE_URL for
Postgres/MySQL in production without changing any other code.
"""

import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, declarative_base

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./mdcat.db")

# Render supplies a standard PostgreSQL URL. Select SQLAlchemy's psycopg 3
# driver explicitly so the same configuration works locally and in production.
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace(
        "postgresql://", "postgresql+psycopg://", 1
    )

is_sqlite = DATABASE_URL.startswith("sqlite")
connect_args = (
    {"check_same_thread": False, "timeout": 30}
    if is_sqlite
    else {}
)

engine_options = {
    "connect_args": connect_args,
    "pool_pre_ping": True,
}
if not is_sqlite:
    # Generation requests can be longer than ordinary API requests.  Keep
    # enough short-lived overflow capacity so 10-15 concurrent students do
    # not starve login, OTP, heartbeat, or quiz-submission requests.
    engine_options.update(
        pool_size=max(5, int(os.getenv("DB_POOL_SIZE", "10"))),
        max_overflow=max(10, int(os.getenv("DB_MAX_OVERFLOW", "20"))),
        pool_timeout=30,
        pool_recycle=1800,
    )

engine = create_engine(
    DATABASE_URL,
    **engine_options,
)


if is_sqlite:
    @event.listens_for(engine, "connect")
    def _enable_sqlite_foreign_keys(dbapi_connection, _connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.execute("PRAGMA journal_mode=WAL")
        cursor.execute("PRAGMA synchronous=NORMAL")
        cursor.execute("PRAGMA busy_timeout=30000")
        cursor.close()


SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
