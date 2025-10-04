#!/usr/bin/env python3
"""
Test SQS message receiving and processing
"""

import json
from datetime import datetime

import boto3


def receive_and_process_messages():
    """Receive messages from SQS and process them manually"""

    print("🔍 Checking for messages in SQS queues...")

    # SQS client
    sqs = boto3.client(
        'sqs',
        region_name='eu-west-1',
        aws_access_key_id='AKIAYCG3NTKVNJBJVWIH',
        aws_secret_access_key='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'
    )

    # Queue URL
    queue_url = ("https://sqs.eu-west-1.amazonaws.com/"
                 "554510949034/wipsie-default")

    try:
        # Receive messages
        response = sqs.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=5,
            MessageAttributeNames=['All']
        )

        messages = response.get('Messages', [])

        if not messages:
            print("📭 No messages found in queue")
            return

        print(f"📬 Found {len(messages)} message(s) to process:")

        for i, message in enumerate(messages, 1):
            print(f"\n{'='*50}")
            print(f"📨 Processing Message {i}")
            print(f"{'='*50}")

            # Parse message
            try:
                body = json.loads(message['Body'])
                print(f"🆔 Message ID: {message['MessageId']}")
                print(f"📝 Content: {body.get('message', 'No message')}")
                print(f"🔖 Task Type: {body.get('task_type', 'Unknown')}")
                print(f"🕒 Timestamp: {body.get('timestamp', 'No timestamp')}")

                # Show attributes
                attrs = message.get('MessageAttributes', {})
                if attrs:
                    print(f"🏷️  Attributes:")
                    for key, value in attrs.items():
                        print(f"   {key}: {value.get('StringValue', 'N/A')}")

                # Simulate processing
                print(f"⚙️  Processing...")
                process_result = {
                    'processed_at': datetime.now().isoformat(),
                    'status': 'completed',
                    'processor': 'manual_processor'
                }
                print(f"✅ Processing result: {process_result}")

                # Optional: Delete message after processing
                should_delete = input(
                    f"\n🗑️  Delete this message? (y/N): ").lower()
                if should_delete == 'y':
                    sqs.delete_message(
                        QueueUrl=queue_url,
                        ReceiptHandle=message['ReceiptHandle']
                    )
                    print("🗑️  Message deleted from queue")
                else:
                    print("📌 Message kept in queue")

            except json.JSONDecodeError as e:
                print(f"❌ Failed to parse message body: {e}")
                print(f"Raw body: {message['Body']}")

    except Exception as e:
        print(f"❌ Error receiving messages: {e}")


def queue_stats():
    """Show queue statistics"""

    print("\n📊 Queue Statistics")
    print("=" * 30)

    sqs = boto3.client(
        'sqs',
        region_name='eu-west-1',
        aws_access_key_id='AKIAYCG3NTKVNJBJVWIH',
        aws_secret_access_key='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'
    )

    queues = [
        ('Default', 'wipsie-default'),
        ('Data Polling', 'wipsie-data-polling'),
        ('Task Processing', 'wipsie-task-processing'),
        ('Notifications', 'wipsie-notifications')
    ]

    for name, queue_name in queues:
        queue_url = (f"https://sqs.eu-west-1.amazonaws.com/"
                     f"554510949034/{queue_name}")

        try:
            attrs = sqs.get_queue_attributes(
                QueueUrl=queue_url,
                AttributeNames=['ApproximateNumberOfMessages']
            )

            message_count = attrs['Attributes'].get(
                'ApproximateNumberOfMessages', '0'
            )
            print(f"📮 {name}: {message_count} messages")

        except Exception as e:
            print(f"❌ {name}: Error getting stats - {e}")


if __name__ == "__main__":
    print("🚀 SQS Message Processor")
    print("=" * 40)

    # Show queue stats first
    queue_stats()

    # Process messages
    receive_and_process_messages()

    print("\n🎯 Processing complete!")
