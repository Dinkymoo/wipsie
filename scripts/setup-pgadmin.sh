#!/bin/bash
# Quick pgAdmin Setup for Wipsie RDS
# This sets up pgAdmin in Docker for easy database querying

set -e

echo "🐘 SETTING UP PGADMIN FOR WIPSIE DATABASE"
echo "=========================================="
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Stop existing pgAdmin if running
if docker ps -a --format "table {{.Names}}" | grep -q "pgadmin"; then
    echo "🔄 Stopping existing pgAdmin container..."
    docker stop pgadmin >/dev/null 2>&1 || true
    docker rm pgadmin >/dev/null 2>&1 || true
fi

echo "🚀 Starting pgAdmin container..."

# Start pgAdmin
docker run -d \
    --name pgadmin \
    -p 8080:80 \
    -e PGADMIN_DEFAULT_EMAIL=admin@wipsie.com \
    -e PGADMIN_DEFAULT_PASSWORD=admin123 \
    -e PGADMIN_CONFIG_SERVER_MODE=False \
    -e PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=False \
    dpage/pgadmin4:latest

echo "⏳ Waiting for pgAdmin to start..."
sleep 5

# Check if container is running
if docker ps --format "table {{.Names}}" | grep -q "pgadmin"; then
    echo "✅ pgAdmin is running!"
    echo ""
    echo "🌐 Access pgAdmin at: http://localhost:8080"
    echo "📧 Email: admin@wipsie.com"
    echo "🔑 Password: admin123"
    echo ""
    
    # Get RDS connection details
    echo "📋 RDS CONNECTION DETAILS:"
    echo "--------------------------"
    
    cd /workspaces/wipsie/infrastructure
    RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null | cut -d':' -f1)
    DB_NAME=$(terraform output -raw rds_database_name 2>/dev/null || echo "wipsie")
    
    echo "Host: $RDS_ENDPOINT"
    echo "Port: 5432"
    echo "Database: $DB_NAME"
    echo "Username: postgres"
    
    # Try to get password
    if [[ -f "terraform.tfvars" ]]; then
        PASSWORD=$(grep "db_password" terraform.tfvars | cut -d'=' -f2 | tr -d '" ' 2>/dev/null || echo "")
        if [[ -n "$PASSWORD" ]]; then
            echo "Password: $PASSWORD"
        else
            echo "Password: [Check terraform.tfvars]"
        fi
    else
        echo "Password: [Check terraform.tfvars]"
    fi
    
    echo ""
    echo "🔧 TO ADD YOUR DATABASE IN PGADMIN:"
    echo "1. Open http://localhost:8080 in your browser"
    echo "2. Login with admin@wipsie.com / admin123"
    echo "3. Right-click 'Servers' → 'Register' → 'Server'"
    echo "4. General tab: Name = 'Wipsie RDS'"
    echo "5. Connection tab: Enter the details above"
    echo "6. Click 'Save'"
    echo ""
    echo "🎉 Ready to query your PostgreSQL database!"
    echo ""
    echo "🛑 To stop pgAdmin later: docker stop pgadmin"
    
else
    echo "❌ Failed to start pgAdmin"
    echo "Check Docker logs: docker logs pgadmin"
fi
