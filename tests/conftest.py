import os
import sys

import pytest

# Add backend directory to path for imports
backend_dir = os.path.join(os.path.dirname(__file__), '..', 'backend')
if os.path.isdir(backend_dir):
    sys.path.insert(0, os.path.abspath(backend_dir))


@pytest.fixture(scope='session')
def setup_database():
    # Code to set up the database connection
    yield
    # Code to tear down the database connection


@pytest.fixture
def sample_data():
    return {"key": "value"}


@pytest.fixture
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'
    os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'


@pytest.fixture
def lambda_context():
    """Mock Lambda context for testing."""
    class MockContext:
        def __init__(self):
            self.function_name = "test_function"
            self.function_version = "$LATEST"
            self.invoked_function_arn = (
                "arn:aws:lambda:us-east-1:123456789012:"
                "function:test_function"
            )
            self.memory_limit_in_mb = 128
            self.remaining_time_in_millis = lambda: 30000
            self.aws_request_id = "test-request-id"
            self.log_group_name = "/aws/lambda/test_function"
            self.log_stream_name = "test_stream"

    return MockContext()
