#!/usr/bin/env python3
"""
Quick test script to verify Aurora PostgreSQL connection.
"""

from backend.db.database import (
    engine,
)
from backend.core.config import (
    settings,
)
import sys
from pathlib import (
    Path,
)

from sqlalchemy import (
    text,
)

# Add the backend directory to Python path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))


def test_connection():
    """Test basic database connection."""
    print("🔌 Testing Aurora PostgreSQL connection...")
    print(f"📍 Database URL: {settings.DATABASE_URL}")

    try:
        with engine.connect() as conn:
            # Test basic connection
            result = conn.execute(text("SELECT version()"))
            row = result.fetchone()
            if row:
                version = row[0]
                print("✅ Connection successful!")
                print(f"📊 PostgreSQL Version: {version}")

            # Test database exists
            result = conn.execute(text("SELECT current_database()"))
            row = result.fetchone()
            if row:
                db_name = row[0]
                print(f"📂 Connected to database: {db_name}")

            # Test tables exist
            result = conn.execute(text("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                ORDER BY table_name
            """))

            tables = [row[0] for row in result.fetchall()]

            if tables:
                print(f"📋 Tables found: {', '.join(tables)}")

                # Count records in each table
                for table in tables:
                    result = conn.execute(
                        text(f"SELECT COUNT(*) FROM {table}")
                    )
                    row = result.fetchone()
                    if row:
                        count = row[0]
                        print(f"   {table}: {count} records")
            else:
                print("📋 No tables found (database is empty)")

            return True

    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False


def main():
    """Main function."""
    print("🧪 Aurora PostgreSQL Connection Test")
    print("=" * 40)

    if test_connection():
        print("\n🎉 Backend is ready to connect to Aurora!")
        print("\n🚀 Next steps:")
        print("1. Run: python backend/populate_database.py")
        print("2. Start backend: uvicorn backend.main:app --reload")
        print("3. Visit: http://localhost:8000/docs")
    else:
        print("\n❌ Connection failed. Check:")
        print("1. Aurora cluster is running")
        print("2. Database 'wipsie' exists")
        print("3. Password is correct")
        print("4. Security groups allow connections")


if __name__ == "__main__":
    main()
