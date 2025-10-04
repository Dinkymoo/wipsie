#!/usr/bin/env python3
"""
Send a test message to SQS queue - FIXED VERSION
"""

import json
import os
import uuid
from datetime import datetime

import boto3
from dotenv import load_dotenv

# Load environment variables
load_dotenv()


def send_message_to_sqs():
    """Send a test message directly to SQS"""

    print("📤 Sending message to SQS...")

    # SQS client using environment variables
    sqs = boto3.client(
        "sqs",
        region_name="eu-west-1",
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    )

    # Message content
    message_body = {
        "id": str(uuid.uuid4()),
        "task_id": "test-123",
        "task_type": "data_polling",
        "message": "Hello from Wipsie! 🚀",
        "timestamp": datetime.now().isoformat(),
        "source": "manual_test_script",
        "data": {
            "source": "manual_test",
            "priority": "high",
            "description": "Test message via direct SQS integration",
        },
    }

    # Queue URL
    base_url = "https://sqs.eu-west-1.amazonaws.com/554510949034"
    queue_url = f"{base_url}/wipsie-default"

    try:
        # Send the message
        response = sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(message_body),
            MessageAttributes={
                "source": {
                    "StringValue": "direct_script",
                    "DataType": "String",
                },
                "message_type": {"StringValue": "test", "DataType": "String"},
                "priority": {"StringValue": "high", "DataType": "String"},
            },
        )

        print("✅ Message sent successfully!")
        print(f"📨 Message ID: {response['MessageId']}")

        # Safely handle optional response fields
        if "MD5OfBody" in response:
            print(f"🔒 MD5 of Body: {response['MD5OfBody']}")
        if "MD5OfMessageAttributes" in response:
            print(
                f"🔐 MD5 of Attributes: {response['MD5OfMessageAttributes']}"
            )

        print(f"📍 Queue: {queue_url}")
        print(f"📝 Message Content: {message_body['message']}")
        print(f"🆔 Task ID: {message_body['task_id']}")

        return response["MessageId"]

    except Exception as e:
        print(f"❌ Error sending message: {e}")
        return None


def check_queue_messages():
    """Check messages in the queue"""

    print("\n🔍 Checking queue for messages...")

    sqs = boto3.client(
        "sqs",
        region_name="eu-west-1",
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    )

    base_url = "https://sqs.eu-west-1.amazonaws.com/554510949034"
    queue_url = f"{base_url}/wipsie-default"

    try:
        # Receive messages
        response = sqs.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=5,
            WaitTimeSeconds=2,
            MessageAttributeNames=["All"],
        )

        messages = response.get("Messages", [])

        if messages:
            print(f"📬 Found {len(messages)} message(s):")
            for i, msg in enumerate(messages, 1):
                print(f"\n📨 Message {i}:")
                print(f"   ID: {msg['MessageId']}")
                body = json.loads(msg["Body"])
                print(f"   Content: {body.get('message', 'No message field')}")
                print(f"   Task ID: {body.get('task_id', 'No task ID')}")
                print(f"   Timestamp: {body.get('timestamp', 'No timestamp')}")

                # Show attributes
                attrs = msg.get("MessageAttributes", {})
                if attrs:
                    print(f"   Attributes: {attrs}")
        else:
            print("📭 No messages in queue")

    except Exception as e:
        print(f"❌ Error checking queue: {e}")


if __name__ == "__main__":
    print("🚀 SQS Message Test Script")
    print("=" * 40)

    # Send a message
    message_id = send_message_to_sqs()

    if message_id:
        print(f"\n✨ Success! Message sent with ID: {message_id}")

        # Check queue for messages
        check_queue_messages()
    else:
        print("\n❌ Failed to send message")
