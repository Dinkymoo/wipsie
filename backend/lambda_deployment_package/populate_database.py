#!/usr/bin/env python3
"""
Database population script using SQLAlchemy factories.
Populates the Aurora PostgreSQL database with realistic test data.
"""

from models.models import (
    Base,
)
from factories import (
    create_complete_dataset,
)
from db.database import (
    SessionLocal,
    engine,
)
from sqlalchemy import (
    text,
)
import sys
from pathlib import (
    Path,
)

# Add the backend directory to Python path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))


def check_database_connection():
    """Test database connection."""
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT version()"))
            version = result.fetchone()[0]
            print(f"✅ Connected to PostgreSQL: {version}")
            return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False


def create_tables():
    """Create all tables if they don't exist."""
    try:
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created/verified")
        return True
    except Exception as e:
        print(f"❌ Failed to create tables: {e}")
        return False


def check_existing_data():
    """Check if database already has data."""
    try:
        with SessionLocal() as db:
            # Check for existing users
            result = db.execute(text("SELECT COUNT(*) FROM users"))
            user_count = result.fetchone()[0]

            result = db.execute(text("SELECT COUNT(*) FROM tasks"))
            task_count = result.fetchone()[0]

            result = db.execute(text("SELECT COUNT(*) FROM data_points"))
            data_point_count = result.fetchone()[0]

            print(
                f"📊 Existing data: {user_count} users, {task_count} tasks, {data_point_count} data points")

            return user_count > 0
    except Exception as e:
        print(f"⚠️ Could not check existing data: {e}")
        return False


def populate_database(num_users=10, tasks_per_user=5, data_points_per_task=3):
    """Populate database with test data."""
    print(
        f"🏗️ Creating test data: {num_users} users, {tasks_per_user} tasks each, {data_points_per_task} data points each")

    try:
        dataset = create_complete_dataset(
            num_users=num_users,
            tasks_per_user=tasks_per_user,
            data_points_per_task=data_points_per_task
        )

        print(f"✅ Successfully created:")
        print(f"   👥 {len(dataset['users'])} users")
        print(f"   📋 {len(dataset['tasks'])} tasks")
        print(f"   📊 {len(dataset['data_points'])} data points")

        return dataset
    except Exception as e:
        print(f"❌ Failed to create test data: {e}")
        return None


def display_sample_data():
    """Display sample of created data."""
    try:
        with SessionLocal() as db:
            # Sample query to show relationships
            result = db.execute(text("""
                SELECT 
                    u.username,
                    u.email,
                    t.title,
                    t.status,
                    dp.data_type,
                    dp.value_json->>'percentage' as completion_percentage
                FROM users u
                JOIN tasks t ON u.id = t.user_id
                LEFT JOIN data_points dp ON t.id = dp.task_id
                WHERE dp.data_type = 'completion_rate'
                LIMIT 5
            """))

            print("\n📋 Sample data (users with completion rate data):")
            print("Username | Email | Task | Status | Completion %")
            print("-" * 60)

            for row in result:
                username, email, title, status, completion = row
                print(
                    f"{username[:12]:<12} | {email[:20]:<20} | {title[:15]:<15} | {status:<10} | {completion or 'N/A'}")

    except Exception as e:
        print(f"⚠️ Could not display sample data: {e}")


def main():
    """Main execution function."""
    print("🚀 Aurora PostgreSQL Database Population Script")
    print("=" * 50)

    # Check database connection
    if not check_database_connection():
        print("Please check your Aurora cluster and database configuration.")
        sys.exit(1)

    # Create/verify tables
    if not create_tables():
        print("Failed to create database tables.")
        sys.exit(1)

    # Check existing data
    has_data = check_existing_data()

    if has_data:
        response = input(
            "\n⚠️ Database already contains data. Add more? (y/N): ").lower()
        if response != 'y':
            print("👋 Exiting without changes.")
            display_sample_data()
            return

    # Get user preferences
    print("\n🎯 Data generation options:")
    print("1. Small dataset (5 users, 3 tasks each, 2 data points each)")
    print("2. Medium dataset (10 users, 5 tasks each, 3 data points each)")
    print("3. Large dataset (20 users, 8 tasks each, 5 data points each)")
    print("4. Custom")

    choice = input("Choose option (1-4) [2]: ").strip() or "2"

    if choice == "1":
        num_users, tasks_per_user, data_points_per_task = 5, 3, 2
    elif choice == "3":
        num_users, tasks_per_user, data_points_per_task = 20, 8, 5
    elif choice == "4":
        num_users = int(input("Number of users [10]: ") or "10")
        tasks_per_user = int(input("Tasks per user [5]: ") or "5")
        data_points_per_task = int(input("Data points per task [3]: ") or "3")
    else:  # Default to medium
        num_users, tasks_per_user, data_points_per_task = 10, 5, 3

    # Populate database
    dataset = populate_database(
        num_users, tasks_per_user, data_points_per_task)

    if dataset:
        print("\n🎉 Database population completed!")
        display_sample_data()

        print("\n🔗 Test your data in Aurora Query Editor:")
        print("https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:")
        print("\nSample queries to try:")
        print("SELECT * FROM users LIMIT 5;")
        print("SELECT u.username, COUNT(t.id) as task_count FROM users u LEFT JOIN tasks t ON u.id = t.user_id GROUP BY u.username;")
        print("SELECT data_type, COUNT(*) FROM data_points GROUP BY data_type;")
    else:
        print("❌ Database population failed.")
        sys.exit(1)


if __name__ == "__main__":
    main()
