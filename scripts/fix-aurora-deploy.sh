#!/bin/bash
# Quick Aurora Deployment Fix
# Addresses the Terraform errors encountered

set -e

echo "🔧 FIXING AURORA TERRAFORM ERRORS"
echo "=================================="

cd /workspaces/wipsie/infrastructure

echo "✅ Step 1: Initialize Terraform to ensure all providers are ready"
terraform init

echo "✅ Step 2: Validate Terraform configuration"
terraform validate

echo "✅ Step 3: Planning Aurora Serverless deployment with fixed configuration"
terraform plan -var-file="aurora-serverless.tfvars" -detailed-exitcode

if [ $? -eq 2 ]; then
    echo ""
    echo "🚀 Configuration looks good! Ready to deploy."
    echo ""
    read -p "Deploy Aurora Serverless now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🚀 Deploying Aurora Serverless v2..."
        terraform apply -var-file="aurora-serverless.tfvars" -auto-approve
        
        echo ""
        echo "🌟 Aurora Serverless v2 deployed successfully!"
        echo ""
        echo "🎯 NEXT STEPS:"
        echo "1. Wait 2-3 minutes for cluster to be ready"
        echo "2. Access AWS Query Editor: https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:"
        echo "3. Select your Aurora cluster"
        echo "4. Connect with username: postgres"
        echo "5. Start querying!"
        
    else
        echo "Deployment cancelled."
    fi
elif [ $? -eq 0 ]; then
    echo "✅ No changes needed - Aurora may already be deployed"
else
    echo "❌ Configuration has errors. Please check the output above."
fi
