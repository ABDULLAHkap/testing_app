from sqlalchemy import inspect, text

from app.database import engine


def apply_compatibility_migrations() -> None:
    """Small additive migration for the existing Render database.

    A full Alembic history should replace this before further schema changes.
    """
    if engine.dialect.name != "postgresql":
        return
    inspector = inspect(engine)
    user_columns = {column["name"] for column in inspector.get_columns("users")}
    quiz_columns = {column["name"] for column in inspector.get_columns("quiz_sets")}
    attempt_columns = {
        column["name"] for column in inspector.get_columns("quiz_attempts")
    }
    statements = []
    additions = {
        "gender": "VARCHAR(20)",
        "phone": "VARCHAR(30)",
        "target_exam": "VARCHAR(30) NOT NULL DEFAULT 'MDCAT'",
        "email_verified": "BOOLEAN NOT NULL DEFAULT TRUE",
        "is_admin": "BOOLEAN NOT NULL DEFAULT FALSE",
        "subscription_expires_at": "TIMESTAMP WITH TIME ZONE",
        "last_seen_at": "TIMESTAMP WITH TIME ZONE",
    }
    for name, definition in additions.items():
        if name not in user_columns:
            statements.append(f"ALTER TABLE users ADD COLUMN {name} {definition}")
    if "exam_type" not in quiz_columns:
        statements.append(
            "ALTER TABLE quiz_sets ADD COLUMN exam_type VARCHAR(30) NOT NULL DEFAULT 'MDCAT'"
        )
    quiz_additions = {
        "mode": "VARCHAR(30) NOT NULL DEFAULT 'topic'",
        "negative_marking": "DOUBLE PRECISION NOT NULL DEFAULT 0",
        "format_version": "VARCHAR(80)",
        "section_config": "JSON",
    }
    for name, definition in quiz_additions.items():
        if name not in quiz_columns:
            statements.append(
                f"ALTER TABLE quiz_sets ADD COLUMN {name} {definition}"
            )
    if "question_times" not in attempt_columns:
        statements.append(
            "ALTER TABLE quiz_attempts ADD COLUMN question_times JSON"
        )
    statements.append(
        "CREATE TABLE IF NOT EXISTS exam_subscriptions ("
        "id SERIAL PRIMARY KEY, "
        "user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, "
        "exam_type VARCHAR(30) NOT NULL, "
        "expires_at TIMESTAMP WITH TIME ZONE NOT NULL, "
        "created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(), "
        "updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(), "
        "UNIQUE(user_id, exam_type)"
        ")"
    )
    statements.append(
        "CREATE INDEX IF NOT EXISTS ix_exam_subscriptions_user_id "
        "ON exam_subscriptions(user_id)"
    )
    statements.append(
        "INSERT INTO exam_subscriptions "
        "(user_id, exam_type, expires_at, created_at, updated_at) "
        "SELECT id, target_exam, subscription_expires_at, NOW(), NOW() FROM users "
        "WHERE subscription_expires_at IS NOT NULL AND subscription_expires_at > NOW() "
        "ON CONFLICT (user_id, exam_type) DO NOTHING"
    )
    if statements:
        with engine.begin() as connection:
            for statement in statements:
                connection.execute(text(statement))
