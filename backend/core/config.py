import os
from typing import List, Optional, Union

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # API Configuration
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Wipsie Full Stack API"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Database
    DATABASE_URL: str = "postgresql://postgres:postgres@db:5432/wipsie_db"

    # Redis (Optional - keeping for caching if needed)
    REDIS_URL: str = "redis://redis:6379"

    # CORS
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost:4200",
        "http://localhost:3000",
        "http://localhost:8080",
    ]

    # AWS Configuration
    AWS_REGION: str = "eu-west-1"
    AWS_ACCESS_KEY_ID: Optional[str] = None
    AWS_SECRET_ACCESS_KEY: Optional[str] = None

    # SQS Configuration
    SQS_QUEUE_PREFIX: str = "wipsie"
    SQS_DEFAULT_QUEUE: str = f"{SQS_QUEUE_PREFIX}-default"
    SQS_DATA_POLLING_QUEUE: str = f"{SQS_QUEUE_PREFIX}-data-polling"
    SQS_TASK_PROCESSING_QUEUE: str = f"{SQS_QUEUE_PREFIX}-task-processing"
    SQS_NOTIFICATIONS_QUEUE: str = f"{SQS_QUEUE_PREFIX}-notifications"

    # Celery Configuration with SQS
    @property
    def CELERY_BROKER_URL(self) -> str:
        return f"sqs://{self.AWS_ACCESS_KEY_ID}:{self.AWS_SECRET_ACCESS_KEY}@"

    @property
    def CELERY_RESULT_BACKEND(self) -> str:
        # For results, we can use database or S3, using db:// for simplicity
        return f"db+{self.DATABASE_URL}"

    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"


settings = Settings()
