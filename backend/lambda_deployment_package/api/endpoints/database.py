"""
API endpoints for Users, Tasks, and DataPoints.
Provides CRUD operations for the Aurora PostgreSQL database.
"""

from typing import (
    List,
    Optional,
)

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
)
from sqlalchemy.orm import (
    Session,
)

from backend.db.database import (
    get_db,
)
from backend.models.models import (
    DataPoint,
    Task,
    User,
)
from backend.schemas.aurora_schemas import (
    DataPointCreate,
    DataPointResponse,
    TaskCreate,
    TaskResponse,
    UserCreate,
    UserResponse,
)

router = APIRouter(prefix="/api/v1", tags=["database"])


# User endpoints
@router.get("/users", response_model=List[UserResponse])
async def get_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, le=1000),
    db: Session = Depends(get_db)
):
    """Get all users with pagination."""
    users = db.query(User).offset(skip).limit(limit).all()
    return users


@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: Session = Depends(get_db)):
    """Get a specific user by ID."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.post("/users", response_model=UserResponse)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    """Create a new user."""
    # Check if username or email already exists
    existing = db.query(User).filter(
        (User.username == user.username) | (User.email == user.email)
    ).first()

    if existing:
        raise HTTPException(
            status_code=400,
            detail="Username or email already exists"
        )

    db_user = User(**user.dict())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


# Task endpoints
@router.get("/tasks", response_model=List[TaskResponse])
async def get_tasks(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, le=1000),
    status: Optional[str] = Query(None),
    user_id: Optional[int] = Query(None),
    db: Session = Depends(get_db)
):
    """Get tasks with optional filtering."""
    query = db.query(Task)

    if status:
        query = query.filter(Task.status == status)

    if user_id:
        query = query.filter(Task.user_id == user_id)

    tasks = query.offset(skip).limit(limit).all()
    return tasks


@router.get("/tasks/{task_id}", response_model=TaskResponse)
async def get_task(task_id: int, db: Session = Depends(get_db)):
    """Get a specific task by ID."""
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@router.post("/tasks", response_model=TaskResponse)
async def create_task(task: TaskCreate, db: Session = Depends(get_db)):
    """Create a new task."""
    # Verify user exists
    user = db.query(User).filter(User.id == task.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    db_task = Task(**task.dict())
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task


@router.put("/tasks/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: int,
    task_update: TaskCreate,
    db: Session = Depends(get_db)
):
    """Update a task."""
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    for field, value in task_update.dict(exclude_unset=True).items():
        setattr(task, field, value)

    db.commit()
    db.refresh(task)
    return task


# DataPoint endpoints
@router.get("/data-points", response_model=List[DataPointResponse])
async def get_data_points(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, le=1000),
    task_id: Optional[int] = Query(None),
    data_type: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    """Get data points with optional filtering."""
    query = db.query(DataPoint)

    if task_id:
        query = query.filter(DataPoint.task_id == task_id)

    if data_type:
        query = query.filter(DataPoint.data_type == data_type)

    data_points = query.offset(skip).limit(limit).all()
    return data_points


@router.post("/data-points", response_model=DataPointResponse)
async def create_data_point(
    data_point: DataPointCreate,
    db: Session = Depends(get_db)
):
    """Create a new data point."""
    # Verify task exists
    task = db.query(Task).filter(Task.id == data_point.task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    db_data_point = DataPoint(**data_point.dict())
    db.add(db_data_point)
    db.commit()
    db.refresh(db_data_point)
    return db_data_point


# Analytics endpoints
@router.get("/analytics/user-stats")
async def get_user_stats(db: Session = Depends(get_db)):
    """Get user statistics."""
    from sqlalchemy import (
        func,
    )

    stats = db.query(
        func.count(User.id).label("total_users"),
        func.count(Task.id).label("total_tasks"),
        func.count(DataPoint.id).label("total_data_points")
    ).select_from(User).outerjoin(Task).outerjoin(DataPoint).first()

    task_stats = db.query(
        Task.status,
        func.count(Task.id).label("count")
    ).group_by(Task.status).all()

    return {
        "total_users": stats.total_users,
        "total_tasks": stats.total_tasks,
        "total_data_points": stats.total_data_points,
        "tasks_by_status": [
            {"status": stat.status, "count": stat.count}
            for stat in task_stats
        ]
    }


@router.get("/analytics/task-completion")
async def get_task_completion_data(db: Session = Depends(get_db)):
    """Get task completion analytics from data points."""
    from sqlalchemy import (
        and_,
        func,
        text,
    )

    # Get completion rate data points
    completion_data = db.execute(text("""
        SELECT 
            t.title,
            t.status,
            dp.value_json->>'percentage' as completion_percentage,
            dp.timestamp
        FROM tasks t
        JOIN data_points dp ON t.id = dp.task_id
        WHERE dp.data_type = 'completion_rate'
        ORDER BY dp.timestamp DESC
        LIMIT 20
    """)).fetchall()

    return [
        {
            "task_title": row.title,
            "task_status": row.status,
            "completion_percentage": row.completion_percentage,
            "timestamp": row.timestamp
        }
        for row in completion_data
    ]
