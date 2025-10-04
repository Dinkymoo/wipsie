"""
SQS data models and schemas
"""

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
)


class SQSMessage(BaseModel):
    """Standard SQS message format"""

    id: str
    timestamp: str
    source: str
    task_type: str
    message: str
    queue: str
    data: Dict[str, Any]
    priority: Optional[str] = "medium"
    retry_count: Optional[int] = 0
    correlation_id: Optional[str] = None


class QueueInfo(BaseModel):
    """Queue information and statistics"""

    queue_name: str
    queue_url: str
    messages_available: int
    messages_in_flight: int
    visibility_timeout_seconds: int
    message_retention_days: int
    has_dead_letter_queue: bool
    created_timestamp: str
    last_modified_timestamp: str


class MessageResponse(BaseModel):
    """Response model for sent messages"""

    message_id: str
    queue: str
    status: str
    timestamp: str
    queue_url: Optional[str] = None
