#!/usr/bin/env python3
"""
Local Lambda Function Tester
Test your Lambda functions locally before deploying to AWS
"""

import json
import os
import importlib.util
from datetime import datetime


def load_lambda_function(function_path):
    """Load a Lambda function from a file"""
    spec = importlib.util.spec_from_file_location(
        "lambda_function", function_path
    )
    if spec and spec.loader:
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module.lambda_handler
    else:
        raise ImportError(f"Could not load module from {function_path}")


def simulate_lambda_context():
    """Create a mock Lambda context object"""

    class MockContext:
        def __init__(self):
            self.function_name = "test-function"
            self.function_version = "$LATEST"
            self.invoked_function_arn = (
                "arn:aws:lambda:us-east-1:123456789012:function:test-function"
            )
            self.memory_limit_in_mb = 256
            self.remaining_time_in_millis = lambda: 30000
            self.log_group_name = "/aws/lambda/test-function"
            self.log_stream_name = "2025/09/29/[$LATEST]test123"
            self.aws_request_id = "test-request-id"

    return MockContext()


def test_lambda_function(function_name, event):
    """Test a Lambda function locally"""
    print(f"🧪 Testing Lambda function: {function_name}")
    print(f"📝 Event: {json.dumps(event, indent=2)}")
    print("-" * 50)

    try:
        # Load the Lambda function
        function_path = f"./functions/{function_name}.py"
        if not os.path.exists(function_path):
            print(f"❌ Function file not found: {function_path}")
            return None

        lambda_handler = load_lambda_function(function_path)
        context = simulate_lambda_context()

        # Execute the function
        start_time = datetime.now()
        result = lambda_handler(event, context)
        end_time = datetime.now()

        duration = (end_time - start_time).total_seconds() * 1000

        print("✅ Function executed successfully")
        print(f"⏱️  Duration: {duration:.2f}ms")
        print("📤 Response:")
        print(json.dumps(result, indent=2))

        return result

    except Exception as e:
        print(f"❌ Function execution failed: {str(e)}")
        import traceback

        traceback.print_exc()
        return None


def main():
    """Main function to run tests"""
    print("🚀 Wipsie Lambda Local Tester")
    print("=" * 50)

    # Test Data Poller Function
    print("\n🌦️  Testing Data Poller Function")
    test_events = [
        {"source": "weather"},
        {"source": "stocks"},
        {"source": "news"},
        {"source": "unknown"},
    ]

    for event in test_events:
        test_lambda_function("data_poller", event)
        print()

    # Test Task Processor Function
    print("\n⚙️  Testing Task Processor Function")
    task_events = [
        {
            "task_data": {
                "type": "email_notification",
                "id": "task-001",
                "recipient": "test@example.com",
                "subject": "Test Email",
                "message": "This is a test message",
            }
        },
        {
            "task_data": {
                "type": "data_analysis",
                "id": "task-002",
                "dataset_id": "dataset-123",
                "analysis_type": "statistical",
            }
        },
        {
            "task_data": {
                "type": "report_generation",
                "id": "task-003",
                "report_name": "monthly-report",
                "report_type": "summary",
                "date_range": "30d",
            }
        },
        {
            "task_data": {
                "type": "webhook_call",
                "id": "task-004",
                "webhook_url": "https://httpbin.org/post",
                "payload": {"message": "Hello from Lambda!"},
                "method": "POST",
            }
        },
    ]

    for event in task_events:
        test_lambda_function("task_processor", event)
        print()

    print("🎉 All tests completed!")


if __name__ == "__main__":
    main()
