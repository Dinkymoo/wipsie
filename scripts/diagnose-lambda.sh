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
echo "🔍 LAMBDA DIAGNOSTICS"
echo "=================================="

FUNCTION_NAME="wipsie-backend"
API_ID="yb6i0oap3c"
AWS_REGION="eu-west-1"

print_section "1. Lambda Function Status"

# Check if function exists
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    print_success "Lambda function exists"
    
    # Get function configuration
    CONFIG=$(aws lambda get-function-configuration --function-name "$FUNCTION_NAME" --region "$AWS_REGION")
    HANDLER=$(echo "$CONFIG" | grep -o '"Handler": "[^"]*"' | cut -d'"' -f4)
    STATE=$(echo "$CONFIG" | grep -o '"State": "[^"]*"' | cut -d'"' -f4)
    
    print_info "Handler: $HANDLER"
    print_info "State: $STATE"
    
    if [ "$STATE" = "Active" ]; then
        print_success "Lambda function is active"
    else
        print_warning "Lambda function state: $STATE"
    fi
else
    print_error "Lambda function not found"
    exit 1
fi

print_section "2. API Gateway Status"

# Check if API exists
if aws apigateway get-rest-api --rest-api-id "$API_ID" --region "$AWS_REGION" >/dev/null 2>&1; then
    print_success "API Gateway exists"
    
    # Test API Gateway endpoint
    print_info "Testing API Gateway endpoint..."
    RESPONSE=$(curl -s -w "%{http_code}" https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/prod/ -o /tmp/api_response.txt)
    
    echo "Response code: $RESPONSE"
    echo "Response body:"
    cat /tmp/api_response.txt
    echo ""
    
    if [ "$RESPONSE" = "200" ]; then
        print_success "API Gateway responding successfully"
    else
        print_warning "API Gateway returning: $RESPONSE"
    fi
else
    print_error "API Gateway not found"
fi

print_section "3. Lambda Permissions"

# Check Lambda permissions
print_info "Checking Lambda permissions..."
if aws lambda get-policy --function-name "$FUNCTION_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    print_success "Lambda has policy attached"
    aws lambda get-policy --function-name "$FUNCTION_NAME" --region "$AWS_REGION" | jq -r '.Policy' | jq .
else
    print_warning "No policy found for Lambda function"
fi

print_section "4. Recent Lambda Logs"

# Get recent logs
print_info "Fetching recent Lambda logs..."
LATEST_STREAM=$(aws logs describe-log-streams \
    --log-group-name /aws/lambda/$FUNCTION_NAME \
    --region "$AWS_REGION" \
    --order-by LastEventTime \
    --descending \
    --max-items 1 \
    --query 'logStreams[0].logStreamName' \
    --output text 2>/dev/null || echo "none")

if [ "$LATEST_STREAM" != "none" ] && [ "$LATEST_STREAM" != "None" ]; then
    print_success "Found log stream: $LATEST_STREAM"
    echo "Recent log events:"
    aws logs get-log-events \
        --log-group-name /aws/lambda/$FUNCTION_NAME \
        --log-stream-name "$LATEST_STREAM" \
        --region "$AWS_REGION" \
        --start-time $(($(date +%s) - 3600))000 \
        --query 'events[*].message' \
        --output text
else
    print_warning "No recent log streams found"
fi

print_section "5. Quick Fixes"

echo "To fix common issues, try:"
echo "1. Reset handler:"
echo "   aws lambda update-function-configuration --function-name $FUNCTION_NAME --handler test_lambda.lambda_handler --region $AWS_REGION"
echo ""
echo "2. Add API Gateway permission:"
echo "   aws lambda add-permission --function-name $FUNCTION_NAME --statement-id allow-api-gateway --action lambda:InvokeFunction --principal apigateway.amazonaws.com --region $AWS_REGION"
echo ""
echo "3. Test in AWS Console:"
echo "   Go to Lambda Console → $FUNCTION_NAME → Test tab"
echo ""
echo "4. Redeploy backend:"
echo "   bash scripts/deploy-backend-only.sh"

echo ""
echo "🔍 Diagnostics completed!"
