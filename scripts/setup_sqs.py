#!/usr/bin/env python3
"""
Script to create SQS queues for Celery
Run this script to set up the required SQS queues in AWS
"""

import sys

import boto3
from botocore.exceptions import ClientError

from backend.core.config import settings


def create_sqs_queues():
    """Create SQS queues for Celery tasks"""

    # Initialize SQS client
    try:
        sqs = boto3.client(
            'sqs',
            region_name=settings.AWS_REGION,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
        )
    except Exception as e:
        print(f"❌ Failed to initialize SQS client: {e}")
        print("Make sure your AWS credentials are configured.")
        return False

    # List of queues to create
    queues = [
        settings.SQS_DEFAULT_QUEUE,
        settings.SQS_DATA_POLLING_QUEUE,
        settings.SQS_TASK_PROCESSING_QUEUE,
        settings.SQS_NOTIFICATIONS_QUEUE,
    ]

    created_queues = []
    existing_queues = []

    for queue_name in queues:
        try:
            # Try to create the queue
            response = sqs.create_queue(
                QueueName=queue_name,
                Attributes={
                    'VisibilityTimeout': '300',  # 5 minutes
                    'MessageRetentionPeriod': '1209600',  # 14 days
                    'ReceiveMessageWaitTimeSeconds': '20',  # Long polling
                }
            )
            created_queues.append(queue_name)
            print(f"✅ Created queue: {queue_name}")
            print(f"   Queue URL: {response['QueueUrl']}")

        except ClientError as e:
            if e.response['Error']['Code'] == 'QueueAlreadyExists':
                existing_queues.append(queue_name)
                print(f"ℹ️  Queue already exists: {queue_name}")
            else:
                print(f"❌ Failed to create queue {queue_name}: {e}")
                return False

    print("\n🎉 SQS Setup Complete!")
    print(f"✅ Created {len(created_queues)} new queues")
    print(f"ℹ️  Found {len(existing_queues)} existing queues")

    if created_queues:
        print("\nNew queues created:")
        for queue in created_queues:
            print(f"  - {queue}")

    if existing_queues:
        print("\nExisting queues:")
        for queue in existing_queues:
            print(f"  - {queue}")

    print(f"\n📍 AWS Region: {settings.AWS_REGION}")
    print("\n🚀 Your Celery workers can now use SQS!")

    return True


def list_existing_queues():
    """List all existing SQS queues"""
    try:
        sqs = boto3.client(
            'sqs',
            region_name=settings.AWS_REGION,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
        )

        response = sqs.list_queues()
        queues = response.get('QueueUrls', [])

        print(f"\n📋 Existing SQS queues in {settings.AWS_REGION}:")
        if queues:
            for queue_url in queues:
                queue_name = queue_url.split('/')[-1]
                print(f"  - {queue_name}")
                print(f"    URL: {queue_url}")
        else:
            print("  No queues found")

    except Exception as e:
        print(f"❌ Failed to list queues: {e}")


if __name__ == "__main__":
    print("🚀 Setting up SQS queues for Wipsie Celery...")
    print(f"🔑 AWS Region: {settings.AWS_REGION}")
    print("🛡️  Security Reminder: See docs/AWS_SECURITY.md for best practices")

    # Check if AWS credentials are configured
    if not settings.AWS_ACCESS_KEY_ID or not settings.AWS_SECRET_ACCESS_KEY:
        print("❌ AWS credentials not configured!")
        print("Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY")
        print("You can:")
        print("1. Set them in your .env file")
        print("2. Set them as environment variables")
        print("3. Use AWS CLI: aws configure")
        print("🛡️  SECURITY: Never commit credentials to version control!")
        sys.exit(1)

    # List existing queues first
    list_existing_queues()

    # Create new queues
    success = create_sqs_queues()

    if not success:
        sys.exit(1)

    print("\n💡 Next steps:")
    print("1. Your AWS credentials are configured ✅")
    print("2. Start your Celery workers:")
    print("   celery -A backend.core.celery_app worker --loglevel=info")
    print("3. Monitor your queues in AWS Console")
    print("🛡️  Security: Review docs/AWS_SECURITY.md for ongoing practices")
