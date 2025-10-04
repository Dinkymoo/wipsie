#!/usr/bin/env python3
"""
AWS SQS Queue Cleanup Tool for US Region
Safely deletes development and test queues in us-east-1 region.
"""

import re
import sys
from typing import List

import boto3


def get_sqs_client():
    """Create SQS client for us-east-1 region"""
    return boto3.client('sqs', region_name='us-east-1')


def list_queues_to_cleanup(sqs_client) -> List[str]:
    """
    List queues that are safe to delete (dev, test, temporary queues)
    """
    try:
        response = sqs_client.list_queues()
        all_queues = response.get('QueueUrls', [])

        # Patterns for queues that are safe to delete
        cleanup_patterns = [
            r'.*-dev(-.*)?$',          # Development queues
            r'.*-test(-.*)?$',         # Test queues
            r'.*-temp(-.*)?$',         # Temporary queues
            r'.*-staging(-.*)?$',      # Staging queues (if not in use)
            r'temp-.*',                # Temporary prefix queues
            r'test-.*',                # Test prefix queues
        ]

        # Patterns for queues to NEVER delete (production)
        protected_patterns = [
            r'.*-prod(-.*)?$',         # Production queues
            r'.*-production(-.*)?$',   # Production queues
            r'prod-.*',                # Production prefix queues
            r'production-.*',          # Production prefix queues
        ]

        queues_to_cleanup = []

        for queue_url in all_queues:
            queue_name = queue_url.split('/')[-1]

            # Skip if it's a protected queue
            is_protected = any(re.match(pattern, queue_name, re.IGNORECASE)
                               for pattern in protected_patterns)
            if is_protected:
                print(f"⚠️  Skipping protected queue: {queue_name}")
                continue

            # Check if it matches cleanup patterns
            should_cleanup = any(re.match(pattern, queue_name, re.IGNORECASE)
                                 for pattern in cleanup_patterns)
            if should_cleanup:
                queues_to_cleanup.append(queue_url)

        return queues_to_cleanup

    except Exception as e:
        print(f"❌ Error listing queues: {e}")
        return []


def delete_queue_safely(sqs_client, queue_url: str) -> bool:
    """
    Delete a queue with safety checks
    """
    try:
        queue_name = queue_url.split('/')[-1]

        # Get queue attributes to check if it's empty
        response = sqs_client.get_queue_attributes(
            QueueUrl=queue_url,
            AttributeNames=[
                'ApproximateNumberOfMessages',
                'ApproximateNumberOfMessagesNotVisible'
            ]
        )

        attrs = response['Attributes']
        visible_messages = int(attrs.get('ApproximateNumberOfMessages', 0))
        invisible_messages = int(
            attrs.get('ApproximateNumberOfMessagesNotVisible', 0)
        )
        total_messages = visible_messages + invisible_messages

        if total_messages > 0:
            print(f"⚠️  Queue {queue_name} has {total_messages} messages. "
                  f"Skipping...")
            return False

        # Delete the queue
        sqs_client.delete_queue(QueueUrl=queue_url)
        print(f"✅ Deleted queue: {queue_name}")
        return True

    except Exception as e:
        queue_name = queue_url.split('/')[-1]
        print(f"❌ Error deleting queue {queue_name}: {e}")
        return False


def main():
    """
    Main cleanup function
    """
    print("🧹 AWS SQS Queue Cleanup Tool (US Region)")
    print("=========================================")

    try:
        sqs_client = get_sqs_client()

        # List queues to cleanup
        print("📋 Finding queues to cleanup...")
        queues_to_cleanup = list_queues_to_cleanup(sqs_client)

        if not queues_to_cleanup:
            print("✨ No queues found that need cleanup!")
            return

        print(f"\n📝 Found {len(queues_to_cleanup)} queues to cleanup:")
        for queue_url in queues_to_cleanup:
            queue_name = queue_url.split('/')[-1]
            print(f"  - {queue_name}")

        # Confirm before deletion
        if '--force' not in sys.argv:
            count = len(queues_to_cleanup)
            prompt = f"\n❓ Delete these {count} queues? (y/N): "
            response = input(prompt)
            if response.lower() != 'y':
                print("❌ Cleanup cancelled.")
                return

        # Delete queues
        print("\n🗑️  Deleting queues...")
        deleted_count = 0
        skipped_count = 0

        for queue_url in queues_to_cleanup:
            if delete_queue_safely(sqs_client, queue_url):
                deleted_count += 1
            else:
                skipped_count += 1

        print("\n✅ Cleanup complete!")
        print(f"   Deleted: {deleted_count} queues")
        print(f"   Skipped: {skipped_count} queues")

    except Exception as e:
        print(f"❌ Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ['-h', '--help']:
        print(__doc__)
        print("\nUsage:")
        print("  python cleanup_us_queues.py          # Interactive mode")
        print("  python cleanup_us_queues.py --force  # Skip confirmation")
        sys.exit(0)

    main()
