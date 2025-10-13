#!/bin/bash
# Wipsie Budget-Optimized Deployment Script
# Deploys frontend to S3+CloudFront and backend to Lambda (no ECS/ALB)

set -e

# Ensure we're using bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="wipsie"
AWS_REGION="us-east-1"
ENVIRONMENT="production"
S3_BUCKET="${PROJECT_NAME}-frontend-$(date +%s)"

print_header() {
    echo -e "${PURPLE}=====================================
💰 WIPSIE BUDGET DEPLOYMENT
=====================================${NC}"
}

print_section() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Activate virtual environment if it exists
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
        print_success "Virtual environment activated"
    fi
    
    # Check AWS CLI (look in common locations)
    AWS_CMD=""
    if command -v aws >/dev/null 2>&1; then
        AWS_CMD="aws"
    elif [ -f ".venv/bin/aws" ]; then
        AWS_CMD=".venv/bin/aws"
    elif [ -f "/usr/local/bin/aws" ]; then
        AWS_CMD="/usr/local/bin/aws"
    else
        print_error "AWS CLI not found. Please install it first."
        print_warning "Try: pip install awscli"
        exit 1
    fi
    
    print_success "AWS CLI found: $AWS_CMD"
    
    # Check AWS credentials
    if ! $AWS_CMD sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    # Check Node.js
    if ! command -v npm >/dev/null 2>&1; then
        print_error "Node.js/npm not found. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Build and deploy frontend to S3
deploy_frontend() {
    print_section "Building and Deploying Frontend to S3"
    
    # Generate unique bucket name
    BUCKET_NAME="wipsie-frontend-$(date +%s)"
    AWS_REGION="us-east-1"  # Default region for S3 website hosting
    
    # Build Angular for production
    print_warning "Building Angular application..."
    cd frontend/wipsie-app
    npm ci
    npm run build:prod
    
    # Create S3 bucket
    echo "⚠️  Creating S3 bucket: $BUCKET_NAME"
    $AWS_CMD s3 mb s3://$BUCKET_NAME
    
    # Configure bucket for static website hosting
    $AWS_CMD s3 website s3://$BUCKET_NAME --index-document index.html --error-document index.html
    
    # First, disable block public access settings
    echo "🔧 Configuring bucket public access settings..."
    $AWS_CMD s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
    
    # Wait a moment for the settings to apply
    sleep 2
    
    # Set bucket policy for public read access
    cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF
    
    echo "🔒 Setting bucket policy for public access..."
    $AWS_CMD s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json
    rm bucket-policy.json
    
    # Upload built files
    print_warning "Uploading to S3..."
    $AWS_CMD s3 sync dist/wipsie-app/ s3://$BUCKET_NAME --delete
    
    cd ../..
    print_success "Frontend deployed to S3: http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"
}

# Deploy backend as Lambda function
deploy_backend_lambda() {
    print_section "Deploying Backend as Lambda Function"
    
    PROJECT_NAME="wipsie"
    DATABASE_URL="postgresql://postgres:WipsieAurora2024!@wipsie-learning-aurora.cluster-cuwqzh1jt5kv.us-east-1.rds.amazonaws.com:5432/wipsie"
    cd backend
    
    # Create deployment package
    print_warning "Creating Lambda deployment package..."
    rm -rf lambda-package wipsie-backend.zip  # Clean up any previous attempts
    mkdir -p lambda-package
    
    # Install dependencies in lambda-package
    print_warning "Installing dependencies..."
    pip install -r requirements.txt -t lambda-package/ --quiet
    
    # Add mangum for Lambda ASGI handling
    pip install mangum -t lambda-package/ --quiet
    
    # Copy source code (excluding unnecessary files)
    print_warning "Copying source code..."
    cp -r api core db models schemas services utils lambda-package/
    cp main.py __init__.py lambda-package/
    
    # Create Lambda handler
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
    
    # Create ZIP file
    print_warning "Creating deployment package..."
    cd lambda-package
    zip -r ../wipsie-backend.zip . -x "*.pyc" "*/__pycache__/*" "*.git*" "*/test*" "*/.*" > /dev/null
    cd ..
    
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
    
    # Create Lambda function
    print_warning "Creating Lambda function..."
    FUNCTION_NAME="${PROJECT_NAME}-backend"
    
    if aws lambda get-function --function-name "$FUNCTION_NAME" >/dev/null 2>&1; then
        print_warning "Function exists, updating code..."
        aws lambda update-function-code \
            --function-name "$FUNCTION_NAME" \
            --zip-file fileb://wipsie-backend.zip
    else
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
    
    # Clean up
    rm -rf lambda-package wipsie-backend.zip
    
    cd ..
    print_success "Backend deployed as Lambda function"
}

