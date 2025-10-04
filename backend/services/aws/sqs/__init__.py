"""
SQS service module
Amazon Simple Queue Service integration
"""

from .exceptions import (
    QueueNotFoundError,
    SQSError,
)
from .models import (
    QueueInfo,
    SQSMessage,
)
from .service import (
    SQSService,
)

__all__ = [
    "SQSService",
    "SQSMessage",
    "QueueInfo",
    "SQSError",
    "QueueNotFoundError",
]
