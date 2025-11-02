from datetime import (
    datetime,
)
from typing import (
    Optional,
)

from pydantic import (
    BaseModel,
    EmailStr,
)

# User Schemas


class UserBase(BaseModel):
    email: EmailStr
    username: str


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    is_active: Optional[bool] = None


class User(UserBase):
    id: int
    is_active: bool
    is_superuser: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# Task Schemas


class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None


class TaskCreate(TaskBase):
    pass


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None


class Task(TaskBase):
    id: int
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# Data Point Schemas


class DataPointBase(BaseModel):
    name: str
    value: str
    source: Optional[str] = None


class DataPointCreate(DataPointBase):
    pass


class DataPoint(DataPointBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# Response Schemas


class MessageResponse(BaseModel):
    message: str


class HealthResponse(BaseModel):
    status: str
    message: str
    environment: Optional[str] = None
