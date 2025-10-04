from typing import (
    List,
)

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)
from sqlalchemy.orm import (
    Session,
)

from backend.db.database import (
    get_db,
)
from backend.schemas.schemas import (
    Task,
    TaskCreate,
    TaskUpdate,
)
from backend.services.task_service import (
    TaskService,
)

router = APIRouter()


@router.get("/", response_model=List[Task])
async def get_tasks(
    skip: int = 0, limit: int = 100, db: Session = Depends(get_db)
):
    """Get all tasks"""
    return TaskService.get_tasks(db, skip=skip, limit=limit)


@router.post("/", response_model=Task)
async def create_task(task: TaskCreate, db: Session = Depends(get_db)):
    """Create a new task"""
    return TaskService.create_task(db, task)


@router.get("/{task_id}", response_model=Task)
async def get_task(task_id: int, db: Session = Depends(get_db)):
    """Get a specific task"""
    task = TaskService.get_task(db, task_id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Task not found"
        )
    return task


@router.put("/{task_id}", response_model=Task)
async def update_task(
    task_id: int, task_update: TaskUpdate, db: Session = Depends(get_db)
):
    """Update a task"""
    task = TaskService.update_task(db, task_id, task_update)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Task not found"
        )
    return task


@router.delete("/{task_id}")
async def delete_task(task_id: int, db: Session = Depends(get_db)):
    """Delete a task"""
    success = TaskService.delete_task(db, task_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Task not found"
        )
    return {"message": "Task deleted successfully"}
