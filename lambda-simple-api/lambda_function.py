import json
import logging
import os
import urllib.parse
from datetime import (
    datetime,
)

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    # Log the incoming event for debugging
    logger.info(f"Received event: {json.dumps(event, default=str)}")

    # Extract request details
    http_method = event.get('httpMethod', 'GET')
    path = event.get('path', '/')
    headers = event.get('headers', {})
    query_params = event.get('queryStringParameters') or {}
    body = event.get('body')

    # Parse body if it exists
    request_body = None
    if body:
        try:
            request_body = json.loads(body)
        except:
            request_body = body

    try:
        # Route requests
        if path == '/health':
            return handle_health(http_method)
        elif path == '/':
            return handle_root(http_method)
        elif path == '/data-points':
            return handle_data_points(http_method, request_body)
        elif path == '/users':
            return handle_users(http_method, request_body, query_params)
        elif path == '/courses':
            return handle_courses(http_method, request_body, query_params)
        elif path == '/api/test':
            return handle_test(http_method, query_params, headers)
        else:
            return create_response(404, {
                "error": "Not Found",
                "message": f"Path {path} not found",
                "available_paths": ["/", "/health", "/data-points", "/users", "/courses", "/api/test"],
                "method": http_method
            })

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return create_response(500, {
            "error": "Internal Server Error",
            "message": str(e),
            "path": path,
            "method": http_method
        })


def get_db_connection():
    """Get database connection - will implement actual connection next"""
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise Exception("DATABASE_URL environment variable not set")

    # For now, return a mock connection status
    # We'll implement actual psycopg2 connection next
    return {
        "status": "configured",
        "url_set": True,
        "host": database_url.split("@")[1].split(":")[0] if "@" in database_url else "unknown"
    }


def handle_health(method):
    """Health check endpoint with database status"""
    if method != 'GET':
        return create_response(405, {"error": "Method not allowed", "allowed": ["GET"]})

    try:
        db_status = get_db_connection()
        return create_response(200, {
            "status": "healthy",
            "message": "Wipsie Backend API is running",
            "environment": "lambda",
            "database": db_status,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })
    except Exception as e:
        return create_response(200, {
            "status": "degraded",
            "message": "API running but database connection failed",
            "database_error": str(e),
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })


def handle_root(method):
    """Root endpoint with API information"""
    return create_response(200, {
        "message": "Welcome to Wipsie Learning Management System API",
        "status": "working",
        "version": "1.1.0",
        "endpoints": {
            "health": "/health",
            "data_points": "/data-points",
            "users": "/users",
            "courses": "/courses",
            "test": "/api/test"
        },
        "method": method,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    })


def handle_data_points(method, body):
    """Handle data points - will connect to database"""
    if method == 'GET':
        # For now, return mock data - will query database next
        return create_response(200, {
            "message": "Data points from database (mock)",
            "data": [
                {"id": 1, "name": "Sample Learning Module",
                    "type": "course", "created_at": "2024-11-02T10:00:00Z"},
                {"id": 2, "name": "User Progress Data", "type": "progress",
                    "created_at": "2024-11-02T11:00:00Z"},
                {"id": 3, "name": "Assessment Results", "type": "assessment",
                    "created_at": "2024-11-02T12:00:00Z"}
            ],
            "total": 3,
            "source": "database_ready",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })

    elif method == 'POST':
        if not body:
            return create_response(400, {"error": "Request body required"})

        # Mock creation response - will insert to database next
        return create_response(201, {
            "message": "Data point would be created in database",
            "received_data": body,
            "mock_id": 123,
            "status": "ready_for_db_insert",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })

    else:
        return create_response(405, {"error": "Method not allowed", "allowed": ["GET", "POST"]})


def handle_users(method, body, params):
    """Handle user management endpoints"""
    if method == 'GET':
        return create_response(200, {
            "message": "Users endpoint (database ready)",
            "users": [
                {"id": 1, "name": "John Doe",
                    "email": "john@example.com", "role": "student"},
                {"id": 2, "name": "Jane Smith",
                    "email": "jane@example.com", "role": "instructor"}
            ],
            "total": 2,
            "filters": params,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })

    elif method == 'POST':
        return create_response(201, {
            "message": "User would be created",
            "user_data": body,
            "status": "ready_for_db",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })

    else:
        return create_response(405, {"error": "Method not allowed", "allowed": ["GET", "POST"]})


def handle_courses(method, body, params):
    """Handle course management endpoints"""
    if method == 'GET':
        return create_response(200, {
            "message": "Courses endpoint (database ready)",
            "courses": [
                {"id": 1, "title": "Introduction to Python",
                    "instructor": "Jane Smith", "students": 25},
                {"id": 2, "title": "Advanced JavaScript",
                    "instructor": "John Doe", "students": 18}
            ],
            "total": 2,
            "filters": params,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })

    elif method == 'POST':
        return create_response(201, {
            "message": "Course would be created",
            "course_data": body,
            "status": "ready_for_db",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })

    else:
        return create_response(405, {"error": "Method not allowed", "allowed": ["GET", "POST"]})


def handle_test(method, params, headers):
    """Test endpoint for debugging"""
    return create_response(200, {
        "message": "Test endpoint working",
        "request_info": {
            "method": method,
            "query_params": params,
            "headers_count": len(headers),
            "database_configured": bool(os.getenv("DATABASE_URL"))
        },
        "timestamp": datetime.utcnow().isoformat() + "Z"
    })


def create_response(status_code, body):
    """Create standardized API response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
            'X-API-Version': '1.1.0',
            'X-Timestamp': datetime.utcnow().isoformat() + 'Z'
        },
        'body': json.dumps(body, default=str)
    }
