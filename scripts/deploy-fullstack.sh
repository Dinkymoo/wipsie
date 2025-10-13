#!/bin/bash
# Wipsie Full-Stack Deployment Script
# Deploys backend and frontend to AWS ECS with Aurora PostgreSQL

set -e

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

print_header() {
    echo -e "${PURPLE}=====================================
🚀 WIPSIE FULL-STACK DEPLOYMENT
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
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install it first."
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Create ECR repositories if they don't exist
setup_ecr_repositories() {
    print_section "Setting up ECR Repositories"
    
    # Backend repository
    aws ecr describe-repositories --repository-names "${PROJECT_NAME}-backend" --region $AWS_REGION 2>/dev/null || {
        print_warning "Creating ECR repository for backend..."
        aws ecr create-repository --repository-name "${PROJECT_NAME}-backend" --region $AWS_REGION
        print_success "Backend ECR repository created"
    }
    
    # Frontend repository
    aws ecr describe-repositories --repository-names "${PROJECT_NAME}-frontend" --region $AWS_REGION 2>/dev/null || {
        print_warning "Creating ECR repository for frontend..."
        aws ecr create-repository --repository-name "${PROJECT_NAME}-frontend" --region $AWS_REGION
        print_success "Frontend ECR repository created"
    }
    
    print_success "ECR repositories ready"
}

# Build and push backend
deploy_backend() {
    print_section "Building and Deploying Backend"
    
    # Get ECR login token
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com"
    
    # Build backend image
    print_warning "Building backend Docker image..."
    cd backend
    docker build -t "${PROJECT_NAME}-backend:latest" .
    
    # Tag for ECR
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_BACKEND_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-backend:latest"
    docker tag "${PROJECT_NAME}-backend:latest" $ECR_BACKEND_URI
    
    # Push to ECR
    print_warning "Pushing backend image to ECR..."
    docker push $ECR_BACKEND_URI
    
    cd ..
    print_success "Backend deployed to ECR: $ECR_BACKEND_URI"
}

# Build and push frontend
deploy_frontend() {
    print_section "Building and Deploying Frontend"
    
    # Build Angular for production
    print_warning "Building Angular application..."
    cd frontend/wipsie-app
    npm ci
    npm run build:prod
    
    # Build frontend image (nginx-based)
    print_warning "Building frontend Docker image..."
    docker build -t "${PROJECT_NAME}-frontend:latest" .
    
    # Tag for ECR
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_FRONTEND_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-frontend:latest"
    docker tag "${PROJECT_NAME}-frontend:latest" $ECR_FRONTEND_URI
    
    # Push to ECR
    print_warning "Pushing frontend image to ECR..."
    docker push $ECR_FRONTEND_URI
    
    cd ../..
    print_success "Frontend deployed to ECR: $ECR_FRONTEND_URI"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_section "Deploying Infrastructure with Terraform"
    
    cd infrastructure
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    print_warning "Creating Terraform plan..."
    terraform plan -var-file="aurora-learning.tfvars" -out=deployment.tfplan
    
    # Apply deployment
    echo ""
    read -p "🚀 Ready to deploy infrastructure? (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        print_warning "Applying Terraform configuration..."
        terraform apply deployment.tfplan
        print_success "Infrastructure deployed successfully"
    else
        print_warning "Infrastructure deployment skipped"
    fi
    
    cd ..
}

# Setup database
setup_database() {
    print_section "Setting up Aurora Database"
    
    cd backend
    
    # Run migrations
    print_warning "Running Alembic migrations..."
    alembic upgrade head
    
    # Populate with sample data
    echo ""
    read -p "📊 Populate database with sample data? (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        print_warning "Populating database..."
        python populate_database.py
        print_success "Database populated with sample data"
    fi
    
    cd ..
    print_success "Database setup complete"
}

# Get deployment URLs
show_deployment_info() {
    print_section "Deployment Information"
    
    cd infrastructure
    
    # Get load balancer URL
    ALB_URL=$(terraform output -raw alb_dns_name 2>/dev/null || echo "Not available")
    
    # Get Aurora endpoint
    AURORA_ENDPOINT=$(terraform output -raw aurora_cluster_endpoint 2>/dev/null || echo "Not available")
    
    cd ..
    
    echo ""
    echo -e "${GREEN}🎉 Deployment Complete!${NC}"
    echo ""
    echo -e "${BLUE}📋 Application URLs:${NC}"
    echo -e "   🌐 Frontend: http://$ALB_URL"
    echo -e "   🔧 Backend API: http://$ALB_URL/api/v1"
    echo -e "   📚 API Docs: http://$ALB_URL/docs"
    echo ""
    echo -e "${BLUE}📊 Database:${NC}"
    echo -e "   🗄️  Aurora Endpoint: $AURORA_ENDPOINT"
    echo -e "   🔐 Password: WipsieAurora2024!"
    echo ""
    echo -e "${BLUE}📈 Monitoring:${NC}"
    echo -e "   🔍 ECS Console: https://console.aws.amazon.com/ecs/home?region=$AWS_REGION#clusters"
    echo -e "   📊 Aurora Console: https://console.aws.amazon.com/rds/home?region=$AWS_REGION#databases:"
    echo ""
    echo -e "${YELLOW}⏰ Note: It may take 5-10 minutes for services to be fully available${NC}"
}

# Main deployment function
main() {
    print_header
    
    echo "🎯 This script will deploy:"
    echo "   • Backend FastAPI service to ECS Fargate"
    echo "   • Frontend Angular app to ECS Fargate"
    echo "   • Use existing Aurora PostgreSQL cluster"
    echo "   • Set up load balancer and networking"
    echo ""
    
    read -p "🚀 Continue with deployment? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    check_prerequisites
    setup_ecr_repositories
    deploy_backend
    deploy_frontend
    deploy_infrastructure
    setup_database
    show_deployment_info
    
    echo ""
    echo -e "${GREEN}🚀 Wipsie full-stack application deployed successfully!${NC}"
}

# Run main function
main "$@"
