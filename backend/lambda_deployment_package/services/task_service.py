from typing import (
    List,
    Optional,
)

from sqlalchemy.orm import (
    Session,
)

from models.models import (
    Task,
)
from schemas.schemas import (
    TaskCreate,
    TaskUpdate,
)


class TaskService:
    @staticmethod
    def get_tasks(db: Session, skip: int = 0, limit: int = 100) -> List[Task]:
        """Get all tasks with pagination"""
        return db.query(Task).offset(skip).limit(limit).all()

    @staticmethod
    def get_task(db: Session, task_id: int) -> Optional[Task]:
        """Get a specific task by ID"""
        return db.query(Task).filter(Task.id == task_id).first()

    @staticmethod
    def create_task(db: Session, task: TaskCreate) -> Task:
        """Create a new task"""
        db_task = Task(**task.dict())
        db.add(db_task)
        db.commit()
        db.refresh(db_task)
        return db_task

    @staticmethod
    def update_task(
        db: Session, task_id: int, task_update: TaskUpdate
    ) -> Optional[Task]:
        """Update an existing task"""
        db_task = db.query(Task).filter(Task.id == task_id).first()
        if not db_task:
            return None

        update_data = task_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_task, field, value)

        db.commit()
        db.refresh(db_task)
        return db_task

    @staticmethod
    def delete_task(db: Session, task_id: int) -> bool:
        """Delete a task"""
        db_task = db.query(Task).filter(Task.id == task_id).first()
        if not db_task:
            return False

        db.delete(db_task)
        db.commit()
        return True
