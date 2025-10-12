#!/bin/bash
# Quick RDS Query Editor Access
# Run this script to get all the info you need to connect

set -e

echo "🗄️  WIPSIE RDS QUERY EDITOR ACCESS"
echo "=================================="
echo ""

# Get connection details
cd /workspaces/wipsie/infrastructure

RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "Not available")
DB_NAME=$(terraform output -raw rds_database_name 2>/dev/null || echo "wipsie")

echo "📊 CONNECTION DETAILS:"
echo "----------------------"
echo "🌐 RDS Endpoint: $RDS_ENDPOINT"
echo "🗄️  Database Name: $DB_NAME"
echo "👤 Username: postgres"
echo "🔑 Password: [Check your terraform.tfvars or .env file]"
echo ""

echo "🚀 ACCESS OPTIONS:"
echo "------------------"

echo ""
echo "❌ AWS RDS Query Editor (NOT AVAILABLE)"
echo "   📱 AWS Query Editor only supports Aurora Serverless"
echo "   � Your RDS PostgreSQL is not compatible"
echo ""

echo "1. 🥇 pgAdmin (Recommended)"
echo "   🐘 Web-based PostgreSQL administration tool"
echo "   💻 Run: docker run -d -p 8080:80 -e PGADMIN_DEFAULT_EMAIL=admin@wipsie.com -e PGADMIN_DEFAULT_PASSWORD=admin123 dpage/pgadmin4"
echo ""

echo "2. 🥈 Command Line (psql)"
echo "   💻 Command: psql -h ${RDS_ENDPOINT%:*} -U postgres -d $DB_NAME"
echo "   📦 Install: sudo apt-get install postgresql-client"
echo ""

echo "3. 🥉 Local GUI Tools"
echo "   🔧 DBeaver: https://dbeaver.io/download/"
echo "   🔧 DataGrip: https://www.jetbrains.com/datagrip/"
echo ""

echo "🔐 SECURITY NOTE:"
echo "-----------------"
echo "Your RDS is in a private subnet with security groups."
echo "AWS Query Editor works through the AWS console (recommended)."
echo "For local connections, you may need to update security groups."
echo ""

echo "💡 QUICK START:"
echo "---------------"
echo "1. Run pgAdmin: docker run -d -p 8080:80 -e PGADMIN_DEFAULT_EMAIL=admin@wipsie.com -e PGADMIN_DEFAULT_PASSWORD=admin123 dpage/pgadmin4"
echo "2. Open: http://localhost:8080"
echo "3. Login with admin@wipsie.com / admin123"
echo "4. Add server with connection details above"
echo "5. Start querying!"
echo ""

echo "📝 SAMPLE QUERIES:"
echo "------------------"
echo "-- List all tables"
echo "\\dt"
echo ""
echo "-- Check database info"
echo "SELECT version();"
echo ""
echo "-- View table structure"
echo "\\d table_name"
echo ""

# Check if password is available
if [[ -f "../.env" ]]; then
    PASSWORD=$(grep "POSTGRES_PASSWORD" ../.env | cut -d'=' -f2 | tr -d '"' || echo "")
    if [[ -n "$PASSWORD" ]]; then
        echo "🔑 Found password in .env: $PASSWORD"
    fi
fi

if [[ -f "terraform.tfvars" ]]; then
    PASSWORD=$(grep "db_password" terraform.tfvars | cut -d'=' -f2 | tr -d '" ' || echo "")
    if [[ -n "$PASSWORD" ]]; then
        echo "🔑 Found password in terraform.tfvars: $PASSWORD"
    fi
fi

echo ""
echo "🌟 Ready to query your PostgreSQL database!"
