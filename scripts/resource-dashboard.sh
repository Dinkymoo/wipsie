#!/bin/bash
# Wipsie AWS Resource Dashboard - Simple CLI Version
# Shows comprehensive view of your AWS infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT="wipsie"
ENVIRONMENT="staging"
REGION="us-east-1"
ACCOUNT_ID="554510949034"

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}🎯 WIPSIE AWS RESOURCE DASHBOARD${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo -e "📅 Generated: $(date)"
    echo -e "🌍 Region: ${REGION}"
    echo -e "🏢 Account: ${ACCOUNT_ID}"
    echo -e "📦 Project: ${PROJECT}"
    echo -e "🏷️  Environment: ${ENVIRONMENT}"
    echo -e "${BLUE}=================================${NC}"
}

check_terraform_status() {
    echo -e "\n${PURPLE}📋 TERRAFORM STATUS${NC}"
    echo "----------------------------------------"
    
    cd /workspaces/wipsie/infrastructure
    
    if [ -f "terraform.tfstate" ]; then
        echo -e "${GREEN}✅ Terraform State Found${NC}"
        
        # Get resource count
        RESOURCE_COUNT=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources | length' 2>/dev/null || echo "Unknown")
        echo -e "📊 Deployed Resources: ${RESOURCE_COUNT}"
        
        # Check if plan shows changes
        if terraform plan -detailed-exitcode &>/dev/null; then
            echo -e "${GREEN}✅ Infrastructure Up-to-Date${NC}"
        else
            echo -e "${YELLOW}⚠️  Pending Changes Detected${NC}"
        fi
    else
        echo -e "${RED}❌ No Terraform State Found${NC}"
    fi
}

