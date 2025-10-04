"""
Wipsie Workers Package
Background task processing with Celery + SQS + SES
"""

from .celery_app import app as celery_app

# Import tasks to register them with Celery
from .tasks import data_processing  # noqa: F401
from .tasks import email  # noqa: F401
from .tasks import general  # noqa: F401
from .tasks import notifications  # noqa: F401

__all__ = ["celery_app"]
