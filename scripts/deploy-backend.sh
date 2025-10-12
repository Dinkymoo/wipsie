#!/bin/bash
# Build and deploy Wipsie backend to AWS ECS Fargate
# This script builds the Docker image and deploys it to ECR and ECS

set -e

# Configuration
PROJECT_NAME="wipsie"
ENVIRONMENT="staging"
REGION="us-east-1"
ACCOUNT_ID="554510949034"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🚀 $1${NC}"
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
    print_step "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Build Docker image
build_image() {
    print_step "Building Docker image..."
    
    cd /workspaces/wipsie/backend
    
    # Build image with timestamp tag
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    IMAGE_TAG="${TIMESTAMP}"
    
    docker build -t ${PROJECT_NAME}-backend:${IMAGE_TAG} .
    docker tag ${PROJECT_NAME}-backend:${IMAGE_TAG} ${PROJECT_NAME}-backend:latest
    
    print_success "Docker image built: ${PROJECT_NAME}-backend:${IMAGE_TAG}"
    
    # Return to infrastructure directory
    cd /workspaces/wipsie/infrastructure
}

# Push to ECR
push_to_ecr() {
    print_step "Pushing image to ECR..."
    
    # Get ECR repository URI
    ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${PROJECT_NAME}-backend-${ENVIRONMENT}"
    
    # Login to ECR
    aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
    
    # Tag and push image
    docker tag ${PROJECT_NAME}-backend:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
    docker tag ${PROJECT_NAME}-backend:${IMAGE_TAG} ${ECR_REPO}:latest
    
    docker push ${ECR_REPO}:${IMAGE_TAG}
    docker push ${ECR_REPO}:latest
    
    print_success "Image pushed to ECR: ${ECR_REPO}:${IMAGE_TAG}"
}

# Deploy with Terraform
deploy_infrastructure() {
    print_step "Deploying infrastructure with Terraform..."
    
    cd /workspaces/wipsie/infrastructure
    
    # Enable Fargate service and set image tag
    terraform apply \
        -var="enable_fargate_service=true" \
        -var="backend_image_tag=${IMAGE_TAG}" \
        -var="fargate_desired_count=1" \
        -var="fargate_use_spot=true" \
        -auto-approve
    
    print_success "Infrastructure deployed successfully"
}

# Get service status
get_service_status() {
    print_step "Checking service status..."
    
    # Get ECS service status
    aws ecs describe-services \
        --cluster ${PROJECT_NAME}-cluster-${ENVIRONMENT} \
        --services ${PROJECT_NAME}-backend-${ENVIRONMENT} \
        --query 'services[0].{Status:status,Running:runningCount,Pending:pendingCount,Desired:desiredCount}' \
        --output table
    
    # Get service endpoint
    if [ "$ENABLE_ALB" = "true" ]; then
        ALB_DNS=$(terraform output -raw application_load_balancer_dns 2>/dev/null || echo "")
        if [ -n "$ALB_DNS" ]; then
            print_success "Service available at: http://${ALB_DNS}"
        fi
    else
        print_warning "Load balancer disabled. Service running in public subnets."
        print_warning "For direct access, you'll need to get the task public IP."
    fi
}

# Show helpful commands
show_helpful_commands() {
    print_step "Helpful commands for monitoring:"
    
    echo ""
    echo "📊 Monitor ECS service:"
    echo "  aws ecs describe-services --cluster ${PROJECT_NAME}-cluster-${ENVIRONMENT} --services ${PROJECT_NAME}-backend-${ENVIRONMENT}"
    echo ""
    echo "📋 View service logs:"
    echo "  aws logs tail /ecs/${PROJECT_NAME}-${ENVIRONMENT} --follow"
    echo ""
    echo "🔧 Scale service:"
    echo "  aws ecs update-service --cluster ${PROJECT_NAME}-cluster-${ENVIRONMENT} --service ${PROJECT_NAME}-backend-${ENVIRONMENT} --desired-count 2"
    echo ""
    echo "⏹️  Stop service (save costs):"
    echo "  aws ecs update-service --cluster ${PROJECT_NAME}-cluster-${ENVIRONMENT} --service ${PROJECT_NAME}-backend-${ENVIRONMENT} --desired-count 0"
    echo ""
    echo "🚀 Redeploy with new image:"
    echo "  aws ecs update-service --cluster ${PROJECT_NAME}-cluster-${ENVIRONMENT} --service ${PROJECT_NAME}-backend-${ENVIRONMENT} --force-new-deployment"
}

# Main execution
main() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}🎯 WIPSIE BACKEND DEPLOYMENT${NC}"
    echo -e "${BLUE}=================================${NC}"
    
    check_prerequisites
    build_image
    push_to_ecr
    deploy_infrastructure
    get_service_status
    show_helpful_commands
    
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}✅ Deployment Complete!${NC}"
    echo -e "${GREEN}Backend service is now running on Fargate${NC}"
    echo -e "${GREEN}=================================${NC}"
}

# Check if running as script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