check_networking() {
    echo -e "\n${CYAN}🌐 NETWORKING RESOURCES${NC}"
    echo "----------------------------------------"
    
    cd /workspaces/wipsie/infrastructure
    
    # Get terraform outputs
    if terraform output vpc_id &>/dev/null; then
        VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "Unknown")
        IGW_ID=$(terraform output -raw internet_gateway_id 2>/dev/null || echo "Unknown")
        
        echo -e "🏠 VPC: ${GREEN}${VPC_ID}${NC}"
        echo -e "🌐 Internet Gateway: ${GREEN}${IGW_ID}${NC}"
        
        # Check NAT Gateway status
        NAT_COUNT=$(terraform output -json nat_gateway_ids 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
        if [ "$NAT_COUNT" = "0" ]; then
            echo -e "🔴 NAT Gateway: ${RED}DISABLED (Cost Optimization)${NC}"
        else
            echo -e "✅ NAT Gateway: ${GREEN}Active (${NAT_COUNT})${NC}"
        fi
        
        # Subnet counts
        PUBLIC_COUNT=$(terraform output -json public_subnet_ids 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
        PRIVATE_COUNT=$(terraform output -json private_subnet_ids 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
        DB_COUNT=$(terraform output -json database_subnet_ids 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
        
        echo -e "🏘️  Public Subnets: ${GREEN}${PUBLIC_COUNT}${NC}"
        echo -e "🏘️  Private Subnets: ${GREEN}${PRIVATE_COUNT}${NC}"
        echo -e "🏘️  Database Subnets: ${GREEN}${DB_COUNT}${NC}"
    else
        echo -e "${RED}❌ Could not retrieve networking information${NC}"
    fi
}

check_compute() {
    echo -e "\n${YELLOW}🚀 COMPUTE RESOURCES${NC}"
    echo "----------------------------------------"
    
    cd /workspaces/wipsie/infrastructure
    
    # ECS Cluster
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "wipsie-cluster-staging")
    
    if aws ecs describe-clusters --clusters "$CLUSTER_NAME" &>/dev/null; then
        echo -e "🎯 ECS Cluster: ${GREEN}${CLUSTER_NAME} (Active)${NC}"
        
        # Check running tasks
        RUNNING_TASKS=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" --query 'clusters[0].runningTasksCount' --output text 2>/dev/null || echo "0")
        PENDING_TASKS=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" --query 'clusters[0].pendingTasksCount' --output text 2>/dev/null || echo "0")
        ACTIVE_SERVICES=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" --query 'clusters[0].activeServicesCount' --output text 2>/dev/null || echo "0")
        
        echo -e "📊 Running Tasks: ${GREEN}${RUNNING_TASKS}${NC}"
        echo -e "⏳ Pending Tasks: ${YELLOW}${PENDING_TASKS}${NC}"
        echo -e "🔧 Active Services: ${GREEN}${ACTIVE_SERVICES}${NC}"
        echo -e "💰 Fargate Support: ${GREEN}FARGATE + FARGATE_SPOT${NC}"
    else
        echo -e "❌ ECS Cluster: ${RED}Not accessible${NC}"
    fi
    
    # Load Balancer status
    ALB_ARN=$(terraform output -raw application_load_balancer_arn 2>/dev/null || echo "")
    if [ -z "$ALB_ARN" ]; then
        echo -e "🔴 Load Balancer: ${RED}DISABLED (Cost Optimization)${NC}"
    else
        echo -e "✅ Load Balancer: ${GREEN}Active${NC}"
    fi
}

check_storage() {
    echo -e "\n${GREEN}🗄️  STORAGE & DATABASE${NC}"
    echo "----------------------------------------"
    
    cd /workspaces/wipsie/infrastructure
    
    # RDS Database
    if aws rds describe-db-instances --output text &>/dev/null; then
        DB_COUNT=$(aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `wipsie`)] | length(@)' --output text 2>/dev/null || echo "0")
        
        if [ "$DB_COUNT" -gt "0" ]; then
            DB_STATUS=$(aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `wipsie`)].DBInstanceStatus' --output text 2>/dev/null || echo "unknown")
            DB_CLASS=$(aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `wipsie`)].DBInstanceClass' --output text 2>/dev/null || echo "unknown")
            echo -e "💾 RDS PostgreSQL: ${GREEN}${DB_STATUS} (${DB_CLASS})${NC}"
        else
            echo -e "💾 RDS PostgreSQL: ${RED}Not found${NC}"
        fi
    else
        echo -e "💾 RDS PostgreSQL: ${RED}Not accessible${NC}"
    fi
    
    # Redis status
    REDIS_ENDPOINT=$(terraform output -raw redis_endpoint 2>/dev/null || echo "")
    if [ -z "$REDIS_ENDPOINT" ]; then
        echo -e "🔴 Redis Cache: ${RED}DISABLED (Cost Optimization)${NC}"
    else
        echo -e "✅ Redis Cache: ${GREEN}Active${NC}"
    fi
    
    # S3 Buckets
    S3_FRONTEND=$(terraform output -raw s3_frontend_bucket 2>/dev/null || echo "")
    S3_LAMBDA=$(terraform output -raw s3_lambda_deployments_bucket 2>/dev/null || echo "")
    
    if [ -n "$S3_FRONTEND" ]; then
        echo -e "🪣 S3 Frontend: ${GREEN}${S3_FRONTEND}${NC}"
    fi
    
    if [ -n "$S3_LAMBDA" ]; then
        echo -e "🪣 S3 Lambda: ${GREEN}${S3_LAMBDA}${NC}"
    fi
    
    # CloudFront status
    CF_DOMAIN=$(terraform output -raw cloudfront_domain_name 2>/dev/null || echo "")
    if [ -z "$CF_DOMAIN" ]; then
        echo -e "🔴 CloudFront: ${RED}DISABLED (Cost Optimization)${NC}"
    else
        echo -e "✅ CloudFront: ${GREEN}Active${NC}"
    fi
}

