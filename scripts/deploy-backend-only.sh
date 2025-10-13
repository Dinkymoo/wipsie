#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_section() {
    echo -e "\n${BLUE}📋 $1${NC}"
}

echo "=================================="
echo "🚀 WIPSIE BACKEND DEPLOYMENT"
echo "=================================="

# Remove virtual environment from PATH to use system Python
export PATH="/usr/local/python/current/bin:/usr/local/py-utils/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/sbin:/bin"

# Check for Python and pip
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
    PIP_CMD="/usr/local/bin/pip3"
    print_success "Using system Python: $(python3 --version)"
elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
    PIP_CMD="/usr/local/bin/pip"
    print_success "Using system Python: $(python --version)"
else
    print_error "Python not found"
    exit 1
fi

PROJECT_NAME="wipsie"
DATABASE_URL="postgresql://postgres:WipsieAurora2024!@wipsie-learning-aurora.cluster-cuwqzh1jt5kv.us-east-1.rds.amazonaws.com:5432/wipsie"

cd backend

print_section "Creating Lambda deployment package"
rm -rf lambda-package wipsie-backend.zip

mkdir -p lambda-package

print_warning "Installing dependencies with clean installation..."
$PIP_CMD install -t lambda-package/ --quiet --upgrade \
    fastapi==0.104.1 \
    uvicorn[standard]==0.24.0 \
    psycopg2-binary==2.9.9 \
    sqlalchemy==2.0.23 \
    alembic==1.12.1 \
    boto3==1.34.0 \
    botocore==1.34.0 \
    asyncpg==0.29.0 \
    httpx==0.25.2 \
    pydantic==2.5.0 \
    pydantic-core \
    pydantic-settings==2.1.0 \
    mangum

print_warning "Copying source code..."
cp -r api core db models schemas services utils lambda-package/
cp main.py __init__.py lambda-package/

print_warning "Creating Lambda handler..."
cat > lambda-package/lambda_handler.py << 'EOF'
import os
from mangum import Mangum
from main import app

# Configure for Lambda environment
if 'AWS_LAMBDA_FUNCTION_NAME' in os.environ:
    # We're running in Lambda
    handler = Mangum(app, lifespan="off")
else:
    # Local development
    handler = Mangum(app)

def lambda_handler(event, context):
    return handler(event, context)
EOF

print_warning "Creating deployment package..."
cd lambda-package
zip -r ../wipsie-backend.zip . -x "*.pyc" "*/__pycache__/*" "*.git*" "*/test*" "*/.*" > /dev/null
cd ..

print_section "Setting up AWS Lambda"

# Check if Lambda execution role exists, create if not
ROLE_NAME="wipsie-lambda-execution-role"
ROLE_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/$ROLE_NAME"

if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    print_warning "Creating Lambda execution role..."
    
    # Create trust policy
    cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
    
    # Create the role
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document file://trust-policy.json
    
    # Attach basic Lambda execution policy
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    
    # Attach VPC execution policy (if needed for RDS access)
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
    
    rm trust-policy.json
    print_success "Lambda execution role created"
    
    # Wait for role to be available
    print_warning "Waiting for role to be available..."
    sleep 10
fi

# Create or update Lambda function
FUNCTION_NAME="${PROJECT_NAME}-backend"

if aws lambda get-function --function-name "$FUNCTION_NAME" >/dev/null 2>&1; then
    print_warning "Function exists, updating code..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file fileb://wipsie-backend.zip
else
    print_warning "Creating new Lambda function..."
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime python3.11 \
        --role "$ROLE_ARN" \
        --handler lambda_handler.lambda_handler \
        --zip-file fileb://wipsie-backend.zip \
        --timeout 30 \
        --memory-size 512 \
        --environment Variables="{DATABASE_URL=$DATABASE_URL}" \
        --description "Wipsie Backend API"
fi

# Get Lambda function URL
LAMBDA_ARN=$(aws lambda get-function --function-name "$FUNCTION_NAME" --query 'Configuration.FunctionArn' --output text)

print_success "Backend deployed as Lambda function: $FUNCTION_NAME"
print_info "Lambda ARN: $LAMBDA_ARN"

# Clean up
rm -rf lambda-package wipsie-backend.zip

cd ..

print_section "Deployment Summary"
print_success "✅ Frontend: http://wipsie-frontend-1760293702.s3-website-us-east-1.amazonaws.com"
print_success "✅ Backend: Lambda function '$FUNCTION_NAME' deployed"
print_warning "⚠️  Next Steps:"
print_info "   1. Set up API Gateway to connect to the Lambda function"
print_info "   2. Update frontend environment to use the API Gateway URL"
print_info "   3. Test the complete application"

echo ""
echo "🎉 Backend deployment completed!"
