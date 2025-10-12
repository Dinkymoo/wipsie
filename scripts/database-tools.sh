#!/bin/bash

# 🗃️ Database Tools & Connection Helper for Wipsie
# This script helps you connect to your PostgreSQL database using various tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  🗃️ WIPSIE DATABASE TOOLS                   ║${NC}"
echo -e "${BLUE}║                    Query Your Database                       ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"

# Function to display menu
show_menu() {
    echo -e "\n${YELLOW}🛠️ Available Database Tools:${NC}"
    echo ""
    echo "1. 🌐 pgAdmin Web Interface (Recommended)"
    echo "2. 🔧 Install PostgreSQL Client (psql)"
    echo "3. 🌐 Start Adminer Web Interface"
    echo "4. 📋 Show Database Connection Info"
    echo "5. 🔍 Test Database Connection"
    echo "6. 📚 Aurora Setup Guide"
    echo "7. 🔐 AWS Permissions Check"
    echo "8. ❌ Exit"
    echo ""
}

# Function to start pgAdmin
start_pgadmin() {
    echo -e "${GREEN}🌐 Starting pgAdmin Web Interface...${NC}"
    
    # Check if pgAdmin is already running
    if docker ps | grep -q pgadmin; then
        echo -e "${YELLOW}ℹ️ pgAdmin is already running!${NC}"
    else
        docker run -d --name pgadmin \
            -p 5050:80 \
            -e PGADMIN_DEFAULT_EMAIL=admin@wipsie.com \
            -e PGADMIN_DEFAULT_PASSWORD=wipsie123 \
            dpage/pgadmin4
    fi
    
    echo -e "\n${GREEN}✅ pgAdmin is now running!${NC}"
    echo -e "${BLUE}📍 Access URL: http://localhost:5050${NC}"
    echo -e "${BLUE}📧 Email: admin@wipsie.com${NC}"
    echo -e "${BLUE}🔐 Password: wipsie123${NC}"
    echo -e "\n${YELLOW}💡 To connect to your database in pgAdmin:${NC}"
    echo "   1. Open http://localhost:5050 in your browser"
    echo "   2. Login with the credentials above"
    echo "   3. Add New Server with your RDS endpoint details"
}

# Function to install PostgreSQL client
install_psql() {
    echo -e "${GREEN}🔧 Installing PostgreSQL client...${NC}"
    apt update && apt install -y postgresql-client
    echo -e "${GREEN}✅ PostgreSQL client installed!${NC}"
    echo -e "${YELLOW}💡 Usage: psql -h YOUR_RDS_ENDPOINT -U YOUR_USERNAME -d YOUR_DATABASE${NC}"
}

# Function to start Adminer
start_adminer() {
    echo -e "${GREEN}🌐 Starting Adminer Web Interface...${NC}"
    
    if docker ps | grep -q adminer; then
        echo -e "${YELLOW}ℹ️ Adminer is already running!${NC}"
    else
        docker run -d --name adminer -p 8080:8080 adminer
    fi
    
    echo -e "\n${GREEN}✅ Adminer is now running!${NC}"
    echo -e "${BLUE}📍 Access URL: http://localhost:8080${NC}"
    echo -e "\n${YELLOW}💡 Connection details needed:${NC}"
    echo "   - System: PostgreSQL"
    echo "   - Server: Your RDS endpoint"
    echo "   - Username: Your DB username"
    echo "   - Password: Your DB password"
    echo "   - Database: Your database name"
}

# Function to show connection info
show_connection_info() {
    echo -e "${BLUE}📋 Database Connection Information${NC}"
    echo -e "${YELLOW}══════════════════════════════════${NC}"
    
    # Try to get RDS endpoint from Terraform outputs
    if [ -f "infrastructure/terraform.tfstate" ]; then
        echo -e "${GREEN}From Terraform State:${NC}"
        cd infrastructure
        DB_ENDPOINT=$(terraform output -raw database_endpoint 2>/dev/null || echo "Not available")
        DB_NAME=$(terraform output -raw database_name 2>/dev/null || echo "Not available") 
        cd ..
        echo "🔗 RDS Endpoint: $DB_ENDPOINT"
        echo "🗃️ Database Name: $DB_NAME"
        echo "🔌 Port: 5432"
    else
        echo -e "${YELLOW}⚠️ No Terraform state found. You'll need:${NC}"
        echo "🔗 RDS Endpoint: (from AWS Console or terraform output)"
        echo "🗃️ Database Name: (your database name)"
        echo "👤 Username: (your database username)"
        echo "🔐 Password: (your database password)"
        echo "🔌 Port: 5432"
    fi
    
    echo -e "\n${BLUE}🔧 Connection String Format:${NC}"
    echo "postgresql://username:password@endpoint:5432/database_name"
}

