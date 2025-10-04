#!/usr/bin/env python3
"""
SQS Message Retention and Lifecycle Demo
"""

import json
from datetime import datetime, timedelta

import requests


def demonstrate_message_lifecycle():
    """Show how message retention works in practice"""

    base_url = "http://localhost:8000"

    print("🎯 SQS Message Lifecycle Demonstration")
    print("=" * 50)

    # 1. Check current queue status
    print("\n📊 Current Queue Status:")
    response = requests.get(f"{base_url}/sqs/queue-info/default")
    if response.status_code == 200:
        info = response.json()
        retention = info["message_retention"]
        print(f"📬 Messages available: {info['messages_available']}")
        print(f"⏰ Retention period: {retention['human_readable']}")
        print(f"👁️  Visibility timeout: {info['visibility_timeout_seconds']}s")

        # Calculate when messages will expire
        created_timestamp = int(info["created_timestamp"])
        created_date = datetime.fromtimestamp(created_timestamp)
        expiry_date = created_date + timedelta(
            seconds=retention["total_seconds"]
        )

        print(
            f"📅 Queue created: {created_date.strftime('%Y-%m-%d %H:%M:%S')}"
        )
        print(
            f"🗑️  Messages expire: {expiry_date.strftime('%Y-%m-%d %H:%M:%S')}"
        )

        days_until_expiry = (expiry_date - datetime.now()).days
        print(f"⏳ Days until current messages expire: {days_until_expiry}")

    # 2. Send a new message with timestamp
    print("\n📤 Sending a timestamped test message:")
    test_message = {
        "type": "lifecycle_demo",
        "message": "Testing message retention",
        "created_at": datetime.now().isoformat(),
        "expires_at": (datetime.now() + timedelta(days=14)).isoformat(),
        "demo_info": {
            "purpose": "Demonstrate 14-day retention",
            "automatic_cleanup": True,
            "visibility_timeout": "30 seconds",
        },
    }

    response = requests.post(
        f"{base_url}/sqs/send",
        json={
            "queue_name": "default",
            "message": test_message,
            "attributes": {
                "demo": "retention_test",
                "created_timestamp": str(int(datetime.now().timestamp())),
            },
        },
    )

    if response.status_code == 200:
        result = response.json()
        print(f"✅ Message sent with ID: {result['message_id']}")
        print(f"📝 Message: {test_message['message']}")
        print(f"🗓️  Will be deleted on: {test_message['expires_at'][:10]}")

    # 3. Show processing simulation
    print("\n🔄 Message Processing Simulation:")
    print("1. Worker receives message → Message becomes invisible (30s)")
    print("2. Worker processes successfully → Worker deletes message")
    print("3. OR Worker fails → Message becomes visible again after 30s")
    print("4. OR No worker picks up → Message stays until 14-day expiry")

    # 4. Receive a message to demonstrate visibility timeout
    print("\n👀 Demonstrating Visibility Timeout:")
    response = requests.get(f"{base_url}/sqs/receive/default?max_messages=1")
    if response.status_code == 200:
        data = response.json()
        if data["message_count"] > 0:
            message = data["messages"][0]
            print(f"📨 Received message: {message['message_id']}")
            print(f"⏱️  This message is now invisible for 30 seconds")
            print(
                f"🔄 It will become visible again automatically if not deleted"
            )
            print(
                f"🗑️  To delete: DELETE /sqs/message/default?receipt_handle={message['receipt_handle'][:20]}..."
            )
        else:
            print("📭 No messages available (all might be in-flight)")

    print("\n💡 Key Takeaways:")
    print("• Messages automatically expire after 14 days")
    print(
        "• Visibility timeout prevents multiple workers processing same message"
    )
    print("• Long polling (20s) provides efficient real-time processing")
    print("• Failed messages automatically retry (become visible again)")
    print(
        "• Always delete successfully processed messages to avoid reprocessing"
    )


if __name__ == "__main__":
    demonstrate_message_lifecycle()
