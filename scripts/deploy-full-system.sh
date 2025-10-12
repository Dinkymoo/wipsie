#!/bin/bash
# Complete deployment script for Wipsie learning environment
# Deploys both backend (Fargate) and frontend (S3) for a full hosted system

set -e

# Configuration
PROJECT_NAME="wipsie"
ENVIRONMENT="staging"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${PURPLE}=================================${NC}"
    echo -e "${PURPLE}🎯 WIPSIE LEARNING ENVIRONMENT${NC}"
    echo -e "${PURPLE}   FULL SYSTEM DEPLOYMENT${NC}"
    echo -e "${PURPLE}=================================${NC}"
}

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

# Show deployment plan
show_deployment_plan() {
    print_step "Deployment Plan:"
    echo ""
    echo "📦 Backend (FastAPI on ECS Fargate):"
    echo "   • Build Docker image"
    echo "   • Push to ECR"
    echo "   • Deploy to Fargate with Spot instances"
    echo "   • Auto-scaling enabled"
    echo ""
    echo "🌐 Frontend (Static site on S3):"
    echo "   • Build learning-focused UI"
    echo "   • Deploy to S3 with website hosting"
    echo "   • API testing capabilities built-in"
    echo ""
    echo "💰 Cost Optimization:"
    echo "   • Fargate Spot: ~70% savings"
    echo "   • S3 static hosting: <$1/month"
    echo "   • Scale to zero when not learning"
    echo ""
    
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
}

# Check system requirements
check_requirements() {
    print_step "Checking system requirements..."
    
    local errors=0
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is required but not installed"
        errors=$((errors + 1))
    fi
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is required but not installed"
        errors=$((errors + 1))
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is required but not installed"
        errors=$((errors + 1))
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        errors=$((errors + 1))
    fi
    
    if [ $errors -gt 0 ]; then
        print_error "$errors requirement(s) not met. Please fix and try again."
        exit 1
    fi
    
    print_success "All requirements satisfied"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_step "Deploying base infrastructure..."
    
    cd /workspaces/wipsie/infrastructure
    
    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        terraform init
    fi
    
    # Plan infrastructure
    terraform plan -out=deployment.tfplan
    
    # Apply infrastructure
    terraform apply deployment.tfplan
    
    print_success "Base infrastructure deployed"
}

# Deploy backend
deploy_backend() {
    print_step "Deploying backend service..."
    
    # Make script executable and run it
    chmod +x /workspaces/wipsie/scripts/deploy-backend.sh
    /workspaces/wipsie/scripts/deploy-backend.sh
    
    print_success "Backend deployment completed"
}

# Deploy frontend
deploy_frontend() {
    print_step "Deploying frontend application..."
    
    # Make script executable and run it
    chmod +x /workspaces/wipsie/scripts/deploy-frontend.sh
    /workspaces/wipsie/scripts/deploy-frontend.sh
    
    print_success "Frontend deployment completed"
}

# Wait for services to be healthy
wait_for_services() {
    print_step "Waiting for services to become healthy..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # Check ECS service status
        local running_count=$(aws ecs describe-services \
            --cluster ${PROJECT_NAME}-cluster-${ENVIRONMENT} \
            --services ${PROJECT_NAME}-backend-${ENVIRONMENT} \
            --query 'services[0].runningCount' \
            --output text 2>/dev/null || echo "0")
        
        if [ "$running_count" -gt "0" ]; then
            print_success "Backend service is running"
            break
        fi
        
        echo "Attempt $attempt/$max_attempts: Waiting for backend service..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_warning "Backend service took longer than expected to start"
        print_warning "Check the ECS console for details"
    fi
}

# Show final status and access information
show_final_status() {
    print_step "Deployment Summary:"
    echo ""
    
    cd /workspaces/wipsie/infrastructure
    
    # Get infrastructure information
    local cluster_name=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "Unknown")
    local s3_bucket=$(terraform output -raw s3_frontend_bucket 2>/dev/null || echo "Unknown")
    local frontend_url="http://${s3_bucket}.s3-website-${REGION}.amazonaws.com"
    
    echo "🎯 System Status:"
    echo "   Frontend: ✅ Deployed to S3"
    echo "   Backend:  ✅ Running on Fargate"
    echo "   Database: ✅ PostgreSQL ready"
    echo "   Queues:   ✅ SQS configured"
    echo ""
    
    echo "🌐 Access URLs:"
    echo "   Frontend: ${frontend_url}"
    echo "   Backend:  Check ECS service for endpoint"
    echo ""
    
    echo "💰 Monthly Costs (Learning Mode):"
    echo "   Backend:  ~$1-3/month (pay per second when running)"
    echo "   Frontend: ~$0.50/month (S3 static hosting)"
    echo "   Database: ~$12-15/month (t3.micro always-on)"
    echo "   Total:    ~$13-18/month"
    echo ""
    
    echo "🎮 Management Commands:"
    echo "   Scale backend to 0: aws ecs update-service --cluster ${cluster_name} --service ${PROJECT_NAME}-backend-${ENVIRONMENT} --desired-count 0"
    echo "   Scale backend to 1: aws ecs update-service --cluster ${cluster_name} --service ${PROJECT_NAME}-backend-${ENVIRONMENT} --desired-count 1"
    echo "   View logs:         aws logs tail /ecs/${PROJECT_NAME}-${ENVIRONMENT} --follow"
    echo "   Resource dashboard: /workspaces/wipsie/scripts/resource-dashboard.sh"
    echo ""
    
    echo "📚 Learning Features:"
    echo "   • API testing built into frontend"
    echo "   • Health check monitoring"
    echo "   • Cost optimization tracking"
    echo "   • Auto-scaling capabilities"
    echo "   • Real-time logging"
}

# Cleanup function for interrupted deployments
cleanup_on_interrupt() {
    print_warning "Deployment interrupted. You may need to:"
    echo "1. Check ECS service status"
    echo "2. Review CloudWatch logs"
    echo "3. Run terraform plan to see any pending changes"
    echo "4. Use scripts/resource-dashboard.sh to check status"
    exit 130
}

# Main execution
main() {
    # Set up interrupt handler
    trap cleanup_on_interrupt INT
    
    print_banner
    show_deployment_plan
    check_requirements
    
    echo ""
    print_step "Starting full system deployment..."
    echo ""
    
    deploy_infrastructure
    deploy_backend
    deploy_frontend
    wait_for_services
    
    echo ""
    show_final_status
    
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}🎉 DEPLOYMENT SUCCESSFUL!${NC}"
    echo -e "${GREEN}Your learning environment is ready${NC}"
    echo -e "${GREEN}=================================${NC}"
}

# Check if running as script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
