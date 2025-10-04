#!/usr/bin/env python3
"""
Test New Worker Architecture
Test the refactored worker system
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


def test_worker_imports():
    """Test that all worker modules can be imported"""
    print("🧪 Testing Worker Imports...")

    try:
        from backend.workers import celery_app
        print("✅ Celery app imported successfully")

        from backend.workers.tasks import data_processing
        print("✅ Data processing tasks imported")

        from backend.workers.tasks import general
        print("✅ General tasks imported")

        from backend.workers.tasks import email
        print("✅ Email tasks imported")

        from backend.workers.tasks import notifications
        print("✅ Notification tasks imported")

        return True

    except ImportError as e:
        print(f"❌ Import failed: {e}")
        return False


def test_task_registration():
    """Test that tasks are properly registered"""
    print("\n📋 Testing Task Registration...")

    try:
        from backend.workers import celery_app

        # Get registered tasks
        registered_tasks = list(celery_app.tasks.keys())

        expected_tasks = [
            'backend.workers.tasks.data_processing.process_default_message',
            'backend.workers.tasks.data_processing.process_data_polling',
            'backend.workers.tasks.data_processing.enrich_data',
            'backend.workers.tasks.general.process_task',
            'backend.workers.tasks.general.health_check',
            'backend.workers.tasks.email.send_notification_email',
            'backend.workers.tasks.email.send_task_completion_email',
            'backend.workers.tasks.notifications.send_notification',
        ]

        print(f"📊 Found {len(registered_tasks)} registered tasks:")
        for task in sorted(registered_tasks):
            if not task.startswith('celery.'):
                print(f"   ✓ {task}")

        # Check if our expected tasks are registered
        missing_tasks = []
        for expected in expected_tasks:
            if expected not in registered_tasks:
                missing_tasks.append(expected)

        if missing_tasks:
            print(f"\n⚠️  Missing tasks: {missing_tasks}")
            return False

        print("\n✅ All expected tasks are registered!")
        return True

    except Exception as e:
        print(f"❌ Task registration test failed: {e}")
        return False


def test_queue_configuration():
    """Test SQS queue configuration"""
    print("\n🔧 Testing Queue Configuration...")

    try:
        from backend.workers import celery_app

        # Check broker configuration
        broker_url = celery_app.conf.broker_url
        print(f"📡 Broker: {broker_url[:20]}...")

        # Check predefined queues
        queues = celery_app.conf.broker_transport_options.get(
            'predefined_queues', {})
        print(f"📬 Configured queues: {list(queues.keys())}")

        # Check task routes
        routes = celery_app.conf.task_routes
        print(f"🛣️  Task routes: {len(routes)} configured")

        return True

    except Exception as e:
        print(f"❌ Queue configuration test failed: {e}")
        return False


def main():
    """Run all tests"""
    print("🚀 Testing New Worker Architecture")
    print("=" * 50)

    tests = [
        test_worker_imports,
        test_task_registration,
        test_queue_configuration
    ]

    passed = 0
    failed = 0

    for test in tests:
        try:
            if test():
                passed += 1
            else:
                failed += 1
        except Exception as e:
            print(f"❌ Test {test.__name__} crashed: {e}")
            failed += 1

    print(f"\n📊 Test Results: {passed} passed, {failed} failed")

    if failed == 0:
        print("🎉 All tests passed! Worker architecture is ready!")
    else:
        print("⚠️  Some tests failed. Check the errors above.")

    return failed == 0


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
