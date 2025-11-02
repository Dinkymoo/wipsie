import json
import os
import urllib.parse
from datetime import datetime

def lambda_handler(event, context):
    # Log the incoming event for debugging
    print(f"Received event: {json.dumps(event, default=str)}")
    
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
    
    # Simple routing with proper API responses
    if path == '/health':
        response_body = {
            "status": "healthy",
            "message": "Wipsie Backend API is running",
            "environment": "lambda",
            "database_configured": bool(os.getenv("DATABASE_URL")),
            "method": http_method,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        status_code = 200
        
    elif path == '/':
        response_body = {
            "message": "Welcome to Wipsie Backend API",
            "status": "working",
            "version": "1.0.0",
            "endpoints": {
                "health": "/health",
                "data_points": "/data-points",
                "root": "/"
            },
            "method": http_method,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        status_code = 200
        
    elif path == '/data-points':
        if http_method == 'GET':
            response_body = {
                "message": "Data points endpoint",
                "data": [
                    {"id": 1, "name": "Sample Data Point 1", "value": 100},
                    {"id": 2, "name": "Sample Data Point 2", "value": 200}
                ],
                "total": 2,
                "method": http_method,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            }
            status_code = 200
        elif http_method == 'POST':
            response_body = {
                "message": "Data point created",
                "received_data": request_body,
                "method": http_method,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            }
            status_code = 201
        else:
            response_body = {
                "error": "Method not allowed",
                "allowed_methods": ["GET", "POST"]
            }
            status_code = 405
            
    elif path == '/api/test':
        response_body = {
            "message": "Test endpoint working",
            "query_params": query_params,
            "headers_received": len(headers),
            "method": http_method,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        status_code = 200
        
    else:
        response_body = {
            "error": "Not Found",
            "message": f"Path {path} not found",
            "available_paths": ["/", "/health", "/data-points", "/api/test"],
            "method": http_method
        }
        status_code = 404
    
    # Return proper API Gateway response
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
            'X-API-Version': '1.0.0'
        },
        'body': json.dumps(response_body, default=str)
    }
