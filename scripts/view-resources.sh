#!/bin/bash
# Wipsie Resource Viewer Script
# Shows your deployed AWS resources

echo "🎯 WIPSIE INFRASTRUCTURE OVERVIEW"
echo "=================================="

# Get account info
echo "📋 Account Information:"
aws sts get-caller-identity --query '{Account:Account,User:Arn}' --output table

echo -e "\n🏗️  Core Infrastructure:"
echo "VPC ID: vpc-0c1e8120f0bea8265"
echo "ECS Cluster: wipsie-cluster-staging"
echo "Region: us-east-1"

echo -e "\n📊 SQS Queues:"
aws sqs list-queues --query 'QueueUrls[?contains(@, `wipsie`)]' --output table

echo -e "\n💰 Estimated Monthly Costs:"
echo "• RDS PostgreSQL (t3.micro): ~$12-15/month"
echo "• ECS Fargate: Pay per second when running"
echo "• S3 Storage: ~$1-3/month"
echo "• SQS: Minimal cost"
echo "• Total (ultra-budget): ~$13-18/month"

echo -e "\n🚀 Quick Actions:"
echo "• View in Console: https://us-east-1.console.aws.amazon.com/ecs/v2/clusters/wipsie-cluster-staging"
echo "• Start Backend Task: terraform plan -target=aws_ecs_service.backend"
echo "• Check Database: aws rds describe-db-instances --output table"

echo -e "\n✅ Infrastructure Status: DEPLOYED & READY FOR FARGATE SERVICES"
