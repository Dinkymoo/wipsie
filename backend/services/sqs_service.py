"""
SQS service for sending and receiving messages
"""

import json
from datetime import (
    datetime,
)
from typing import (
    Any,
    Dict,
    Optional,
)

import boto3

from backend.core.config import (
    settings,
)


class SQSService:
    """Service for interacting with Amazon SQS"""

    def __init__(self):
        self.sqs = boto3.client(
            "sqs",
            region_name=settings.AWS_REGION,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        )

        # Queue URLs
        aws_account = "554510949034"
        region = settings.AWS_REGION
        base_url = f"https://sqs.{region}.amazonaws.com/{aws_account}"
        self.queue_urls = {
            "default": f"{base_url}/wipsie-default",
            "data_polling": f"{base_url}/wipsie-data-polling",
            "task_processing": f"{base_url}/wipsie-task-processing",
            "notifications": f"{base_url}/wipsie-notifications",
        }

    def send_message(
        self,
        queue_name: str,
        message_body: Dict[str, Any],
        message_attributes: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Send a message to the specified SQS queue"""

        if queue_name not in self.queue_urls:
            raise ValueError(f"Unknown queue: {queue_name}")

        queue_url = self.queue_urls[queue_name]

        # Add timestamp to message
        message_body["timestamp"] = datetime.now().isoformat()
        message_body["queue"] = queue_name

        # Prepare message attributes
        attrs = {
            "source": {"StringValue": "fastapi", "DataType": "String"},
            "queue_name": {"StringValue": queue_name, "DataType": "String"},
        }

        if message_attributes:
            for key, value in message_attributes.items():
                attrs[key] = {"StringValue": str(value), "DataType": "String"}

        # Send message
        response = self.sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(message_body),
            MessageAttributes=attrs,
        )

        return {
            "message_id": response["MessageId"],
            "queue": queue_name,
            "queue_url": queue_url,
            "status": "sent",
            "timestamp": message_body["timestamp"],
        }

    def receive_messages(self, queue_name: str, max_messages: int = 5) -> list:
        """Receive messages from the specified queue"""

        if queue_name not in self.queue_urls:
            raise ValueError(f"Unknown queue: {queue_name}")

        queue_url = self.queue_urls[queue_name]

        response = self.sqs.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=max_messages,
            WaitTimeSeconds=2,
            MessageAttributeNames=["All"],
        )

        messages = []
        for msg in response.get("Messages", []):
            messages.append(
                {
                    "message_id": msg["MessageId"],
                    "body": json.loads(msg["Body"]),
                    "attributes": msg.get("MessageAttributes", {}),
                    "receipt_handle": msg["ReceiptHandle"],
                }
            )

        return messages

    def delete_message(self, queue_name: str, receipt_handle: str):
        """Delete a message from the queue"""

        if queue_name not in self.queue_urls:
            raise ValueError(f"Unknown queue: {queue_name}")

        queue_url = self.queue_urls[queue_name]

        self.sqs.delete_message(
            QueueUrl=queue_url, ReceiptHandle=receipt_handle
        )


# Global SQS service instance
sqs_service = SQSService()
