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
    if statements:
        with engine.begin() as connection:
            for statement in statements:
                connection.execute(text(statement))
