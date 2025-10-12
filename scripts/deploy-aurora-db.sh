#!/bin/bash
# Aurora Database Deployment Script
# This script deploys your database schema to Aurora PostgreSQL using Alembic

set -e  # Exit on any error

echo "🚀 Starting Aurora Database Deployment..."

# Check if we're in the right directory
if [ ! -f "alembic.ini" ]; then
    echo "❌ Error: alembic.ini not found. Please run this script from the project root directory."
    exit 1
fi

# Check if Aurora endpoint is provided
if [ -z "$AURORA_ENDPOINT" ]; then
    echo "❌ Error: AURORA_ENDPOINT environment variable not set"
    echo "Usage: AURORA_ENDPOINT=your-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com ./scripts/deploy-aurora-db.sh"
    exit 1
fi

# Check if database password is provided
if [ -z "$DB_PASSWORD" ]; then
    echo "❌ Error: DB_PASSWORD environment variable not set"
    echo "Usage: DB_PASSWORD=your-password ./scripts/deploy-aurora-db.sh"
    exit 1
fi

# Set database URL for Aurora
export DATABASE_URL="postgresql+psycopg://postgres:${DB_PASSWORD}@${AURORA_ENDPOINT}:5432/wipsie"

echo "📍 Aurora Endpoint: ${AURORA_ENDPOINT}"
echo "🔗 Database URL: postgresql+psycopg://postgres:***@${AURORA_ENDPOINT}:5432/wipsie"

# Test database connection
echo "🔍 Testing database connection..."
python -c "
import psycopg
try:
    conn = psycopg.connect('$DATABASE_URL')
    conn.close()
    print('✅ Database connection successful!')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    exit(1)
"

# Create wipsie database if it doesn't exist
echo "🏗️  Creating 'wipsie' database if it doesn't exist..."
python -c "
import psycopg
from psycopg.sql import SQL, Identifier

# Connect to postgres database to create wipsie database
postgres_url = '$DATABASE_URL'.replace('/wipsie', '/postgres')
try:
    conn = psycopg.connect(postgres_url, autocommit=True)
    cursor = conn.cursor()
    
    # Check if wipsie database exists
    cursor.execute('SELECT 1 FROM pg_database WHERE datname = %s', ('wipsie',))
    if not cursor.fetchone():
        cursor.execute(SQL('CREATE DATABASE {}').format(Identifier('wipsie')))
        print('✅ Created wipsie database')
    else:
        print('✅ wipsie database already exists')
    
    conn.close()
except Exception as e:
    print(f'❌ Failed to create database: {e}')
    exit(1)
"

# Run Alembic migrations
echo "📋 Running Alembic migrations..."
alembic upgrade head

echo "✅ Aurora database deployment completed successfully!"
echo ""
echo "🎯 Your application can now connect using:"
echo "   DATABASE_URL=$DATABASE_URL"
echo ""
echo "🔗 You can also use AWS Query Editor at:"
echo "   https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:"
