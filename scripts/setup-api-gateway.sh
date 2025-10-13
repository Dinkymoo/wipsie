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
echo "🌐 WIPSIE API GATEWAY SETUP"
echo "=================================="

PROJECT_NAME="wipsie"
FUNCTION_NAME="${PROJECT_NAME}-backend"
API_NAME="${PROJECT_NAME}-api"
AWS_REGION="eu-west-1"

print_section "Setting up API Gateway"

# Get Lambda function ARN
LAMBDA_ARN=$(aws lambda get-function --function-name "$FUNCTION_NAME" --region "$AWS_REGION" --query 'Configuration.FunctionArn' --output text)
print_info "Lambda ARN: $LAMBDA_ARN"

# Create REST API
print_warning "Creating REST API..."
API_ID=$(aws apigateway create-rest-api \
    --name "$API_NAME" \
    --description "Wipsie Backend API Gateway" \
    --region "$AWS_REGION" \
    --query 'id' --output text)

print_success "API Gateway created: $API_ID"

# Get the root resource ID
ROOT_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$AWS_REGION" \
    --query 'items[0].id' --output text)

print_info "Root resource ID: $ROOT_RESOURCE_ID"

# Create a proxy resource to catch all paths
print_warning "Creating proxy resource..."
PROXY_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$ROOT_RESOURCE_ID" \
    --path-part "{proxy+}" \
    --region "$AWS_REGION" \
    --query 'id' --output text)

print_success "Proxy resource created: $PROXY_RESOURCE_ID"

# Create ANY method on the proxy resource
print_warning "Creating ANY method..."
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$PROXY_RESOURCE_ID" \
    --http-method ANY \
    --authorization-type NONE \
    --region "$AWS_REGION"

# Set up Lambda integration
print_warning "Setting up Lambda integration..."
LAMBDA_URI="arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"

aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$PROXY_RESOURCE_ID" \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "$LAMBDA_URI" \
    --region "$AWS_REGION"

# Also create ANY method on root resource for root path
print_warning "Creating root ANY method..."
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$ROOT_RESOURCE_ID" \
    --http-method ANY \
    --authorization-type NONE \
    --region "$AWS_REGION"

aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$ROOT_RESOURCE_ID" \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "$LAMBDA_URI" \
    --region "$AWS_REGION"

# Add permission for API Gateway to invoke Lambda
print_warning "Adding Lambda permission for API Gateway..."
aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id apigateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${AWS_REGION}:$(aws sts get-caller-identity --query Account --output text):${API_ID}/*/*" \
    --region "$AWS_REGION" \
    2>/dev/null || print_info "Permission already exists"

# Deploy the API
print_warning "Deploying API..."
aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name prod \
    --description "Production deployment" \
    --region "$AWS_REGION"

# Get the API URL
API_URL="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/prod"

print_section "Deployment Summary"
print_success "✅ Frontend: http://wipsie-frontend-1760293702.s3-website-us-east-1.amazonaws.com"
print_success "✅ Backend API: $API_URL"
print_success "✅ Lambda function: $FUNCTION_NAME"
print_info "📝 API Gateway ID: $API_ID"

print_section "Testing the API"
print_warning "Testing API health check..."
curl -s "$API_URL/" && echo "" || print_warning "API not responding yet (this is normal, may take a moment)"

print_section "Next Steps"
print_info "1. Update your frontend environment.prod.ts with the API URL:"
print_info "   apiUrl: '$API_URL'"
print_info "2. Rebuild and redeploy frontend if needed"
print_info "3. Test your application!"

echo ""
echo "🎉 API Gateway setup completed!"
echo "🌐 Your API is available at: $API_URL"
