#!/usr/bin/env python3
"""
Simple SQS message test - with hardcoded credentials for testing
"""

import json
import uuid
from datetime import (
    datetime,
)

import boto3


def send_test_message():
    """Send a test message directly to SQS"""

    print("📤 Sending message to SQS...")

    # SQS client with hardcoded credentials (for testing only)
    sqs = boto3.client(
        "sqs",
        region_name="us-east-1",
        aws_access_key_id="AKIAYCG3NTKVNJBJVWIH",
        aws_secret_access_key="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",
    )

    # Message content
    message_body = {
        "id": str(uuid.uuid4()),
        "task_id": "test-api-" + str(uuid.uuid4())[:8],
        "task_type": "api_test",
        "message": "Hello from FastAPI SQS Integration! 🚀",
        "timestamp": datetime.now().isoformat(),
        "source": "fastapi_test",
        "data": {
            "test_type": "api_integration",
            "priority": "high",
            "description": "Testing SQS via FastAPI service",
        },
    }

    # Queue URL
    queue_url = (
        "https://sqs.us-east-1.amazonaws.com/" "554510949034/wipsie-default"
    )

    try:
        # Send the message
        response = sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(message_body),
            MessageAttributes={
                "source": {
                    "StringValue": "fastapi_test",
                    "DataType": "String",
                },
                "message_type": {
                    "StringValue": "api_test",
                    "DataType": "String",
                },
                "priority": {"StringValue": "high", "DataType": "String"},
            },
        )

        print("✅ Message sent successfully!")
        print(f"📨 Message ID: {response['MessageId']}")
        print(f"📝 Message: {message_body['message']}")
        print(f"🆔 Task ID: {message_body['task_id']}")
        print(f"📍 Queue: {queue_url}")

        return response["MessageId"]

    except Exception as e:
        print(f"❌ Error sending message: {e}")
        import traceback

        traceback.print_exc()
        return None


if __name__ == "__main__":
    print("🚀 Simple SQS Test")
    print("=" * 30)

    message_id = send_test_message()

    if message_id:
        print(f"\n✨ Success! Message ID: {message_id}")
    else:
        print("\n❌ Failed to send message")
