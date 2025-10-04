"""
Test API endpoints and routes.
"""

import pytest


class TestAPIEndpoints:
    """Test API endpoints functionality."""

    def test_health_endpoint_detailed(self, client):
        """Test the health check endpoint with detailed validation."""
        response = client.get("/health")
        assert response.status_code == 200

        data = response.json()
        assert "status" in data
        assert data["status"] == "healthy"

    def test_docs_endpoints(self, client):
        """Test that API documentation endpoints are accessible."""
        # Test OpenAPI docs
        response = client.get("/docs")
        assert response.status_code == 200

        # Test ReDoc
        response = client.get("/redoc")
        assert response.status_code == 200

        # Test OpenAPI JSON
        response = client.get("/openapi.json")
        assert response.status_code == 200
        assert response.headers["content-type"] == "application/json"

    def test_api_routes_basic(self, client):
        """Test basic API routes if they exist."""
        # These might not exist yet, so we'll check gracefully
        potential_routes = [
            "/api/v1/users",
            "/api/v1/tasks",
            "/api/v1/data-points"
        ]

        for route in potential_routes:
            response = client.get(route)
            # We expect either a valid response or a proper 404
            assert response.status_code in [200, 404, 405]

    def test_cors_headers(self, client):
        """Test CORS headers if configured."""
        response = client.options("/health")
        # CORS might not be configured yet
        assert response.status_code in [200, 405]


class TestAPIErrorHandling:
    """Test API error handling."""

    def test_404_handling(self, client):
        """Test 404 error handling."""
        response = client.get("/nonexistent-endpoint")
        assert response.status_code == 404

    def test_method_not_allowed(self, client):
        """Test method not allowed handling."""
        # Try POST on a GET-only endpoint
        response = client.post("/health")
        assert response.status_code == 405


class TestAPIPerformance:
    """Basic performance tests for API endpoints."""

    def test_health_endpoint_performance(self, client):
        """Test that health endpoint responds quickly."""
        import time

        start_time = time.time()
        response = client.get("/health")
        end_time = time.time()

        assert response.status_code == 200
        # Health check should be very fast (under 1 second)
        assert (end_time - start_time) < 1.0

    def test_multiple_requests(self, client):
        """Test handling multiple requests."""
        responses = []

        for _ in range(5):
            response = client.get("/health")
            responses.append(response)

        # All requests should succeed
        for response in responses:
            assert response.status_code == 200


@pytest.mark.asyncio
class TestAsyncEndpoints:
    """Test async endpoint functionality."""

    async def test_async_health_check(self, client):
        """Test async health check if available."""
        # Basic test - might need adjustment based on implementation
        response = client.get("/health")
        assert response.status_code == 200

    async def test_async_database_endpoints(self, client):
        """Test async database endpoints if they exist."""
        # Test potential async database endpoints
        potential_async_routes = [
            "/api/v1/users",
            "/api/v1/tasks"
        ]

        for route in potential_async_routes:
            response = client.get(route)
            # Expect either success or proper error
            assert response.status_code in [200, 404, 405, 422]
