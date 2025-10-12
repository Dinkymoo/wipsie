#!/bin/bash
# Deploy Database Schema to wipsie-learning-aurora cluster
# This script specifically targets the wipsie-learning-aurora cluster

set -e

echo "🎯 Setting up wipsie-learning-aurora database schema..."

# Specific cluster identifier
CLUSTER_ID="wipsie-learning-aurora"

echo "🔍 Getting Aurora cluster endpoint for $CLUSTER_ID..."

# Get the specific cluster endpoint
AURORA_ENDPOINT=$(aws rds describe-db-clusters \
  --db-cluster-identifier "$CLUSTER_ID" \
  --query 'DBClusters[0].Endpoint' \
  --output text 2>/dev/null)

if [ -z "$AURORA_ENDPOINT" ] || [ "$AURORA_ENDPOINT" = "None" ]; then
    echo "❌ Aurora cluster '$CLUSTER_ID' not found or not accessible."
    echo ""
    echo "Please check:"
    echo "1. Cluster exists: https://console.aws.amazon.com/rds/home?region=us-east-1#databases:"
    echo "2. AWS credentials are configured"
    echo "3. Region is set to us-east-1"
    exit 1
fi

echo "✅ Found Aurora endpoint: $AURORA_ENDPOINT"

# Check if cluster has Data API enabled
DATA_API_ENABLED=$(aws rds describe-db-clusters \
  --db-cluster-identifier "$CLUSTER_ID" \
  --query 'DBClusters[0].HttpEndpointEnabled' \
  --output text 2>/dev/null)

echo "📊 Data API enabled: $DATA_API_ENABLED"

# Get database password from terraform outputs or environment
if [ -z "$DB_PASSWORD" ]; then
    echo "🔐 Attempting to get password from terraform..."
    cd infrastructure
    DB_PASSWORD=$(terraform output -raw aurora_master_password 2>/dev/null || echo "")
    cd ..
    
    if [ -z "$DB_PASSWORD" ]; then
        echo "❌ Database password not found."
        echo ""
        echo "Please set the DB_PASSWORD environment variable:"
        echo "export DB_PASSWORD='your-aurora-password'"
        echo ""
        echo "If you used terraform, the password should be in AWS Secrets Manager."
        echo "You can also find it in the terraform outputs (if not sensitive)."
        exit 1
    fi
fi

# Set environment variables for Alembic
export DATABASE_URL="postgresql+psycopg://postgres:${DB_PASSWORD}@${AURORA_ENDPOINT}:5432/wipsie"
export AURORA_ENDPOINT
export DB_PASSWORD

echo "🚀 Running Alembic database migration..."

# Create database if it doesn't exist (using psql)
echo "📝 Creating database 'wipsie' if it doesn't exist..."
PGPASSWORD="$DB_PASSWORD" psql -h "$AURORA_ENDPOINT" -U postgres -d postgres -c "CREATE DATABASE wipsie;" 2>/dev/null || echo "Database 'wipsie' already exists or creation failed (this is usually OK)"

# Run Alembic migrations
echo "📊 Running Alembic migrations..."
alembic upgrade head

echo ""
echo "🎉 Database schema deployment complete!"
echo ""
echo "📊 Connection Details:"
echo "   Cluster: $CLUSTER_ID"
echo "   Endpoint: $AURORA_ENDPOINT"
echo "   Database: wipsie"
echo "   Username: postgres"
echo "   Data API: $DATA_API_ENABLED"
echo ""
echo "🔗 Access via Query Editor:"
echo "   https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:"
echo ""
echo "✅ Your Aurora PostgreSQL database is ready for use!"