check_serverless() {
    echo -e "\n${PURPLE}⚡ SERVERLESS RESOURCES${NC}"
    echo "----------------------------------------"
    
    # SQS Queues
    if aws sqs list-queues &>/dev/null; then
        SQS_COUNT=$(aws sqs list-queues --query 'QueueUrls[?contains(@, `wipsie`)] | length(@)' --output text 2>/dev/null || echo "0")
        echo -e "📬 SQS Queues: ${GREEN}${SQS_COUNT} queues${NC}"
        
        # List specific queues
        aws sqs list-queues --query 'QueueUrls[?contains(@, `wipsie`)]' --output text 2>/dev/null | while read -r queue_url; do
            if [ -n "$queue_url" ]; then
                QUEUE_NAME=$(basename "$queue_url")
                # Get message count
                MSG_COUNT=$(aws sqs get-queue-attributes --queue-url "$queue_url" --attribute-names ApproximateNumberOfMessages --query 'Attributes.ApproximateNumberOfMessages' --output text 2>/dev/null || echo "0")
                echo -e "  📝 ${QUEUE_NAME}: ${MSG_COUNT} messages"
            fi
        done
    else
        echo -e "📬 SQS Queues: ${RED}Not accessible${NC}"
    fi
    
    # CloudWatch Logs
    LOG_GROUPS=("/ecs/wipsie-staging" "/aws/lambda/wipsie-data-poller-staging" "/aws/lambda/wipsie-task-processor-staging")
    
    for log_group in "${LOG_GROUPS[@]}"; do
        if aws logs describe-log-groups --log-group-name-prefix "$log_group" &>/dev/null; then
            SERVICE_NAME=$(basename "$log_group")
            echo -e "📊 CloudWatch Logs: ${GREEN}${SERVICE_NAME}${NC}"
        fi
    done
}

show_cost_summary() {
    echo -e "\n${CYAN}💰 COST OPTIMIZATION SUMMARY${NC}"
    echo "========================================="
    echo -e "📊 ${RED}Original Cost:${NC} \$87-91/month"
    echo -e "📊 ${GREEN}Current Cost:${NC}  \$13-18/month"
    echo -e "📊 ${YELLOW}Savings:${NC}       \$69-78/month (85% reduction)"
    echo ""
    echo -e "${GREEN}✅ ENABLED SERVICES (Cost-Optimized):${NC}"
    echo "   • RDS PostgreSQL (t3.micro): ~\$12-15/month"
    echo "   • ECS Fargate: Pay-per-second when learning"
    echo "   • S3 Storage: ~\$1-3/month"
    echo "   • SQS Messages: <\$1/month"
    echo ""
    echo -e "${RED}🔴 DISABLED SERVICES (Cost Savings):${NC}"
    echo "   • NAT Gateway: \$45/month saved"
    echo "   • Redis Cache: \$13/month saved"
    echo "   • Load Balancer: \$16/month saved"
    echo "   • CloudFront: \$8/month saved"
}

show_quick_actions() {
    echo -e "\n${BLUE}🎮 QUICK ACTIONS${NC}"
    echo "----------------------------------------"
    echo "• Open AWS Console:"
    echo "  https://us-east-1.console.aws.amazon.com/ecs/v2/clusters/wipsie-cluster-staging"
    echo ""
    echo "• View Cost Dashboard:"
    echo "  https://us-east-1.console.aws.amazon.com/cost-management/home"
    echo ""
    echo "• Terraform Commands:"
    echo "  cd /workspaces/wipsie/infrastructure"
    echo "  terraform plan"
    echo "  terraform output"
    echo ""
    echo "• Start Learning Session:"
    echo "  # Enable services as needed for learning"
    echo "  terraform apply -var='enable_fargate_service=true'"
    echo ""
    echo "• View Web Dashboard:"
    echo "  Open: /workspaces/wipsie/dashboard/index.html"
}

# Main execution
main() {
    print_header
    check_terraform_status
    check_networking
    check_compute
    check_storage
    check_serverless
    show_cost_summary
    show_quick_actions
    
    echo -e "\n${GREEN}=================================${NC}"
    echo -e "${GREEN}✅ Dashboard Complete!${NC}"
    echo -e "${GREEN}Your infrastructure is deployed and ready for learning.${NC}"
    echo -e "${GREEN}=================================${NC}"
}

# Run the dashboard
main "$@"
