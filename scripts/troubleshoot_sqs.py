#!/usr/bin/env python3
"""
SQS Troubleshooting Script
"""

import os

import boto3
from dotenv import load_dotenv


def main():
    load_dotenv()

    print("=" * 50)
    print("🔍 SQS TROUBLESHOOTING")
    print("=" * 50)

    # Check environment variables
    aws_region = os.getenv("AWS_REGION")
    aws_access_key = os.getenv("AWS_ACCESS_KEY_ID")
    aws_secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")

    print(f"AWS_REGION: {aws_region}")
    print(f"AWS_ACCESS_KEY_ID: {aws_access_key}")
    print(
        f"AWS_SECRET_ACCESS_KEY: {'*' * len(aws_secret_key) if aws_secret_key else 'NOT SET'}"
    )
    print()

    if not all([aws_region, aws_access_key, aws_secret_key]):
        print("❌ Missing AWS credentials!")
        return

    try:
        # Test STS (AWS Security Token Service)
        print("🔐 Testing AWS credentials...")
        sts = boto3.client(
            "sts",
            region_name=aws_region,
            aws_access_key_id=aws_access_key,
            aws_secret_access_key=aws_secret_key,
        )
        identity = sts.get_caller_identity()
        print(f"✅ AWS Account: {identity['Account']}")
        print(f"✅ User ARN: {identity['Arn']}")
        print()

        # Test SQS
        print("📋 Checking SQS queues...")
        sqs = boto3.client(
            "sqs",
            region_name=aws_region,
            aws_access_key_id=aws_access_key,
            aws_secret_access_key=aws_secret_key,
        )

        response = sqs.list_queues()
        queues = response.get("QueueUrls", [])

        if queues:
            print(f"✅ Found {len(queues)} queue(s):")
            for queue_url in queues:
                queue_name = queue_url.split("/")[-1]
                print(f"  - {queue_name}")
                print(f"    URL: {queue_url}")
        else:
            print("❌ No queues found!")
            print("🔧 Creating queues now...")

            # Create queues
            queue_names = [
                "wipsie-default",
                "wipsie-data-polling",
                "wipsie-task-processing",
                "wipsie-notifications",
            ]
            for queue_name in queue_names:
                try:
                    result = sqs.create_queue(
                        QueueName=queue_name,
                        Attributes={
                            "VisibilityTimeout": "300",
                            "MessageRetentionPeriod": "1209600",
                            "ReceiveMessageWaitTimeSeconds": "20",
                        },
                    )
                    print(f"✅ Created: {queue_name}")
                    print(f"   URL: {result['QueueUrl']}")
                except Exception as e:
                    print(f"❌ Failed to create {queue_name}: {e}")

            print("\n🔄 Listing queues again...")
            response = sqs.list_queues()
            queues = response.get("QueueUrls", [])
            print(f"📋 Total queues now: {len(queues)}")

    except Exception as e:
        print(f"❌ Error: {e}")
        print("\n🛠️  Troubleshooting tips:")
        print("1. Check if your AWS credentials are correct")
        print("2. Verify you're looking in the correct AWS region (us-east-1)")
        print("3. Ensure your IAM user has SQS permissions")
        print("4. Check AWS Console: https://console.aws.amazon.com/sqs/")


if __name__ == "__main__":
    main()