# Create API Gateway
setup_api_gateway() {
    print_section "Setting up API Gateway"
    
    # Create API Gateway (simplified version)
    API_ID=$(aws apigateway create-rest-api \
        --name "${PROJECT_NAME}-api" \
        --query 'id' --output text)
    
    print_success "API Gateway created: $API_ID"
    print_warning "⚠️  API Gateway setup requires additional configuration"
    print_warning "   Visit AWS Console to complete Lambda integration"
    print_warning "   https://console.aws.amazon.com/apigateway/home?region=$AWS_REGION"
}

# Setup database
setup_database() {
    print_section "Setting up Aurora Database"
    
    cd backend
    
    print_warning "Running Alembic migrations..."
    alembic upgrade head
    
    echo ""
    read -p "📊 Populate database with sample data? (y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        print_warning "Populating database..."
        python populate_database.py
        print_success "Database populated with sample data"
    fi
    
    cd ..
    print_success "Database setup complete"
}

# Show deployment info
show_deployment_info() {
    print_section "Deployment Information"
    
    echo ""
    echo -e "${GREEN}🎉 Budget Deployment Complete!${NC}"
    echo ""
    echo -e "${BLUE}📋 Application URLs:${NC}"
    echo -e "   🌐 Frontend: http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    echo -e "   🔧 Backend: Lambda function '${PROJECT_NAME}-backend'"
    echo ""
    echo -e "${BLUE}📊 Database:${NC}"
    echo -e "   🗄️  Aurora Endpoint: wipsie-learning-aurora.cluster-xxx.us-east-1.rds.amazonaws.com"
    echo -e "   🔐 Password: WipsieAurora2024!"
    echo ""
    echo -e "${BLUE}💰 Estimated Monthly Cost:${NC}"
    echo -e "   💾 Aurora Serverless v2: $15-25"
    echo -e "   🌐 S3 + Data Transfer: $1-3"
    echo -e "   ⚡ Lambda (pay-per-request): $0-5"
    echo -e "   🔗 API Gateway: $0-5"
    echo -e "   📊 Total: ~$16-38/month"
    echo ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo -e "   1. Complete API Gateway setup in AWS Console"
    echo -e "   2. Update frontend environment with API Gateway URL"
    echo -e "   3. Redeploy frontend with correct API endpoint"
    echo ""
    echo -e "${BLUE}🔗 AWS Console Links:${NC}"
    echo -e "   API Gateway: https://console.aws.amazon.com/apigateway/home?region=$AWS_REGION"
    echo -e "   Lambda: https://console.aws.amazon.com/lambda/home?region=$AWS_REGION"
    echo -e "   S3: https://console.aws.amazon.com/s3/home?region=$AWS_REGION"
}

# Main deployment function
main() {
    print_header
    
    echo "🎯 This budget deployment will create:"
    echo "   • Frontend: Angular app on S3 static hosting"
    echo "   • Backend: FastAPI as Lambda function"
    echo "   • API: AWS API Gateway (requires manual setup)"
    echo "   • Database: Use existing Aurora cluster"
    echo ""
    echo "💰 Estimated cost: ~$16-38/month (vs $40-65 with ECS)"
    echo ""
    
    read -p "🚀 Continue with budget deployment? (y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "Starting deployment..."
    else
        echo "Deployment cancelled."
        exit 0
    fi
    
    check_prerequisites
    deploy_frontend
    deploy_backend_lambda
    setup_api_gateway
    setup_database
    show_deployment_info
    
    echo ""
    echo -e "${GREEN}🚀 Budget deployment completed successfully!${NC}"
    echo -e "${YELLOW}⚠️  Don't forget to complete API Gateway configuration${NC}"
}

# Run main function
main "$@"
