from datetime import (
    datetime,
)
from typing import (
    Any,
    Dict,
    Optional,
)

from pydantic import (
    BaseModel,
    EmailStr,
)


# User schemas
class UserBase(BaseModel):
    username: str
    email: EmailStr


class UserCreate(UserBase):
    password_hash: str


class UserResponse(UserBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# Task schemas
class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    status: str = "pending"
    priority: int = 1
    due_date: Optional[datetime] = None


class TaskCreate(TaskBase):
    user_id: int


class TaskResponse(TaskBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# DataPoint schemas
class DataPointBase(BaseModel):
    data_type: str
    value_json: Optional[Dict[str, Any]] = None
    meta_data: Optional[Dict[str, Any]] = None


class DataPointCreate(DataPointBase):
    task_id: int


class DataPointResponse(DataPointBase):
    id: int
    task_id: int
    timestamp: datetime
    created_at: datetime

    class Config:
        from_attributes = True
