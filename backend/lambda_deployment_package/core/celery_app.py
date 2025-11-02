from celery import (
    Celery,
)

from backend.core.config import (
    settings,
)

# Create Celery instance
celery_app = Celery(
    "wipsie",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=["backend.services.tasks"],
)

# Configure Celery for SQS
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    # SQS specific configuration
    broker_url=settings.CELERY_BROKER_URL,
    result_backend=settings.CELERY_RESULT_BACKEND,
    broker_region=settings.AWS_REGION,
    broker_transport_options={
        "region": settings.AWS_REGION,
        "visibility_timeout": 300,  # 5 minutes
        "polling_interval": 1,
        "queue_name_prefix": f"{settings.SQS_QUEUE_PREFIX}-",
        # AWS credentials
        "aws_access_key_id": settings.AWS_ACCESS_KEY_ID,
        "aws_secret_access_key": settings.AWS_SECRET_ACCESS_KEY,
    },
    # Task routing to different SQS queues
    task_routes={
        "backend.services.tasks.poll_data": {
            "queue": settings.SQS_DATA_POLLING_QUEUE
        },
        "backend.services.tasks.process_task": {
            "queue": settings.SQS_TASK_PROCESSING_QUEUE
        },
        "backend.services.tasks.send_notification": {
            "queue": settings.SQS_NOTIFICATIONS_QUEUE
        },
    },
    # Result backend configuration
    result_backend_transport_options=(
        {
            "region": settings.AWS_REGION,
        }
        if settings.CELERY_RESULT_BACKEND.startswith("sqs://")
        else {}
    ),
)
