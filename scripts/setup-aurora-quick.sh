#!/bin/bash
# Quick Aurora Database Setup
# This script gets your Aurora endpoint and sets up the database

set -e

echo "🔍 Getting Aurora cluster endpoint..."

# First, let's see what clusters exist
echo "Checking for Aurora clusters..."
CLUSTERS=$(aws rds describe-db-clusters --query 'DBClusters[*].[DBClusterIdentifier,Status,Engine,Endpoint]' --output text 2>/dev/null)

if [ -z "$CLUSTERS" ]; then
    echo "❌ No Aurora clusters found in your account."
    echo ""
    echo "📋 Let's check what RDS resources exist:"
    aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,Engine,Endpoint.Address]' --output table 2>/dev/null || echo "No RDS instances found"
    echo ""
    echo "🚀 To create Aurora cluster, you can:"
    echo "1. Run terraform: cd infrastructure && terraform apply -var-file='aurora-serverless.tfvars'"
    echo "2. Create manually in AWS Console: https://console.aws.amazon.com/rds/home?region=us-east-1#launch-dbinstance:"
    exit 1
fi

echo "📋 Available Aurora clusters:"
echo "$CLUSTERS"
echo ""

# Try to find any wipsie-related cluster
AURORA_ENDPOINT=$(aws rds describe-db-clusters \
  --query 'DBClusters[?contains(DBClusterIdentifier, `wipsie`)].Endpoint' \
  --output text 2>/dev/null)

# If no wipsie cluster, try any Aurora cluster
if [ -z "$AURORA_ENDPOINT" ] || [ "$AURORA_ENDPOINT" = "None" ]; then
    AURORA_ENDPOINT=$(aws rds describe-db-clusters \
      --query 'DBClusters[0].Endpoint' \
      --output text 2>/dev/null)
    
    if [ -z "$AURORA_ENDPOINT" ] || [ "$AURORA_ENDPOINT" = "None" ]; then
        echo "❌ No Aurora clusters found or accessible."
        echo "Available clusters shown above. Please ensure you have:"
        echo "1. Aurora cluster deployed"
        echo "2. Correct AWS permissions"
        echo "3. Correct AWS region (us-east-1)"
        exit 1
    else
        echo "⚠️  Using first available Aurora cluster"
    fi
fi

echo "✅ Found Aurora endpoint: $AURORA_ENDPOINT"

# Get database password (you'll need to provide this)
if [ -z "$DB_PASSWORD" ]; then
    echo "Please set the DB_PASSWORD environment variable:"
    echo "export DB_PASSWORD='your-aurora-password'"
    echo ""
    echo "Then run: ./scripts/setup-aurora-quick.sh"
    exit 1
fi

# Export environment variables for the deployment
export AURORA_ENDPOINT
export DB_PASSWORD

echo "🚀 Running Aurora database deployment..."
./scripts/deploy-aurora-db.sh

echo ""
echo "🎉 Setup complete! Your Aurora database is ready."
echo "📊 Connection details:"
echo "   Endpoint: $AURORA_ENDPOINT"
echo "   Database: wipsie"
echo "   Username: postgres"
