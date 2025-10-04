"""
Database functions module for Wipsie backend.
Contains utility functions and operations for database interactions.
"""

import logging

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    create_engine,
)
from sqlalchemy.exc import (
    SQLAlchemyError,
)
from sqlalchemy.orm import (
    Session,
    declarative_base,
    relationship,
    sessionmaker,
)

from .queries import (
    BaseRepository,
    filter_by_fields,
    order_by_field,
    search_by_text,
)

# Import our custom modules
from .session import (
    get_db,
    get_db_session,
)
from .utils import (
    check_table_exists,
    execute_raw_sql,
    get_database_version,
    get_table_columns,
    get_table_size,
    vacuum_analyze_table,
)

logger = logging.getLogger(__name__)

# Re-export commonly used SQLAlchemy ORM components for convenience
__all__ = [
    # SQLAlchemy core
    "Session",
    "sessionmaker",
    "declarative_base",
    "relationship",
    "create_engine",
    "Column",
    "Integer",
    "String",
    "DateTime",
    "Boolean",
    "ForeignKey",
    "Text",
    "SQLAlchemyError",
    # Session management
    "get_db_session",
    "get_db",
    # Query utilities
    "BaseRepository",
    "filter_by_fields",
    "search_by_text",
    "order_by_field",
    # Database utilities
    "check_table_exists",
    "get_table_columns",
    "execute_raw_sql",
    "get_database_version",
    "vacuum_analyze_table",
    "get_table_size",
]
