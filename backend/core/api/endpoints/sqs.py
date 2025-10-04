"""
API endpoints for SQS messaging
"""

from typing import (
    Any,
    Dict,
    Optional,
)

from fastapi import (
    APIRouter,
    HTTPException,
)
from pydantic import (
    BaseModel,
)

from backend.services.aws.sqs.service import (
    sqs_service,
)

router = APIRouter(prefix="/sqs", tags=["SQS"])


class SendMessageRequest(BaseModel):
    queue_name: str
    message: Dict[str, Any]
    attributes: Optional[Dict[str, Any]] = None


class MessageResponse(BaseModel):
    message_id: str
    queue: str
    status: str
    timestamp: str


@router.post("/send", response_model=MessageResponse)
async def send_message(request: SendMessageRequest):
    """Send a message to an SQS queue"""
    try:
        result = sqs_service.send_message(
            queue_name=request.queue_name,
            message_body=request.message,
            message_attributes=request.attributes,
        )
        return MessageResponse(**result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        error_msg = f"Failed to send message: {str(e)}"
        raise HTTPException(status_code=500, detail=error_msg)


@router.get("/receive/{queue_name}")
async def receive_messages(queue_name: str, max_messages: int = 5):
    """Receive messages from an SQS queue"""
    try:
        messages = sqs_service.receive_messages(queue_name, max_messages)
        return {
            "queue": queue_name,
            "message_count": len(messages),
            "messages": messages,
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        error_msg = f"Failed to receive messages: {str(e)}"
        raise HTTPException(status_code=500, detail=error_msg)


@router.delete("/message/{queue_name}")
async def delete_message(queue_name: str, receipt_handle: str):
    """Delete a message from an SQS queue"""
    try:
        sqs_service.delete_message(queue_name, receipt_handle)
        return {"status": "deleted", "queue": queue_name}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        error_msg = f"Failed to delete message: {str(e)}"
        raise HTTPException(status_code=500, detail=error_msg)


@router.get("/queues")
async def list_queues():
    """List available SQS queues"""
    return {
        "available_queues": list(sqs_service.queue_urls.keys()),
        "region": "eu-west-1",
    }


@router.post("/test-message")
async def send_test_message():
    """Send a test message to the default queue"""
    test_message = {
        "type": "test",
        "message": "Hello from FastAPI!",
        "source": "api_test",
        "data": {
            "test_id": "api-test-001",
            "description": "Testing SQS integration via FastAPI",
        },
    }

    try:
        result = sqs_service.send_message("default", test_message)
        return {
            "status": "success",
            "test_message": test_message,
            "result": result,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Test failed: {str(e)}")


@router.get("/queue-info/{queue_name}")
async def get_queue_info(queue_name: str):
    """Get detailed information about a specific SQS queue"""
    try:
        # Get queue URL
        if queue_name not in sqs_service.queue_urls:
            raise ValueError(f"Unknown queue: {queue_name}")

        queue_url = sqs_service.queue_urls[queue_name]

        # Get queue attributes
        response = sqs_service.sqs.get_queue_attributes(
            QueueUrl=queue_url, AttributeNames=["All"]
        )

        attrs = response["Attributes"]

        # Convert retention period to human readable
        retention_seconds = int(attrs.get("MessageRetentionPeriod", 1209600))
        retention_days = retention_seconds // 86400
        retention_hours = (retention_seconds % 86400) // 3600

        # Convert visibility timeout
        visibility_timeout = int(attrs.get("VisibilityTimeoutSeconds", 30))

        return {
            "queue_name": queue_name,
            "queue_url": queue_url,
            "message_retention": {
                "total_seconds": retention_seconds,
                "days": retention_days,
                "hours": retention_hours,
                "human_readable": f"{retention_days} days, {retention_hours} hours",
            },
            "visibility_timeout_seconds": visibility_timeout,
            "messages_available": int(
                attrs.get("ApproximateNumberOfMessages", 0)
            ),
            "messages_in_flight": int(
                attrs.get("ApproximateNumberOfMessagesNotVisible", 0)
            ),
            "receive_wait_time_seconds": int(
                attrs.get("ReceiveMessageWaitTimeSeconds", 0)
            ),
            "has_dead_letter_queue": "RedrivePolicy" in attrs,
            "created_timestamp": attrs.get("CreatedTimestamp", "Unknown"),
            "last_modified_timestamp": attrs.get(
                "LastModifiedTimestamp", "Unknown"
            ),
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        error_msg = f"Failed to get queue info: {str(e)}"
        raise HTTPException(status_code=500, detail=error_msg)
