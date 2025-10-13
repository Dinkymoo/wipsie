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
echo "🔐 ADDING IAM PERMISSIONS"
echo "=================================="

USER_NAME="wipsie-infrastructure-user"
POLICY_NAME="WipsieAPIGatewayAccess"

print_section "Creating IAM Policy for API Gateway and CloudFormation"

# Create the policy
print_warning "Creating policy: $POLICY_NAME"
POLICY_ARN=$(aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document file://iam/additional-permissions.json \
    --description "Additional permissions for Wipsie API Gateway deployment" \
    --query 'Policy.Arn' --output text 2>/dev/null || \
    aws iam get-policy --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/$POLICY_NAME" --query 'Policy.Arn' --output text)

print_success "Policy ARN: $POLICY_ARN"

# Attach policy to user
print_warning "Attaching policy to user: $USER_NAME"
aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn "$POLICY_ARN" || print_info "Policy already attached"

print_success "Permissions added successfully!"

print_section "Verification"
print_info "Checking attached policies..."
aws iam list-attached-user-policies --user-name "$USER_NAME"

print_section "Next Steps"
print_info "1. Run the API Gateway setup: bash scripts/setup-api-gateway.sh"
print_info "2. Or deploy via CloudFormation: aws cloudformation deploy --template-file cloudformation/api-gateway.yml --stack-name wipsie-api-gateway --capabilities CAPABILITY_IAM"

echo ""
echo "🎉 IAM permissions setup completed!"
