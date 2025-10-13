#!/bin/bash

echo "=================================="
echo "🚀 ULTRA-SIMPLE BACKEND DEPLOYMENT"
echo "=================================="

# Create a completely simple handler
mkdir -p /tmp/ultra_simple
cd /tmp/ultra_simple

# Create a basic handler that works without any complex dependencies
cat > lambda_handler.py << 'EOF'
import json

def lambda_handler(event, context):
    """Ultra simple Lambda handler"""
    
    # Basic routing based on path
    path = event.get('path', '/')
    method = event.get('httpMethod', 'GET')
    
    if path == '/' and method == 'GET':
        response_body = {
            "message": "Wipsie API is running!",
            "status": "success",
            "path": path,
            "method": method
        }
    elif path == '/health' and method == 'GET':
        response_body = {
            "status": "healthy",
            "service": "wipsie-api"
        }
    elif path == '/api/users' and method == 'GET':
        response_body = {
            "users": [
                {"id": 1, "name": "Test User", "email": "test@example.com"}
            ],
            "total": 1
        }
    else:
        response_body = {
            "error": "Not found",
            "path": path,
            "method": method
        }
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        },
        'body': json.dumps(response_body)
    }
EOF

# Create deployment package
zip -r /tmp/ultra-simple.zip . 

# Update Lambda function
echo "📋 Updating Lambda function..."
aws lambda update-function-code \
    --function-name wipsie-backend \
    --zip-file fileb:///tmp/ultra-simple.zip \
    --region eu-west-1

echo "✅ Ultra-simple backend deployed!"
echo "🧪 Test with: curl https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/prod/"

# Cleanup
rm -rf /tmp/ultra_simple
rm /tmp/ultra-simple.zip
