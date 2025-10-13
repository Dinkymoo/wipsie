#!/bin/bash

echo "=================================="
echo "🚀 SIMPLE WIPSIE BACKEND DEPLOYMENT"
echo "=================================="

# Set region
REGION="eu-west-1"

# Create a simple FastAPI handler that doesn't use complex dependencies
echo "📋 Creating simplified FastAPI handler..."

cat > /tmp/simple_main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum
import json

app = FastAPI(title="Wipsie API", version="1.0.0")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Wipsie API is running!", "status": "success"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "wipsie-api"}

@app.get("/api/users")
def get_users():
    # Simplified response for now
    return {
        "users": [
            {"id": 1, "name": "Test User", "email": "test@example.com"}
        ],
        "total": 1
    }

# Lambda handler
handler = Mangum(app)
EOF

# Create deployment directory
mkdir -p /tmp/simple_deployment
cd /tmp/simple_deployment

# Copy the simple main file
cp /tmp/simple_main.py main.py

# Install only essential dependencies
echo "📋 Installing minimal dependencies..."
pip install --target . fastapi mangum --no-deps

# Install only the essential dependencies we need
pip install --target . typing_extensions annotated_types

# Create a minimal requirements and install them one by one
pip install --target . starlette
pip install --target . anyio
pip install --target . sniffio
pip install --target . idna

# Create lambda handler
cat > lambda_handler.py << 'EOF'
from main import handler

def lambda_handler(event, context):
    return handler(event, context)
EOF

# Create deployment package
echo "📋 Creating deployment package..."
zip -r /tmp/simple-backend.zip . -x "*.pyc" "*__pycache__*"

# Update Lambda function
echo "📋 Updating Lambda function..."
aws lambda update-function-code \
    --function-name wipsie-backend \
    --zip-file fileb:///tmp/simple-backend.zip \
    --region $REGION

# Update handler
echo "📋 Updating handler configuration..."
aws lambda update-function-configuration \
    --function-name wipsie-backend \
    --handler lambda_handler.lambda_handler \
    --region $REGION

echo "✅ Simple backend deployed!"
echo "🧪 Test with: curl https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/prod/"

# Cleanup
rm -rf /tmp/simple_deployment
rm /tmp/simple_main.py
rm /tmp/simple-backend.zip
