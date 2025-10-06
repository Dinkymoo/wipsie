#!/bin/bash
# 🔧 Bootstrap Infrastructure for OIDC Setup
# This script helps resolve the chicken-and-egg problem with GitHub Actions OIDC

set -e

echo "🔧 OIDC Bootstrap Script"
echo "========================"
echo ""
echo "🎯 Purpose: Deploy infrastructure once to enable GitHub Actions OIDC"
echo "📋 Problem: Need role ARN to deploy via GitHub Actions, but need to deploy to get role ARN"
echo "✅ Solution: Bootstrap deployment with admin credentials, then switch to OIDC"
echo ""

# Check if we're in the right directory
if [ ! -d "infrastructure" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS credentials not configured."
    echo ""
    echo "📝 To bootstrap, you need temporary admin AWS credentials:"
    echo "   aws configure --profile bootstrap"
    echo "   export AWS_PROFILE=bootstrap"
    echo ""
    echo "💡 After bootstrap completes, you can remove these credentials"
    echo "   and use OIDC for all future deployments."
    exit 1
fi

# Check current user and permissions
CURRENT_USER=$(aws sts get-caller-identity --query 'Arn' --output text)
echo "🔍 Current AWS User: $CURRENT_USER"

# Test if user has sufficient permissions
echo "🧪 Testing permissions..."
if ! aws ec2 describe-availability-zones --region us-east-1 >/dev/null 2>&1; then
    echo ""
    echo "❌ Current user lacks infrastructure deployment permissions."
    echo "   Current user: $CURRENT_USER"
    echo ""
    echo "🔧 You need temporary admin credentials to bootstrap:"
    echo "   1. Get admin AWS access keys from your AWS admin"
    echo "   2. Configure: aws configure --profile bootstrap"
    echo "   3. Run: export AWS_PROFILE=bootstrap"
    echo "   4. Re-run this script"
    echo ""
    echo "💡 This is a one-time setup. Future deployments will use secure OIDC."
    exit 1
fi

echo "✅ Permissions look good. Proceeding with bootstrap deployment..."
echo ""

cd infrastructure/

# Bootstrap deployment
echo "🔄 Step 1: Initialize Terraform"
terraform init

echo ""
echo "🔄 Step 2: Plan infrastructure deployment"
terraform plan -var-file="staging.tfvars" -out=bootstrap.tfplan

echo ""
echo "🔄 Step 3: Deploy infrastructure (including OIDC role)"
terraform apply bootstrap.tfplan

echo ""
echo "🔄 Step 4: Extract GitHub Actions role ARN"
GITHUB_ROLE_ARN=$(terraform output -raw github_actions_role_arn)

echo ""
echo "🎉 BOOTSTRAP COMPLETED SUCCESSFULLY!"
echo "==================================="
echo ""
echo "✅ Infrastructure deployed to staging"
echo "✅ OIDC provider created"
echo "✅ GitHub Actions role created"
echo ""
echo "🔑 CRITICAL: Set this as GitHub repository variable:"
echo "   Variable name: GITHUB_ACTIONS_ROLE_ARN"
echo "   Variable value: $GITHUB_ROLE_ARN"
echo ""
echo "📋 Next steps:"
echo "1. Go to GitHub repo → Settings → Secrets and variables → Actions → Variables"
echo "2. Create variable: GITHUB_ACTIONS_ROLE_ARN = $GITHUB_ROLE_ARN"
echo "3. Re-run any failed GitHub Actions workflows"
echo "4. All future deployments will use secure OIDC (no more admin credentials needed)"
echo ""
echo "🗑️ SECURITY: You can now remove the bootstrap admin credentials:"
echo "   unset AWS_PROFILE"
echo "   aws configure delete --profile bootstrap"
echo ""
echo "🎯 Lambda functions should deploy automatically via GitHub Actions!"

cd ..

# Save the ARN to a file for reference
echo "$GITHUB_ROLE_ARN" > github-actions-role-arn.txt
echo "💾 GitHub Actions role ARN saved to: github-actions-role-arn.txt"
