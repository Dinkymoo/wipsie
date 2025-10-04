#!/bin/bash

# Deploy Wipsie Lambda Functions
# Usage: ./deploy-lambda.sh [environment] [region]

set -e

# Configuration
PROJECT_NAME="wipsie"
ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-us-east-1}
STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-lambda"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying Wipsie Lambda Functions${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}Region: ${AWS_REGION}${NC}"
echo -e "${BLUE}Stack: ${STACK_NAME}${NC}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials are not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI is configured${NC}"

# Function to create deployment package
create_deployment_package() {
    local function_name=$1
    local package_dir="./packages/${function_name}"
    local zip_file="./packages/${function_name}.zip"
    
    echo -e "${YELLOW}📦 Creating deployment package for ${function_name}...${NC}"
    
    # Create package directory
    rm -rf "$package_dir" "$zip_file"
    mkdir -p "$package_dir"
    
    # Copy function code
    cp "./functions/${function_name}.py" "$package_dir/"
    
    # Install dependencies
    if [ -f "./requirements.txt" ]; then
        pip install -r ./requirements.txt -t "$package_dir" --quiet
    fi
    
    # Create zip file
    cd "$package_dir"
    zip -r "../$(basename $zip_file)" . -x "*.pyc" "*__pycache__*" > /dev/null
    cd - > /dev/null
    
    echo -e "${GREEN}✅ Package created: ${zip_file}${NC}"
    echo "$zip_file"
}

# Create packages directory
mkdir -p ./packages

# Create deployment packages
echo -e "${YELLOW}📦 Creating deployment packages...${NC}"
data_poller_package=$(create_deployment_package "data_poller")
task_processor_package=$(create_deployment_package "task_processor")

# Deploy CloudFormation stack
echo -e "${YELLOW}☁️ Deploying CloudFormation stack...${NC}"

aws cloudformation deploy \
    --template-file ./templates/lambda-infrastructure.yml \
    --stack-name "$STACK_NAME" \
    --parameter-overrides \
        ProjectName="$PROJECT_NAME" \
        Environment="$ENVIRONMENT" \
        ApiBaseUrl="https://api.${PROJECT_NAME}.com" \
        WeatherApiKey="demo_key" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$AWS_REGION" \
    --no-fail-on-empty-changeset

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ CloudFormation stack deployed successfully${NC}"
else
    echo -e "${RED}❌ CloudFormation deployment failed${NC}"
    exit 1
fi

# Update Lambda function code
echo -e "${YELLOW}🔄 Updating Lambda function code...${NC}"

# Update Data Poller function
echo -e "${YELLOW}Updating data-poller function...${NC}"
aws lambda update-function-code \
    --function-name "${PROJECT_NAME}-${ENVIRONMENT}-data-poller" \
    --zip-file "fileb://${data_poller_package}" \
    --region "$AWS_REGION" > /dev/null

# Update Task Processor function
echo -e "${YELLOW}Updating task-processor function...${NC}"
aws lambda update-function-code \
    --function-name "${PROJECT_NAME}-${ENVIRONMENT}-task-processor" \
    --zip-file "fileb://${task_processor_package}" \
    --region "$AWS_REGION" > /dev/null

echo -e "${GREEN}✅ Lambda functions updated successfully${NC}"

# Get stack outputs
echo -e "${YELLOW}📋 Getting stack outputs...${NC}"
STACK_OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs" \
    --output table)

echo "$STACK_OUTPUTS"

# Test the functions
echo -e "${YELLOW}🧪 Testing Lambda functions...${NC}"

echo -e "${YELLOW}Testing data-poller function...${NC}"
aws lambda invoke \
    --function-name "${PROJECT_NAME}-${ENVIRONMENT}-data-poller" \
    --payload '{"source": "weather"}' \
    --region "$AWS_REGION" \
    /tmp/data-poller-response.json > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Data poller test successful${NC}"
    echo "Response:"
    cat /tmp/data-poller-response.json | python -m json.tool
else
    echo -e "${RED}❌ Data poller test failed${NC}"
fi

echo ""

echo -e "${YELLOW}Testing task-processor function...${NC}"
aws lambda invoke \
    --function-name "${PROJECT_NAME}-${ENVIRONMENT}-task-processor" \
    --payload '{"task_data": {"type": "email_notification", "recipient": "test@example.com", "subject": "Test Email"}}' \
    --region "$AWS_REGION" \
    /tmp/task-processor-response.json > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Task processor test successful${NC}"
    echo "Response:"
    cat /tmp/task-processor-response.json | python -m json.tool
else
    echo -e "${RED}❌ Task processor test failed${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Lambda deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📚 Useful commands:${NC}"
echo -e "${YELLOW}View logs:${NC} aws logs tail /aws/lambda/${PROJECT_NAME}-${ENVIRONMENT}-data-poller --follow"
echo -e "${YELLOW}Invoke function:${NC} aws lambda invoke --function-name ${PROJECT_NAME}-${ENVIRONMENT}-data-poller --payload '{\"source\":\"weather\"}' response.json"
echo -e "${YELLOW}Update function:${NC} aws lambda update-function-code --function-name ${PROJECT_NAME}-${ENVIRONMENT}-data-poller --zip-file fileb://package.zip"
echo ""
echo -e "${BLUE}🔗 Next steps:${NC}"
echo -e "${YELLOW}1.${NC} Configure your weather API key in AWS Systems Manager Parameter Store"
echo -e "${YELLOW}2.${NC} Set up your FastAPI backend URL"
echo -e "${YELLOW}3.${NC} Configure SES for email notifications"
echo -e "${YELLOW}4.${NC} Set up monitoring and alerts"

# Cleanup
rm -rf ./packages
