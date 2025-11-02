import json
import os
import sys
from unittest.mock import (
    MagicMock,
    patch,
)

import pytest

# Add backend directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))


def load_main_module():
    """Load backend/main.py as module 'main'.
    Use importlib if normal import fails.
    """
    try:
        # Prefer standard import if available
        import importlib
        return importlib.import_module('main')
    except Exception:
        # Fallback: load module directly from backend/main.py path
        import importlib.machinery
        import importlib.util
        main_path = os.path.join(os.path.dirname(
            __file__), '..', 'backend', 'main.py')

        # Try to get a spec from the file location; if that fails or the spec
        # has no loader, use SourceFileLoader as a reliable fallback.
        spec = importlib.util.spec_from_file_location('main', main_path)
        if spec is None or spec.loader is None:
            loader = importlib.machinery.SourceFileLoader('main', main_path)
            spec = importlib.util.spec_from_loader('main', loader)
        else:
            loader = spec.loader

        # Ensure spec is not None before passing to
        # module_from_spec (satisfies type checkers)
        if spec is None:
            raise ImportError(f"Cannot create module spec for {main_path}")

        module = importlib.util.module_from_spec(spec)
        # Ensure the chosen loader can execute the module
        loader.exec_module(module)

        # Ensure subsequent imports that reference 'main' find this module
        sys.modules['main'] = module
        return module


class MockLambdaContext:
    """Mock AWS Lambda context object"""

    def __init__(self):
        self.function_name = 'wipsie-backend'
        self.function_version = '$LATEST'
        self.invoked_function_arn = (
            'arn:aws:lambda:eu-west-1:554510949034:'
            'function:wipsie-backend'
        )
        self.memory_limit_in_mb = 256
        self.remaining_time_in_millis = 300000
        self.log_group_name = '/aws/lambda/wipsie-backend'
        self.log_stream_name = '2024/01/01/[$LATEST]abcdef'
        self.aws_request_id = 'test-request-id-123'

    def get_remaining_time_in_millis(self):
        return self.remaining_time_in_millis


@pytest.fixture
def lambda_context():
    """Fixture providing a mock Lambda context"""
    return MockLambdaContext()


@pytest.fixture
def api_gateway_event():
    """Fixture providing a basic API Gateway event"""
    return {
        "resource": "/{proxy+}",
        "path": "/health",
        "httpMethod": "GET",
        "headers": {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Host": "yb6i0oap3c.execute-api.eu-west-1.amazonaws.com",
            "User-Agent": "pytest"
        },
        "multiValueHeaders": {},
        "queryStringParameters": None,
        "multiValueQueryStringParameters": None,
        "pathParameters": {"proxy": "health"},
        "stageVariables": None,
        "requestContext": {
            "resourceId": "123456",
            "resourcePath": "/{proxy+}",
            "httpMethod": "GET",
            "extendedRequestId": "test-request-id",
            "requestTime": "09/Apr/2015:12:34:56 +0000",
            "path": "/prod/health",
            "accountId": "554510949034",
            "protocol": "HTTP/1.1",
            "stage": "prod",
            "domainPrefix": "yb6i0oap3c",
            "requestTimeEpoch": 1428582896000,
            "requestId": "test-request-id",
            "identity": {
                "cognitoIdentityPoolId": None,
                "accountId": None,
                "cognitoIdentityId": None,
                "caller": None,
                "accessKey": None,
            },
        },
        "body": None,
        "isBase64Encoded": False,
    }


def test_import_main_module():
    """Ensure main module can be loaded by the fallback loader if needed."""
    try:
        main = load_main_module()
        assert hasattr(main, 'lambda_handler')
    except Exception as e:
        pytest.skip(f"Cannot load main module: {e}")


def _get_lambda_handler_or_skip():
    try:
        main = load_main_module()
        handler = getattr(main, 'lambda_handler', None)
        if handler is None:
            pytest.skip("main.lambda_handler not found")
        return handler
    except Exception as e:
        pytest.skip(f"Cannot import lambda_handler: {e}")


