"""
SQLAlchemy Factory classes for generating test data.
Uses Factory Boy with Faker for realistic data generation.
"""

from datetime import (
    datetime,
)
from typing import (
    Any,
    Dict,
)

import factory
from factory import (
    fuzzy,
)
from factory.alchemy import (
    SQLAlchemyModelFactory,
)
from faker import (
    Faker,
)

from backend.db.database import (
    SessionLocal,
)
from backend.models.models import (
    DataPoint,
    Task,
    User,
)

fake = Faker()


class UserFactory(SQLAlchemyModelFactory):
    """Factory for User model."""

    class Meta:
        model = User
        sqlalchemy_session = SessionLocal
        sqlalchemy_session_persistence = "commit"

    id = factory.Sequence(lambda n: n)
    username = factory.LazyAttribute(lambda obj: fake.user_name())
    email = factory.LazyAttribute(lambda obj: fake.email())
    password_hash = factory.LazyAttribute(
        lambda obj: "$2b$12$sample_hash_" + fake.lexify(text="????????")
    )
    created_at = factory.LazyFunction(datetime.now)
    updated_at = factory.LazyFunction(datetime.now)


class TaskFactory(SQLAlchemyModelFactory):
    """Factory for Task model."""

    class Meta:
        model = Task
        sqlalchemy_session = SessionLocal
        sqlalchemy_session_persistence = "commit"

    id = factory.Sequence(lambda n: n)
    user_id = factory.SubFactory(UserFactory)
    title = factory.LazyAttribute(lambda obj: fake.sentence(nb_words=4))
    description = factory.LazyAttribute(
        lambda obj: fake.paragraph(nb_sentences=3))
    status = fuzzy.FuzzyChoice(
        ["pending", "in_progress", "completed", "cancelled"])
    priority = fuzzy.FuzzyInteger(1, 5)
    due_date = factory.LazyAttribute(
        lambda obj: fake.date_time_between(
            start_date="now", end_date="+30d"
        ) if fake.boolean(chance_of_getting_true=70) else None
    )
    created_at = factory.LazyFunction(datetime.now)
    updated_at = factory.LazyFunction(datetime.now)


class DataPointFactory(SQLAlchemyModelFactory):
    """Factory for DataPoint model."""

    class Meta:
        model = DataPoint
        sqlalchemy_session = SessionLocal
        sqlalchemy_session_persistence = "commit"

    id = factory.Sequence(lambda n: n)
    task_id = factory.SubFactory(TaskFactory)
    data_type = fuzzy.FuzzyChoice([
        "completion_rate", "response_time", "error_count", "user_activity",
        "performance_metric", "status_update", "log_entry"
    ])
    value_json = factory.LazyAttribute(
        lambda obj: _generate_value_json(obj.data_type))
    meta_data = factory.LazyAttribute(
        lambda obj: _generate_metadata(obj.data_type))
    timestamp = factory.LazyAttribute(
        lambda obj: fake.date_time_between(start_date="-7d", end_date="now")
    )
    created_at = factory.LazyFunction(datetime.now)


def _generate_value_json(data_type: str) -> Dict[str, Any]:
    """Generate realistic JSON data based on data type."""
    if data_type == "completion_rate":
        return {
            "percentage": fake.random_int(min=0, max=100),
            "total_tasks": fake.random_int(min=1, max=50),
            "completed_tasks": fake.random_int(min=0, max=50)
        }
    elif data_type == "response_time":
        return {
            "milliseconds": fake.random_int(min=50, max=5000),
            "endpoint": fake.uri_path(),
            "method": fake.random_element(elements=("GET", "POST", "PUT", "DELETE"))
        }
    elif data_type == "error_count":
        return {
            "count": fake.random_int(min=0, max=10),
            "error_type": fake.random_element(elements=(
                "validation_error", "database_error", "network_error", "timeout"
            )),
            "severity": fake.random_element(elements=("low", "medium", "high", "critical"))
        }
    elif data_type == "user_activity":
        return {
            "action": fake.random_element(elements=(
                "login", "logout", "create_task", "update_task", "delete_task"
            )),
            "ip_address": fake.ipv4(),
            "user_agent": fake.user_agent()
        }
    elif data_type == "performance_metric":
        return {
            "cpu_usage": round(fake.random.uniform(0, 100), 2),
            "memory_usage": round(fake.random.uniform(0, 100), 2),
            "disk_usage": round(fake.random.uniform(0, 100), 2)
        }
    elif data_type == "status_update":
        return {
            "old_status": fake.random_element(elements=("pending", "in_progress", "completed")),
            "new_status": fake.random_element(elements=("pending", "in_progress", "completed")),
            "reason": fake.sentence()
        }
    else:  # log_entry or default
        return {
            "level": fake.random_element(elements=("DEBUG", "INFO", "WARNING", "ERROR")),
            "message": fake.sentence(),
            "module": fake.word()
        }


