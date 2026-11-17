import logging
from contextlib import contextmanager
from typing import Generator
from sqlalchemy import create_engine, text
from sqlalchemy.orm import DeclarativeBase, sessionmaker, Session

from app.config import get_settings

logger = logging.getLogger("stitch_style.database")
settings = get_settings()

# Engine configuration with psycopg 3 driver and resilient pool
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,       # Validates connections before checkout
    pool_size=10,             # Base connection pool size
    max_overflow=20,          # Extra burst connections
    pool_recycle=1800,        # Recycle connections after 30 minutes
    echo=settings.DEBUG,      # Echo SQL in debug mode
)

SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    """SQLAlchemy 2.0 Declarative Base with type annotations."""
    pass


def get_db() -> Generator[Session, None, None]:
    """FastAPI route dependency that provides a transactional database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@contextmanager
def get_db_context() -> Generator[Session, None, None]:
    """Context manager for background tasks, migrations, and CLI provisioning scripts."""
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def check_database_connection() -> bool:
    """Executes a lightweight ping against PostgreSQL."""
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        return True
    except Exception as e:
        logger.error(f"Database connection check failed: {e}")
        return False
