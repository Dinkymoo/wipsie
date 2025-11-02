#!/usr/bin/env python3
"""
Diagnostic script to understand Mangum event format requirements.
"""
import os
import sys

# Add backend to path
backend_dir = os.path.join(os.path.dirname(__file__), '..', 'backend')
sys.path.insert(0, backend_dir)


def test_mangum_handlers():
    """Test which Mangum handlers are available."""
    try:
        # Import the mangum.handlers module and resolve HANDLERS.
        # If HANDLERS is not defined, collect classes in the module
        # that expose an 'infer' callable.
        import importlib
        import inspect
        handlers_module = importlib.import_module("mangum.handlers")
        HANDLERS = getattr(handlers_module, "HANDLERS", None)
        if not HANDLERS:
            HANDLERS = [
                obj
                for name, obj in vars(handlers_module).items()
                if inspect.isclass(obj)
                and callable(getattr(obj, "infer", None))
            ]
        print("Available Mangum handlers:")
        for handler in HANDLERS:
            print(f"  - {handler.__name__}")
            # Try to get the infer method signature
            try:
                import inspect
                sig = inspect.signature(handler.infer)
                print(f"    infer signature: {sig}")
            except Exception:
                # ignore handlers where signature cannot be retrieved
                pass
        return HANDLERS
    except ImportError as e:
        print(f"Cannot import Mangum handlers: {e}")
        return []


def test_handler_requirements():
    """Test what each handler requires for inference."""
    try:
        import importlib
        import inspect
        handlers_module = importlib.import_module("mangum.handlers")
        HANDLERS = getattr(handlers_module, "HANDLERS", None)
        if not HANDLERS:
            HANDLERS = [
                obj
                for name, obj in vars(handlers_module).items()
                if inspect.isclass(obj)
                and callable(getattr(obj, "infer", None))
            ]

        # Simple test events
        test_events = {
            "minimal": {"httpMethod": "GET", "path": "/health"},
            "api_gateway_v1": {
                "resource": "/{proxy+}",
                "path": "/health",
                "httpMethod": "GET",
                "headers": {},
                "requestContext": {
                    "resourceId": "123456",
                    "resourcePath": "/{proxy+}",
                    "httpMethod": "GET",
                    "requestId": "test-id",
                    "accountId": "123456789012",
                    "apiId": "1234567890",
                    "stage": "test"
                }
            },
            "api_gateway_v2": {
                "version": "2.0",
                "routeKey": "GET /health",
                "rawPath": "/health",
                "headers": {},
                "requestContext": {
                    "http": {
                        "method": "GET",
                        "path": "/health"
                    }
                }
            },
            "alb": {
                "requestContext": {
                    "elb": {
                        "targetGroupArn": (
                            "arn:aws:elasticloadbalancing:us-east-1:"
                            "123456789012:targetgroup/test/abc123"
                        )
                    }
                },
                "httpMethod": "GET",
                "path": "/health"
            }
        }

        class MockContext:
            pass

        context = MockContext()
        config = {}

        print("\nTesting handler inference:")
        for event_name, event in test_events.items():
            print(f"\n{event_name.upper()} event:")
            for handler in HANDLERS:
                try:
                    can_handle = handler.infer(event, context, config)
                    result = "✓" if can_handle else "✗"
                    print(f"  {handler.__name__}: {result}")
                except Exception as e:
                    print(f"  {handler.__name__}: ERROR - {e}")

    except ImportError as e:
        print(f"Cannot test handlers: {e}")


if __name__ == "__main__":
    print("=== Mangum Diagnostic Tool ===\n")
    test_mangum_handlers()
    test_handler_requirements()
    print("\n=== Diagnostic Complete ===")
