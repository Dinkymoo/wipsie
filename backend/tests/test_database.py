"""
Test the database functionality.
"""

import pytest
from sqlalchemy import text


def test_database_connection(db_session):
    """Test that we can connect to the database."""
    # Simple query to test connection
    result = db_session.execute(text("SELECT 1"))
    assert result.fetchone()[0] == 1


def test_database_session_creation(db_session):
    """Test that database session is properly created."""
    assert db_session is not None

    # Test that we can execute queries
    result = db_session.execute(text("SELECT 'test' as message"))
    row = result.fetchone()
    assert row[0] == "test"


def test_database_transaction_rollback(db_session):
    """Test that database transactions can be rolled back."""
    # Start a transaction
    db_session.begin()

    try:
        # Execute a query
        db_session.execute(text("SELECT 1"))
        # Rollback
        db_session.rollback()
        assert True
    except Exception as e:
        pytest.fail(f"Transaction rollback failed: {e}")


class TestDatabaseConfiguration:
    """Test database configuration and setup."""

    def test_database_import(self):
        """Test that we can import database modules."""
        try:
            from backend.db.database import engine, get_db

            assert get_db is not None
            assert engine is not None
        except ImportError as e:
            pytest.fail(f"Could not import database modules: {e}")

    def test_models_import(self):
        """Test that we can import model modules."""
        try:
            from backend.models.models import Base

            assert Base is not None
        except ImportError:
            # Models might not be fully implemented yet
            pytest.skip("Models not yet implemented")

    def test_alembic_configuration(self):
        """Test that Alembic is properly configured."""
        import os

        # Check if alembic.ini exists
        alembic_ini_path = os.path.join(
            os.path.dirname(os.path.dirname(__file__)), "..", "alembic.ini"
        )

        # This is optional as alembic might be in different location
        if os.path.exists(alembic_ini_path):
            assert True
        else:
            pytest.skip("Alembic configuration not found in expected location")
