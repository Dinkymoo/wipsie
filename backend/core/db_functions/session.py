"""
Database session management utilities.
"""

import logging
from contextlib import (
    contextmanager,
)
from typing import (
    Generator,
)

from sqlalchemy.exc import (
    SQLAlchemyError,
)
from sqlalchemy.orm import (
    Session,
)

from backend.db.database import (
    SessionLocal,
)

logger = logging.getLogger(__name__)


@contextmanager
def get_db_session() -> Generator[Session, None, None]:
    """
    Context manager for database sessions.
    Ensures proper session cleanup and rollback on errors.

    Usage:
        with get_db_session() as db:
            # perform database operations
            pass
    """
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except SQLAlchemyError as e:
        logger.error(f"Database error occurred: {e}")
        db.rollback()
        raise
    except Exception as e:
        logger.error(f"Unexpected error occurred: {e}")
        db.rollback()
        raise
    finally:
        db.close()


def get_db() -> Generator[Session, None, None]:
    """
    FastAPI dependency for database sessions.

    Usage in FastAPI routes:
        @app.get("/items/")
        async def read_items(db: Session = Depends(get_db)):
            return get_items(db)
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