# Function to test database connection
test_connection() {
    echo -e "${BLUE}🔍 Testing Database Connection...${NC}"
    
    # Check if psql is installed
    if ! command -v psql &> /dev/null; then
        echo -e "${RED}❌ PostgreSQL client not installed. Install it first (option 2).${NC}"
        return 1
    fi
    
    read -p "Enter RDS endpoint: " DB_HOST
    read -p "Enter database name: " DB_NAME
    read -p "Enter username: " DB_USER
    read -s -p "Enter password: " DB_PASS
    echo ""
    
    # Test connection
    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Database connection successful!${NC}"
    else
        echo -e "${RED}❌ Database connection failed. Check your credentials.${NC}"
    fi
}

# Function to show Aurora guide
show_aurora_guide() {
    echo -e "${PURPLE}🌟 Aurora PostgreSQL Setup Guide${NC}"
    echo -e "${YELLOW}═══════════════════════════════════${NC}"
    
    cat << 'EOF'
🎯 Why Aurora for Query Editor:
   • AWS Query Editor only works with Aurora (not regular RDS)
   • Aurora has Data API for web-based SQL access
   • Cost-optimized with Serverless v2 (~$15-30/month)

🚀 Manual Aurora Setup Steps:
   1. Go to AWS RDS Console
   2. Create Database → Aurora PostgreSQL-Compatible
   3. Choose "Serverless v2" for cost optimization
   4. Configure networking (use existing VPC/subnets)
   5. Enable "Data API" in Connectivity section
   6. Set database name, username, password
   7. Create cluster

🔧 After Creation:
   1. Wait for cluster to be available (~10-15 minutes)
   2. Note the cluster endpoint
   3. Access Query Editor: https://console.aws.amazon.com/rds/home#query-editor:
   4. Select your Aurora cluster
   5. Start querying!

💰 Cost Optimization:
   • Use Serverless v2 (scales to zero when not used)
   • Set minimum capacity to 0.5 ACU
   • Set maximum capacity to 2-4 ACU for learning
   • Enable auto-pause after 5-10 minutes of inactivity
EOF

    echo -e "\n${BLUE}📋 Current Aurora Infrastructure Status:${NC}"
    if [ -f "infrastructure/aurora.tf" ]; then
        echo -e "${GREEN}✅ Aurora Terraform configuration ready${NC}"
        echo -e "${YELLOW}⚠️ Blocked by AWS permissions (need broader access than current SQS-only user)${NC}"
    else
        echo -e "${RED}❌ Aurora configuration not found${NC}"
    fi
}

# Function to check AWS permissions
check_aws_permissions() {
    echo -e "${BLUE}🔐 AWS Permissions Check${NC}"
    echo -e "${YELLOW}═════════════════════════${NC}"
    
    echo -e "\n${BLUE}Current AWS Identity:${NC}"
    aws sts get-caller-identity 2>/dev/null || echo "❌ AWS CLI not configured"
    
    echo -e "\n${BLUE}Testing Required Permissions:${NC}"
    
    # Test RDS permissions
    echo -n "🔍 RDS Access: "
    if aws rds describe-db-instances --max-items 1 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Has RDS access${NC}"
    else
        echo -e "${RED}❌ No RDS access${NC}"
    fi
    
    # Test VPC permissions  
    echo -n "🔍 VPC Access: "
    if aws ec2 describe-vpcs --max-items 1 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Has VPC access${NC}"
    else
        echo -e "${RED}❌ No VPC access${NC}"
    fi
    
    # Test IAM permissions
    echo -n "🔍 IAM Access: "
    if aws iam list-roles --max-items 1 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Has IAM access${NC}"
    else
        echo -e "${RED}❌ No IAM access${NC}"
    fi
    
    echo -e "\n${YELLOW}💡 For Aurora setup, you need an AWS user with:${NC}"
    echo "   • AmazonRDSFullAccess (for Aurora cluster management)"
    echo "   • AmazonVPCFullAccess (for networking configuration)"
    echo "   • IAMFullAccess (for creating service roles)"
    echo "   • CloudWatchFullAccess (for logging and monitoring)"
}

# Main menu loop
while true; do
    show_menu
    read -p "Choose an option (1-8): " choice
    
    case $choice in
        1) start_pgadmin ;;
        2) install_psql ;;
        3) start_adminer ;;
        4) show_connection_info ;;
        5) test_connection ;;
        6) show_aurora_guide ;;
        7) check_aws_permissions ;;
        8) echo -e "${GREEN}👋 Happy querying!${NC}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option. Please choose 1-8.${NC}" ;;
    esac
    
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read
done