def _generate_metadata(data_type: str) -> Dict[str, Any]:
    """Generate metadata based on data type."""
    base_metadata = {
        "source": fake.random_element(elements=(
            "api", "lambda", "poller", "manual", "automated"
        )),
        "version": fake.random_element(elements=("1.0", "1.1", "2.0")),
        "environment": fake.random_element(elements=("development", "staging", "production"))
    }

    if data_type in ["response_time", "performance_metric"]:
        base_metadata["server_id"] = fake.uuid4()
        base_metadata["region"] = fake.random_element(elements=(
            "us-east-1", "us-west-2", "eu-west-1"
        ))

    return base_metadata


# Convenience functions for creating test data
def create_user(**kwargs) -> User:
    """Create a single user with optional overrides."""
    return UserFactory(**kwargs)


def create_users(count: int, **kwargs) -> list[User]:
    """Create multiple users."""
    return UserFactory.create_batch(count, **kwargs)


def create_task(**kwargs) -> Task:
    """Create a single task with optional overrides."""
    return TaskFactory(**kwargs)


def create_tasks(count: int, **kwargs) -> list[Task]:
    """Create multiple tasks."""
    return TaskFactory.create_batch(count, **kwargs)


def create_data_point(**kwargs) -> DataPoint:
    """Create a single data point with optional overrides."""
    return DataPointFactory(**kwargs)


def create_data_points(count: int, **kwargs) -> list[DataPoint]:
    """Create multiple data points."""
    return DataPointFactory.create_batch(count, **kwargs)


def create_complete_dataset(
    num_users: int = 5,
    tasks_per_user: int = 3,
    data_points_per_task: int = 2
) -> Dict[str, list]:
    """
    Create a complete dataset with users, tasks, and data points.

    Args:
        num_users: Number of users to create
        tasks_per_user: Number of tasks per user
        data_points_per_task: Number of data points per task

    Returns:
        Dictionary with created objects
    """
    # Create a database session for this operation
    db = SessionLocal()

    try:
        users = []
        tasks = []
        data_points = []

        # Create users
        for i in range(num_users):
            user = User(
                username=f"user{i}",
                email=f"user{i}@{fake.domain_name()}",
                password_hash=f"hashed_{fake.password(length=12)}",
                created_at=fake.date_time_this_year(),
                updated_at=fake.date_time_this_month()
            )
            db.add(user)
            db.flush()  # Get the ID
            users.append(user)

            # Create tasks for this user
            for j in range(tasks_per_user):
                task = Task(
                    user_id=user.id,
                    title=fake.sentence(nb_words=4).rstrip('.'),
                    description=fake.text(max_nb_chars=200),
                    status=fake.random_element(
                        elements=('todo', 'in_progress', 'done')
                    ),
                    priority=fake.random_element(
                        elements=(1, 2, 3)  # 1=low, 2=medium, 3=high
                    ),
                    due_date=fake.date_between(
                        start_date='today', end_date='+30d'
                    ),
                    created_at=fake.date_time_this_year(),
                    updated_at=fake.date_time_this_month()
                )
                db.add(task)
                db.flush()  # Get the ID
                tasks.append(task)

                # Create data points for this task
                for k in range(data_points_per_task):
                    data_type = fake.random_element(elements=(
                        'completion_rate', 'time_spent', 'server_metrics'
                    ))

                    data_point = DataPoint(
                        task_id=task.id,
                        data_type=data_type,
                        value_json=_generate_value_json(data_type),
                        meta_data=_generate_metadata(data_type),
                        timestamp=fake.date_time_this_month(),
                        created_at=fake.date_time_this_month()
                    )
                    db.add(data_point)
                    data_points.append(data_point)

        # Commit all changes
        db.commit()

        return {
            "users": users,
            "tasks": tasks,
            "data_points": data_points
        }
    except Exception as e:
        db.rollback()
        raise e
    finally:
        db.close()


# Example usage in tests or scripts
if __name__ == "__main__":
    # Create sample data
    print("Creating sample data...")

    # Create a complete dataset
    dataset = create_complete_dataset(
        num_users=3,
        tasks_per_user=2,
        data_points_per_task=3
    )

    print(f"Created {len(dataset['users'])} users")
    print(f"Created {len(dataset['tasks'])} tasks")
    print(f"Created {len(dataset['data_points'])} data points")

    # Example of individual creation
    user = create_user(username="test_user", email="test@example.com")
    task = create_task(
        user_id=user.id,
        title="Sample Task",
        status="in_progress"
    )

    print(f"Created user: {user.username}")
    print(f"Created task: {task.title}")
