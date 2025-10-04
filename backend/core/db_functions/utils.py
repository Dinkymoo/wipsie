"""
Database migration and schema utilities.
"""

import logging
from typing import Any, Dict, List, Optional

from sqlalchemy import inspect, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)


def check_table_exists(db: Session, table_name: str) -> bool:
    """
    Check if a table exists in the database.

    Args:
        db: Database session
        table_name: Name of the table to check

    Returns:
        True if table exists, False otherwise
    """
    try:
        inspector = inspect(db.bind)
        return table_name in inspector.get_table_names()
    except SQLAlchemyError as e:
        logger.error(f"Error checking if table {table_name} exists: {e}")
        return False


def get_table_columns(db: Session, table_name: str) -> List[Dict[str, Any]]:
    """
    Get column information for a table.

    Args:
        db: Database session
        table_name: Name of the table

    Returns:
        List of column information dictionaries
    """
    try:
        inspector = inspect(db.bind)
        return inspector.get_columns(table_name)
    except SQLAlchemyError as e:
        logger.error(f"Error getting columns for table {table_name}: {e}")
        return []


def execute_raw_sql(db: Session, sql: str,
                    params: Optional[Dict[str, Any]] = None) -> Any:
    """
    Execute raw SQL query with optional parameters.

    Args:
        db: Database session
        sql: SQL query string
        params: Optional parameters for the query

    Returns:
        Query result
    """
    try:
        if params:
            result = db.execute(text(sql), params)
        else:
            result = db.execute(text(sql))
        db.commit()
        return result
    except SQLAlchemyError as e:
        logger.error(f"Error executing SQL query: {e}")
        db.rollback()
        raise


def get_database_version(db: Session) -> str:
    """
    Get the database version.

    Args:
        db: Database session

    Returns:
        Database version string
    """
    try:
        result = db.execute(text("SELECT version()"))
        version = result.scalar()
        return str(version) if version else "Unknown"
    except SQLAlchemyError as e:
        logger.error(f"Error getting database version: {e}")
        return "Unknown"


def vacuum_analyze_table(db: Session, table_name: str) -> bool:
    """
    Run VACUUM ANALYZE on a specific table (PostgreSQL specific).

    Args:
        db: Database session
        table_name: Name of the table to analyze

    Returns:
        True if successful, False otherwise
    """
    try:
        # Note: VACUUM cannot be run inside a transaction block
        db.execute(text(f"VACUUM ANALYZE {table_name}"))
        return True
    except SQLAlchemyError as e:
        logger.error(f"Error running VACUUM ANALYZE on {table_name}: {e}")
        return False


def get_table_size(db: Session, table_name: str) -> Dict[str, Any]:
    """
    Get size information for a table (PostgreSQL specific).

    Args:
        db: Database session
        table_name: Name of the table

    Returns:
        Dictionary with size information
    """
    try:
        sql = """
        SELECT
            pg_size_pretty(pg_total_relation_size(:table_name1)) as total_size,
            pg_size_pretty(pg_relation_size(:table_name2)) as table_size,
            pg_size_pretty(
                pg_total_relation_size(:table_name3) -
                pg_relation_size(:table_name4)
            ) as index_size
        """
        result = db.execute(text(sql), {
            "table_name1": table_name,
            "table_name2": table_name,
            "table_name3": table_name,
            "table_name4": table_name
        })
        row = result.fetchone()
        if row:
            return {
                "total_size": row[0],
                "table_size": row[1],
                "index_size": row[2]
            }
        return {}
    except SQLAlchemyError as e:
        logger.error(f"Error getting size for table {table_name}: {e}")
        return {}
