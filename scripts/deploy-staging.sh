#!/bin/bash
# 🚀 Staging Deployment Script
# This script helps deploy the infrastructure and Lambda functions to staging

set -e

echo "🎯 Starting Staging Deployment Process..."

# Step 1: Check if we're in the right directory
if [ ! -d "infrastructure" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

echo "📋 Step 1: Infrastructure Deployment"
echo "======================================="

# Check if AWS credentials are configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "⚠️  AWS credentials not configured locally."
    echo "📝 You have two options:"
    echo ""
    echo "Option 1: Configure AWS credentials locally"
    echo "  aws configure"
    echo "  # Enter your AWS Access Key ID, Secret, Region: us-east-1"
    echo ""
    echo "Option 2: Use GitHub Actions (Recommended)"
    echo "  1. Go to GitHub repository Actions tab"
    echo "  2. Find 'Infrastructure Deployment' workflow"
    echo "  3. Click 'Run workflow' → Select 'staging' → Click 'Run workflow'"
    echo ""
    echo "🔐 After infrastructure deployment, you'll need to:"
    echo "  1. Get the GitHub Actions role ARN: terraform output github_actions_role_arn"
    echo "  2. Set it as repository variable GITHUB_ACTIONS_ROLE_ARN in GitHub"
    exit 1
fi

# Check if current AWS user has sufficient permissions
echo "🔍 Checking AWS credentials and permissions..."
CURRENT_USER=$(aws sts get-caller-identity --query 'Arn' --output text)
echo "Current AWS User: $CURRENT_USER"

# Test basic EC2 permissions required for Terraform
if ! aws ec2 describe-availability-zones --region us-east-1 >/dev/null 2>&1; then
    echo ""
    echo "🚨 PERMISSION ERROR:"
    echo "=============================="
    echo "The current AWS user doesn't have sufficient permissions for infrastructure deployment."
    echo "Current user: $CURRENT_USER"
    echo ""
    echo "❌ Missing permissions include:"
    echo "   - ec2:DescribeAvailabilityZones"
    echo "   - iam:CreateRole, iam:AttachRolePolicy (for IAM roles)"
    echo "   - ecs:CreateCluster (for ECS infrastructure)"
    echo "   - rds:CreateDBSubnetGroup (for RDS infrastructure)"
    echo "   - And many others required for full infrastructure deployment"
    echo ""
    echo "🔧 SOLUTIONS:"
    echo "=============="
    echo ""
    echo "Option 1: Use GitHub Actions (RECOMMENDED) 🚀"
    echo "   - No local credentials needed"
    echo "   - Uses OIDC with proper IAM roles"
    echo "   - Secure and follows best practices"
    echo "   - Go to: GitHub repo → Actions → 'Infrastructure Deployment' workflow"
    echo ""
    echo "Option 2: Use Administrator AWS Credentials 👑"
    echo "   - Configure AWS CLI with admin-level IAM user credentials"
    echo "   - Only for initial infrastructure deployment"
    echo "   - aws configure --profile admin"
    echo "   - export AWS_PROFILE=admin"
    echo ""
    echo "Option 3: Request Infrastructure Deployment Permissions 📋"
    echo "   - Ask AWS admin to grant infrastructure deployment permissions"
    echo "   - Required policies: PowerUserAccess or custom policy with EC2, IAM, ECS, RDS permissions"
    echo ""
    echo "💡 RECOMMENDED: Use GitHub Actions to avoid local credential management!"
    exit 1
fi

echo "✅ AWS credentials found. Deploying infrastructure..."

cd infrastructure/

# Deploy infrastructure
echo "🏗️  Initializing Terraform..."
terraform init

echo "📋 Planning infrastructure changes..."
terraform plan -var-file="staging.tfvars" -out=staging.tfplan

echo "🚀 Applying infrastructure changes..."
terraform apply staging.tfplan

echo "📊 Getting outputs..."
terraform output -json > ../staging-outputs.json

# Get the GitHub Actions role ARN
GITHUB_ROLE_ARN=$(terraform output -raw github_actions_role_arn)
echo ""
echo "🔑 IMPORTANT: Set this as GitHub repository variable 'GITHUB_ACTIONS_ROLE_ARN':"
echo "   $GITHUB_ROLE_ARN"
echo ""

cd ..

echo "📋 Step 2: Lambda Deployment"
echo "============================="
echo "✅ Infrastructure deployed successfully!"
echo "🎯 Lambda functions will be deployed automatically via GitHub Actions"
echo "   (triggered by push to develop branch)"
echo ""
echo "📊 Deployment Status:"
echo "   - Infrastructure: ✅ Deployed to staging"
echo "   - Lambda Functions: 🔄 Deploying via GitHub Actions"
echo ""
echo "🔍 Monitor deployment:"
echo "   1. Go to GitHub repository → Actions tab"
echo "   2. Watch 'AWS Lambda Deployment' workflow"
echo "   3. Check staging environment in AWS Console"
echo ""
echo "🎉 Staging deployment process completed!"