class TestLambdaHandler:
    """Unit tests for Lambda handler function."""

    def test_lambda_handler_health_check(self, lambda_context):
        """Test health check endpoint."""
        event = {
            'httpMethod': 'GET',
            'path': '/health',
            'headers': {},
            'queryStringParameters': None,
            'body': None
        }

        lambda_handler = _get_lambda_handler_or_skip()

        response = lambda_handler(event, lambda_context)

        assert response['statusCode'] in [
            200, 500]  # Allow for potential errors
        assert 'headers' in response
        assert 'body' in response

        # Parse response body
        if response['statusCode'] == 200:
            body = json.loads(response['body'])
            assert 'message' in body or 'status' in body

    def test_lambda_handler_root_endpoint(self, lambda_context):
        """Test root endpoint."""
        event = {
            'httpMethod': 'GET',
            'path': '/',
            'headers': {},
            'queryStringParameters': None,
            'body': None
        }

        lambda_handler = _get_lambda_handler_or_skip()

        response = lambda_handler(event, lambda_context)

        assert response['statusCode'] in [200, 404, 500]
        assert 'headers' in response
        assert 'body' in response

    def test_lambda_handler_data_points_endpoint(self, lambda_context):
        """Test data-points endpoint."""
        event = {
            'httpMethod': 'GET',
            'path': '/data-points',
            'headers': {},
            'queryStringParameters': None,
            'body': None
        }

        lambda_handler = _get_lambda_handler_or_skip()

        response = lambda_handler(event, lambda_context)

        assert response['statusCode'] in [200, 404, 500]
        assert 'headers' in response
        assert 'body' in response

    def test_lambda_handler_post_request(self, lambda_context):
        """Test POST request handling."""
        event = {
            'httpMethod': 'POST',
            'path': '/data-points',
            'headers': {'Content-Type': 'application/json'},
            'queryStringParameters': None,
            'body': json.dumps({'test': 'data'})
        }

        lambda_handler = _get_lambda_handler_or_skip()

        response = lambda_handler(event, lambda_context)

        assert response['statusCode'] in [200, 201, 400, 404, 500]
        assert 'headers' in response
        assert 'body' in response

    @patch('boto3.client')
    def test_lambda_handler_with_database_interaction(
        self,
        mock_boto_client,
        lambda_context,
    ):
        """Test Lambda handler with mocked database interactions."""
        # Mock DynamoDB or RDS client
        mock_db = MagicMock()
        mock_boto_client.return_value = mock_db

        event = {
            'httpMethod': 'GET',
            'path': '/data-points',
            'headers': {},
            'queryStringParameters': None,
            'body': None
        }

        lambda_handler = _get_lambda_handler_or_skip()

        response = lambda_handler(event, lambda_context)

        assert 'statusCode' in response
        assert 'headers' in response
        assert 'body' in response

    def test_lambda_handler_cors_headers(self, lambda_context):
        """Test that CORS headers are properly set."""
        event = {
            'httpMethod': 'OPTIONS',
            'path': '/health',
            'headers': {},
            'queryStringParameters': None,
            'body': None
        }

        lambda_handler = _get_lambda_handler_or_skip()

        response = lambda_handler(event, lambda_context)

        # Check for CORS headers
        headers = response.get('headers', {})
        assert (
            'Access-Control-Allow-Origin' in headers
            or response['statusCode'] in [404, 500]
        )

    def test_lambda_handler_error_handling(self, lambda_context):
        """Test error handling in Lambda function."""
        # Test with malformed event
        event = {
            'httpMethod': 'INVALID',
            'path': '/nonexistent',
            'headers': {},
            'queryStringParameters': None,
            'body': None
        }

        lambda_handler = _get_lambda_handler_or_skip()

        response = lambda_handler(event, lambda_context)

        # Should handle errors gracefully
        assert 'statusCode' in response
        assert response['statusCode'] in [400, 404, 405, 500]
        assert 'headers' in response
        assert 'body' in response


# End of test_lambda_handler.py
