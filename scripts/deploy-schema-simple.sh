#!/bin/bash
# Simple Database Schema Deployment for wipsie-learning-aurora
# Uses the known cluster endpoint directly

set -e

echo "🎯 Deploying database schema to wipsie-learning-aurora..."

# Known cluster details from terraform deployment
CLUSTER_ID="wipsie-learning-aurora"
# The cluster endpoint follows AWS naming convention
AURORA_ENDPOINT="wipsie-learning-aurora.cluster-cq4e8fmhbjpd.us-east-1.rds.amazonaws.com"
DB_NAME="wipsie"
DB_USER="postgres"

# Check if password is provided
if [ -z "$DB_PASSWORD" ]; then
    echo "❌ Please set the database password:"
    echo "export DB_PASSWORD='your-password'"
    echo ""
    echo "💡 If you used the default terraform settings, try:"
    echo "export DB_PASSWORD='ChangeMe123!'"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "📊 Connection details:"
echo "   Cluster: $CLUSTER_ID"
echo "   Endpoint: $AURORA_ENDPOINT"
echo "   Database: $DB_NAME"
echo "   Username: $DB_USER"

# Test connection first
echo "🔍 Testing database connection..."
PGPASSWORD="$DB_PASSWORD" psql -h "$AURORA_ENDPOINT" -U "$DB_USER" -d postgres -c "SELECT version();" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Connection failed. Please check:"
    echo "1. Aurora cluster is running: https://console.aws.amazon.com/rds/home?region=us-east-1#databases:"
    echo "2. Password is correct"
    echo "3. Security groups allow connections"
    exit 1
fi

echo "✅ Database connection successful!"

# Create database if it doesn't exist
echo "📝 Creating database '$DB_NAME' if needed..."
PGPASSWORD="$DB_PASSWORD" psql -h "$AURORA_ENDPOINT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || echo "Database exists (OK)"

# Set environment for Alembic
export DATABASE_URL="postgresql+psycopg://$DB_USER:$DB_PASSWORD@$AURORA_ENDPOINT:5432/$DB_NAME"

echo "🚀 Running Alembic migrations..."
alembic upgrade head

echo ""
echo "🎉 Database schema deployment complete!"
echo ""
echo "📊 Your PostgreSQL database is ready:"
echo "   Cluster: $CLUSTER_ID"
echo "   Database: $DB_NAME"
echo "   Tables: users, tasks, data_points"
echo ""
echo "🔗 Access via AWS Query Editor:"
echo "   https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:"
echo "   Select cluster: wipsie-learning-aurora"
echo "   Database: wipsie"
echo ""
echo "✨ Ready to run SQL queries!"
