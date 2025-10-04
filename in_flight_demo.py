#!/usr/bin/env python3
"""
Demonstrate SQS In-Flight Message Behavior
"""

import json
import time
from datetime import datetime

import boto3
import requests


def demonstrate_in_flight_behavior():
    """Show exactly when messages become in-flight and visible again"""

    print("🎯 SQS In-Flight Message Demonstration")
    print("=" * 50)

    # SQS client
    sqs = boto3.client(
        'sqs',
        region_name='eu-west-1',
        aws_access_key_id='AKIAYCG3NTKVNJBJVWIH',
        aws_secret_access_key='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'
    )

    queue_url = "https://sqs.eu-west-1.amazonaws.com/554510949034/wipsie-default"

    def check_queue_status():
        """Check current queue message counts"""
        attrs = sqs.get_queue_attributes(
            QueueUrl=queue_url,
            AttributeNames=['ApproximateNumberOfMessages',
                            'ApproximateNumberOfMessagesNotVisible']
        )
        available = int(attrs['Attributes'].get(
            'ApproximateNumberOfMessages', 0))
        in_flight = int(attrs['Attributes'].get(
            'ApproximateNumberOfMessagesNotVisible', 0))
        return available, in_flight

    # 1. Check initial state
    print("\n📊 Step 1: Initial Queue State")
    available, in_flight = check_queue_status()
    print(f"📬 Available messages: {available}")
    print(f"🔄 In-flight messages: {in_flight}")

    # 2. Send a test message if queue is empty
    if available == 0:
        print("\n📤 Step 2: Sending a test message...")
        test_message = {
            "demo": "in_flight_test",
            "message": "Testing in-flight behavior",
            "timestamp": datetime.now().isoformat(),
            "purpose": "Demonstrate visibility timeout"
        }

        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(test_message),
            MessageAttributes={
                'demo_type': {
                    'StringValue': 'in_flight_demo',
                    'DataType': 'String'
                }
            }
        )
        print("✅ Test message sent")

        # Wait a moment for the message to be available
        time.sleep(2)

    # 3. Check state after sending
    print("\n📊 Step 3: After Sending Message")
    available, in_flight = check_queue_status()
    print(f"📬 Available messages: {available}")
    print(f"🔄 In-flight messages: {in_flight}")

    # 4. Receive a message (this makes it in-flight)
    print("\n🎯 Step 4: Receiving Message (Goes In-Flight)")
    print("Calling receive_message()...")

    receive_response = sqs.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=1,
        WaitTimeSeconds=2,
        MessageAttributeNames=['All']
    )

    messages = receive_response.get('Messages', [])

    if messages:
        message = messages[0]
        receipt_handle = message['ReceiptHandle']

        print(f"✅ Received message: {message['MessageId']}")
        print(f"📝 Body: {json.loads(message['Body']).get('message', 'N/A')}")

        # 5. Check state immediately after receiving
        print("\n📊 Step 5: Immediately After Receiving")
        available, in_flight = check_queue_status()
        print(f"📬 Available messages: {available}")
        print(f"🔄 In-flight messages: {in_flight}")
        print("\n💡 Notice: Message is now IN-FLIGHT!")
        print("   • The message is invisible to other consumers")
        print("   • It will stay in-flight for 30 seconds (visibility timeout)")
        print("   • During this time, no other worker can receive it")

        # 6. Simulate processing time
        print(f"\n⏱️  Step 6: Processing Message (In-Flight Duration)")
        for i in range(10):
            print(f"   Processing... {i+1}/10 seconds")
            time.sleep(1)
            if i == 4:  # Check status halfway through
                available, in_flight = check_queue_status()
                print(
                    f"   📊 Status check: Available={available}, In-Flight={in_flight}")

        # 7. Decision point - delete or let it become visible again
        print(f"\n🤔 Step 7: Processing Decision")
        choice = input(
            "Delete message (success) or let it become visible again? (d/v): ").lower()

        if choice == 'd':
            # Delete the message (successful processing)
            print("\n✅ Step 8a: Deleting Message (Successful Processing)")
            sqs.delete_message(
                QueueUrl=queue_url,
                ReceiptHandle=receipt_handle
            )
            print("🗑️  Message deleted - removed from queue permanently")

        else:
            # Let it become visible again
            print("\n🔄 Step 8b: Letting Message Become Visible Again")
            print("   • Not deleting the message")
            print("   • It will become available again after visibility timeout")
            print("   • Another worker (or the same worker) can receive it again")

        # 9. Final status check
        print(f"\n📊 Step 9: Final Queue State")
        time.sleep(2)  # Wait a moment for status to update
        available, in_flight = check_queue_status()
        print(f"📬 Available messages: {available}")
        print(f"🔄 In-flight messages: {in_flight}")

    else:
        print("❌ No messages available to demonstrate")

    print(f"\n🎓 Key Learning Points:")
    print("1. Messages go IN-FLIGHT the instant receive_message() succeeds")
    print("2. In-flight messages are invisible to other consumers")
    print("3. Visibility timeout (30s) determines how long they stay in-flight")
    print("4. Delete successful messages to prevent reprocessing")
    print("5. Failed processing = message becomes available again automatically")


def show_visibility_timeout_scenarios():
    """Show different scenarios for visibility timeout"""

    print(f"\n🎭 Visibility Timeout Scenarios:")
    print("=" * 40)

    scenarios = [
        {
            "name": "✅ Successful Processing",
            "description": "Worker receives → processes quickly → deletes message",
            "timeline": "0s: receive → 5s: process → 10s: delete → DONE",
            "result": "Message permanently removed from queue"
        },
        {
            "name": "❌ Processing Failure",
            "description": "Worker receives → fails to process → doesn't delete",
            "timeline": "0s: receive → 15s: error → 30s: visible again",
            "result": "Message available for retry by same/different worker"
        },
        {
            "name": "⏰ Slow Processing",
            "description": "Worker receives → processing takes longer than 30s",
            "timeline": "0s: receive → 30s: still processing → visible again!",
            "result": "Another worker might receive same message (duplicate processing)"
        },
        {
            "name": "💥 Worker Crash",
            "description": "Worker receives → crashes during processing",
            "timeline": "0s: receive → 10s: crash → 30s: visible again",
            "result": "Message automatically recovers for retry"
        }
    ]

    for i, scenario in enumerate(scenarios, 1):
        print(f"\n{i}. {scenario['name']}")
        print(f"   📝 {scenario['description']}")
        print(f"   ⏱️  {scenario['timeline']}")
        print(f"   🎯 {scenario['result']}")


if __name__ == "__main__":
    demonstrate_in_flight_behavior()
    show_visibility_timeout_scenarios()

    print(f"\n🚀 Want to see this in action?")
    print("Run this script and follow the prompts!")
