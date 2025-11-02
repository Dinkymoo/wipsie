#!/usr/bin/env python3
"""
Test SES Integration
Verify that our SES service works correctly
"""

import os
import sys
from pathlib import Path

# Add the backend directory to Python path
backend_path = Path(__file__).parent.parent / "backend"
sys.path.insert(0, str(backend_path))

from core.config import settings  # noqa: E402

# Now import after path is set
from services.aws.ses.service import SESService  # noqa: E402


def test_ses_configuration():
    """Test SES configuration and setup"""
    print("🔧 Testing SES Configuration...")

    # Check required environment variables
    required_vars = [
        "AWS_ACCESS_KEY_ID",
        "AWS_SECRET_ACCESS_KEY",
        "AWS_REGION",
    ]
    for var in required_vars:
        value = os.getenv(var)
        if value:
            print(f"✅ {var}: {'*' * (len(value) - 4) + value[-4:]}")
        else:
            print(f"❌ {var}: Not set")

    print(f"📍 AWS Region: {settings.AWS_REGION}")
    print(f"📧 From Email: {settings.SES_FROM_EMAIL}")
    print()


def test_simple_email():
    """Test sending a simple email"""
    print("📧 Testing Simple Email...")

    try:
        ses_service = SESService()

        # Test email data
        result = ses_service.send_email(
            to_emails=["test@example.com"],
            subject="🧪 SES Integration Test",
            body_text="This is a test email from the Wipsie SES integration!",
            body_html="""
            <html>
                <body>
                    <h2>🧪 SES Integration Test</h2>
                    <p>This is a test email from the
                    <strong>Wipsie SES integration</strong>!</p>
                    <p>If you received this, the integration
                    is working correctly! 🎉</p>
                </body>
            </html>
            """,
        )

        print("✅ Email sent successfully!")
        print(f"📧 Message ID: {result['message_id']}")
        print(f"📬 Response Metadata: {result['response_metadata']}")
        return True

    except Exception as e:
        print(f"❌ Failed to send simple email: {e}")
        return False


def test_notification_email():
    """Test sending a notification email"""
    print("\n🔔 Testing Notification Email...")

    try:
        ses_service = SESService()

        result = ses_service.send_notification_email(
            recipient="test@example.com",
            notification_type="system_alert",
            title="Test System Alert",
            content="This is a test notification from the Wipsie system.",
            priority="high",
        )

        print("✅ Notification email sent successfully!")
        print(f"📧 Message ID: {result['message_id']}")
        return True

    except Exception as e:
        print(f"❌ Failed to send notification email: {e}")
        return False


def test_task_completion_email():
    """Test sending a task completion email"""
    print("\n🎯 Testing Task Completion Email...")

    try:
        ses_service = SESService()

        result = ses_service.send_task_completion_email(
            recipient="test@example.com",
            task_id="test_task_12345",
            task_type="data_processing",
            status="completed",
            details={
                "duration": "2 minutes",
                "records_processed": 1000,
                "output_file": "data_export_2024.csv",
            },
        )

        print("✅ Task completion email sent successfully!")
        print(f"📧 Message ID: {result['message_id']}")
        return True

    except Exception as e:
        print(f"❌ Failed to send task completion email: {e}")
        return False


def verify_email_addresses():
    """Show information about email verification"""
    print("\n📋 Email Verification Information:")
    print("=" * 50)
    print("Before sending emails, you need to verify email addresses in SES:")
    print("1. Go to AWS SES Console")
    print("2. Navigate to 'Verified identities'")
    print("3. Add and verify your email addresses")
    print("4. Update the test email addresses in this script")
    print("=" * 50)


def main():
    """Run all SES integration tests"""
    print("🚀 Starting SES Integration Tests")
    print("=" * 50)

    # Test configuration
    test_ses_configuration()

    # Show verification info
    verify_email_addresses()

    # Ask user if they want to proceed with actual email tests
    response = (
        input("\n❓ Do you want to run actual email tests? (y/n): ")
        .lower()
        .strip()
    )

    if response != "y":
        print("⏭️  Skipping email tests. Update email addresses and run again.")
        return

    print("\n🧪 Running Email Tests...")
    print("-" * 30)

    # Run tests
    tests_passed = 0
    total_tests = 3

    if test_simple_email():
        tests_passed += 1

    if test_notification_email():
        tests_passed += 1

    if test_task_completion_email():
        tests_passed += 1

    # Summary
    print(f"\n📊 Test Results: {tests_passed}/{total_tests} passed")

    if tests_passed == total_tests:
        print("🎉 All SES integration tests passed!")
    else:
        print(
            "⚠️  Some tests failed. Check your SES configuration and "
            "email verification."
        )


if __name__ == "__main__":
    main()
