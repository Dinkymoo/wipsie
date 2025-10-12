#!/bin/bash
# Wipsie Learning Environment Manager
# Main entry point for all cost optimization and management tools

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${PURPLE}
╔═══════════════════════════════════════════════════════════════╗
║                    🚀 WIPSIE LEARNING HUB                    ║
║                 Cost-Optimized AWS Environment               ║
╚═══════════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo -e "${CYAN}$1${NC}"
}

print_option() {
    echo -e "${GREEN}$1${NC} ${BLUE}$2${NC}"
}

print_cost() {
    echo -e "${YELLOW}💰 $1${NC}"
}

show_main_menu() {
    print_section "
🎯 MAIN MENU - Choose Your Learning Path:
"
    print_option "1." "🗄️  Database Cost Optimizer ($0-35/month options)"
    print_option "2." "📊 Current Cost Monitor (check AWS spending)"
    print_option "3." "🚀 Deploy Learning Environment (full setup)"
    print_option "4." "🛠️  Infrastructure Management (Terraform tools)"
    print_option "5." "📈 Resource Dashboard (monitoring tools)"
    print_option "6." "💡 Learning Guides & Documentation"
    print_option "7." "🧪 Quick Development Setup (local testing)"
    print_option "8." "🗄️  Database Query Tools (SQL editors)"
    print_option "9." "🌟 Setup Aurora PostgreSQL (AWS Query Editor)"
    print_option "10." "⚙️  Advanced Configuration"
    echo ""
    print_option "q." "Quit"
    echo ""
}

show_database_menu() {
    print_section "🗄️ DATABASE COST OPTIMIZATION"
    echo ""
    print_cost "Ultra-Budget: $0/month (SQLite)"
    print_cost "Containerized: $1-5/month (PostgreSQL on Fargate)"
    print_cost "Learning RDS: $12-15/month (Managed PostgreSQL)"
    print_cost "Development: $25-35/month (Full RDS features)"
    echo ""
    ./scripts/database-cost-optimizer.sh
}

show_cost_monitor() {
    print_section "📊 COST MONITORING"
    ./scripts/cost-monitor.sh
}

show_deployment_menu() {
    print_section "🚀 DEPLOYMENT OPTIONS"
    echo ""
    print_option "1." "Backend Only (FastAPI + Database)"
    print_option "2." "Frontend Only (Angular app)"
    print_option "3." "Full System (Backend + Frontend + Database)"
    print_option "4." "Minimal Setup (Ultra-budget mode)"
    echo ""
    
    read -p "Choose deployment option (1-4): " deploy_choice
    
    case $deploy_choice in
        1)
            print_section "Deploying Backend..."
            ./scripts/deploy-backend.sh
            ;;
        2)
            print_section "Deploying Frontend..."
            ./scripts/deploy-frontend.sh
            ;;
        3)
            print_section "Deploying Full System..."
            ./scripts/deploy-full-system.sh
            ;;
        4)
            print_section "Setting up Minimal Environment..."
            cd infrastructure
            terraform apply -var-file="database-ultra-budget.tfvars" -auto-approve
            ./scripts/deploy-backend.sh
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

show_infrastructure_menu() {
    print_section "🛠️ INFRASTRUCTURE MANAGEMENT"
    echo ""
    print_option "1." "Deploy Infrastructure (Terraform apply)"
    print_option "2." "Destroy Infrastructure (Terraform destroy)"
    print_option "3." "Plan Changes (Terraform plan)"
    print_option "4." "Show Current State (Terraform show)"
    print_option "5." "Switch to Ultra-Budget Mode"
    print_option "6." "Switch to Learning Mode"
    echo ""
    
    read -p "Choose option (1-6): " infra_choice
    
    case $infra_choice in
        1)
            cd infrastructure && terraform apply
            ;;
        2)
            cd infrastructure && terraform destroy
            ;;
        3)
            cd infrastructure && terraform plan
            ;;
        4)
            cd infrastructure && terraform show
            ;;
        5)
            cd infrastructure && terraform apply -var-file="database-ultra-budget.tfvars" -auto-approve
            ;;
        6)
            cd infrastructure && terraform apply -var-file="database-learning.tfvars" -auto-approve
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

show_dashboard_menu() {
    print_section "📈 MONITORING DASHBOARDS"
    echo ""
    print_option "1." "Web Dashboard (browser-based)"
    print_option "2." "CLI Dashboard (terminal-based)"
    print_option "3." "Python Dashboard (Jupyter notebook)"
    print_option "4." "Cost Monitor (current spending)"
    echo ""
    
    read -p "Choose dashboard (1-4): " dash_choice
    
    case $dash_choice in
        1)
            if [[ -f "dashboard/web-dashboard.py" ]]; then
                cd dashboard && python web-dashboard.py
            else
                echo "Web dashboard not found. Run deployment first."
            fi
            ;;
        2)
            if [[ -f "dashboard/cli-dashboard.py" ]]; then
                python dashboard/cli-dashboard.py
            else
                echo "CLI dashboard not found. Run deployment first."
            fi
            ;;
        3)
            if [[ -f "dashboard/dashboard.ipynb" ]]; then
                echo "Opening Jupyter notebook..."
                code dashboard/dashboard.ipynb
            else
                echo "Jupyter dashboard not found. Run deployment first."
            fi
            ;;
        4)
            ./scripts/cost-monitor.sh
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

show_documentation() {
    print_section "💡 LEARNING GUIDES & DOCUMENTATION"
    echo ""
    print_option "1." "📖 Database Cost Optimization Guide"
    print_option "2." "🚀 Getting Started Guide"
    print_option "3." "📊 Cost Optimization Complete Guide"
    print_option "4." "🏗️  Architecture Overview"
    print_option "5." "🔧 Configuration Files Summary"
    echo ""
    
    read -p "Choose guide (1-5): " doc_choice
    
    case $doc_choice in
        1)
            code docs/DATABASE_COST_OPTIMIZATION.md
            ;;
        2)
            code GETTING_STARTED.md
            ;;
        3)
            code docs/COST_OPTIMIZATION_COMPLETE.md
            ;;
        4)
            code docs/ARCHITECTURE.md
            ;;
        5)
            code docs/CONFIGURATION_FILES_SUMMARY.md
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

show_dev_setup() {
    print_section "🧪 QUICK DEVELOPMENT SETUP"
    echo ""
    print_option "1." "Start Local Development (Docker Compose)"
    print_option "2." "Backend Only (FastAPI development)"
    print_option "3." "Frontend Only (Angular development)"
    print_option "4." "Database Only (PostgreSQL container)"
    echo ""
    
    read -p "Choose development setup (1-4): " dev_choice
    
    case $dev_choice in
        1)
            echo "Starting full development environment..."
            docker-compose up -d
            echo "✅ Environment started:"
            echo "   Backend: http://localhost:8000"
            echo "   Frontend: http://localhost:4200"
            echo "   Database: localhost:5432"
            ;;
        2)
            echo "Starting backend development..."
            cd backend
            uvicorn main:app --reload --host 0.0.0.0 --port 8000
            ;;
        3)
            echo "Starting frontend development..."
            cd frontend/wipsie-app
            npm install
            ng serve --host 0.0.0.0 --port 4200
            ;;
        4)
            echo "Starting database only..."
            docker run -d --name wipsie-db \
                -e POSTGRES_DB=wipsie \
                -e POSTGRES_USER=wipsie \
                -e POSTGRES_PASSWORD=wipsie123 \
                -p 5432:5432 \
                postgres:13
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

show_advanced_config() {
    print_section "⚙️ ADVANCED CONFIGURATION"
    echo ""
    print_option "1." "Edit Terraform Variables"
    print_option "2." "Edit Environment Configuration"
    print_option "3." "Edit Docker Configuration"
    print_option "4." "Edit Application Configuration"
    print_option "5." "View Current Configuration"
    echo ""
    
    read -p "Choose configuration (1-5): " config_choice
    
    case $config_choice in
        1)
            code infrastructure/variables.tf
            ;;
        2)
            code .env
            ;;
        3)
            code docker-compose.yml
            ;;
        4)
            code backend/core/config.py
            ;;
        5)
            print_section "Current Configuration:"
            echo "Terraform variables:"
            cat infrastructure/terraform.tfvars 2>/dev/null || echo "No terraform.tfvars found"
            echo ""
            echo "Environment variables:"
            cat .env 2>/dev/null || echo "No .env found"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

show_query_tools_menu() {
    print_section "🗄️ DATABASE QUERY TOOLS"
    echo ""
    print_section "📋 Your Current Setup: RDS PostgreSQL (db.t3.micro)"
    print_section "⚠️  Note: AWS Query Editor only works with Aurora Serverless"
    echo ""
    print_option "1." "🐘 Install pgAdmin (Web-based PostgreSQL admin)"
    print_option "2." "💻 Setup psql Command Line (PostgreSQL client)"
    print_option "3." "🔧 Install DBeaver (Free GUI database tool)"
    print_option "4." "📱 Setup Adminer (Lightweight web interface)"
    print_option "5." "🌐 Open Connection Guide"
    print_option "6." "🔐 Setup Secure Connection (SSH tunnel)"
    echo ""
    
    read -p "Choose query tool option (1-6): " query_choice
    
    case $query_choice in
        1)
            setup_pgadmin
            ;;
        2)
            setup_psql
            ;;
        3)
            setup_dbeaver
            ;;
        4)
            setup_adminer
            ;;
        5)
            ./scripts/rds-query-access.sh
            ;;
        6)
            setup_ssh_tunnel
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

setup_pgadmin() {
    print_section "🐘 SETTING UP PGADMIN"
    echo ""
    echo "pgAdmin is the most popular PostgreSQL administration tool."
    echo ""
    print_option "1." "Install pgAdmin locally"
    print_option "2." "Run pgAdmin in Docker container"
    echo ""
    
    read -p "Choose installation method (1-2): " pgadmin_choice
    
    case $pgadmin_choice in
        1)
            echo "Installing pgAdmin locally..."
            echo "Visit: https://www.pgadmin.org/download/"
            echo ""
            echo "For Ubuntu/Debian:"
            echo "curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg"
            echo "sudo sh -c 'echo \"deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/\$(lsb_release -cs) pgadmin4 main\" > /etc/apt/sources.list.d/pgadmin4.list'"
            echo "sudo apt update"
            echo "sudo apt install pgadmin4-web"
            ;;
        2)
            echo "Starting pgAdmin in Docker..."
            docker run -d \
                --name pgadmin \
                -p 8080:80 \
                -e PGADMIN_DEFAULT_EMAIL=admin@wipsie.com \
                -e PGADMIN_DEFAULT_PASSWORD=admin123 \
                dpage/pgadmin4
            
            echo "✅ pgAdmin started!"
            echo "🌐 Access: http://localhost:8080"
            echo "📧 Email: admin@wipsie.com"
            echo "🔑 Password: admin123"
            echo ""
            echo "Add your RDS connection:"
            ./scripts/rds-query-access.sh
            ;;
    esac
}

setup_psql() {
    print_section "💻 SETTING UP POSTGRESQL CLIENT (psql)"
    echo ""
    echo "Installing PostgreSQL client tools..."
    
    # Check if already installed
    if command -v psql &> /dev/null; then
        echo "✅ psql is already installed!"
        psql --version
    else
        echo "Installing PostgreSQL client..."
        sudo apt-get update
        sudo apt-get install -y postgresql-client
        echo "✅ PostgreSQL client installed!"
    fi
    
    echo ""
    echo "🔗 Connection command:"
    cd /workspaces/wipsie/infrastructure
    RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null | cut -d':' -f1)
    echo "psql -h $RDS_ENDPOINT -U postgres -d wipsie"
    echo ""
    echo "📝 Sample usage:"
    echo "# Connect to database"
    echo "psql -h $RDS_ENDPOINT -U postgres -d wipsie"
    echo ""
    echo "# Once connected, try these commands:"
    echo "\\dt                    # List tables"
    echo "\\d table_name         # Describe table"
    echo "SELECT version();      # Database version"
    echo "\\q                     # Quit"
}

setup_dbeaver() {
    print_section "🔧 SETTING UP DBEAVER"
    echo ""
    echo "DBeaver is a free, universal database tool."
    echo ""
    print_option "1." "Install DBeaver Community Edition (recommended)"
    print_option "2." "Download manually from website"
    echo ""
    
    read -p "Choose installation method (1-2): " dbeaver_choice
    
    case $dbeaver_choice in
        1)
            echo "Installing DBeaver Community Edition..."
            
            # Check if snap is available
            if command -v snap &> /dev/null; then
                echo "Installing via snap..."
                sudo snap install dbeaver-ce
                echo "✅ DBeaver installed via snap!"
                echo "Launch with: dbeaver-ce"
            elif command -v flatpak &> /dev/null; then
                echo "Installing via flatpak..."
                flatpak install flathub io.dbeaver.DBeaverCommunity
                echo "✅ DBeaver installed via flatpak!"
                echo "Launch with: flatpak run io.dbeaver.DBeaverCommunity"
            else
                echo "Installing via apt..."
                wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | sudo apt-key add -
                echo "deb https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
                sudo apt-get update
                sudo apt-get install dbeaver-ce
                echo "✅ DBeaver installed!"
                echo "Launch with: dbeaver"
            fi
            
            echo ""
            echo "🔗 Connection setup:"
            ./scripts/rds-query-access.sh
            ;;
        2)
            echo "🌐 Visit: https://dbeaver.io/download/"
            echo "Download the Community Edition for your platform"
            ;;
    esac
}

setup_adminer() {
    print_section "📱 SETTING UP ADMINER"
    echo ""
    echo "Adminer is a lightweight, single-file database management tool."
    echo ""
    
    # Create adminer directory
    mkdir -p /tmp/adminer
    cd /tmp/adminer
    
    echo "Downloading Adminer..."
    wget -O adminer.php https://www.adminer.org/latest.php
    
    echo "Starting Adminer with PHP built-in server..."
    php -S localhost:8081 &
    ADMINER_PID=$!
    
    echo "✅ Adminer started!"
    echo "🌐 Access: http://localhost:8081/adminer.php"
    echo ""
    echo "Connection details:"
    cd /workspaces/wipsie/infrastructure
    RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null | cut -d':' -f1)
    echo "System: PostgreSQL"
    echo "Server: $RDS_ENDPOINT"
    echo "Username: postgres"
    echo "Password: [see terraform.tfvars]"
    echo "Database: wipsie"
    echo ""
    echo "Press Ctrl+C to stop Adminer (PID: $ADMINER_PID)"
}

setup_ssh_tunnel() {
    print_section "🔐 SETTING UP SECURE SSH TUNNEL"
    echo ""
    echo "⚠️  Your RDS is in a private subnet - direct connection not allowed"
    echo "You need an EC2 bastion host or Application Load Balancer"
    echo ""
    print_option "1." "Setup EC2 Bastion Host (additional cost ~$5-10/month)"
    print_option "2." "Use existing application as proxy"
    print_option "3." "Modify security groups (less secure)"
    echo ""
    
    read -p "Choose option (1-3): " tunnel_choice
    
    case $tunnel_choice in
        1)
            echo "Setting up EC2 bastion host..."
            echo "This will create a small EC2 instance for secure access"
            echo "Estimated cost: $5-10/month"
            echo ""
            read -p "Continue? (y/N): " -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo ""
                echo "Creating bastion host configuration..."
                # You could add terraform code here for bastion host
                echo "📝 Manual setup required - see AWS documentation for bastion hosts"
            fi
            ;;
        2)
            echo "Using application proxy..."
            echo "You can proxy database queries through your application"
            echo "This is the most cost-effective approach"
            ;;
        3)
            echo "⚠️  Modifying security groups to allow direct access"
            echo "This is less secure but works for learning environments"
            echo ""
            read -p "Get your public IP and update security group? (y/N): " -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo ""
                MY_IP=$(curl -s ifconfig.me)
                echo "Your public IP: $MY_IP"
                echo ""
                echo "Run this AWS CLI command:"
                echo "aws ec2 authorize-security-group-ingress --group-id $(terraform output -raw database_security_group_id) --protocol tcp --port 5432 --cidr $MY_IP/32"
            fi
            ;;
    esac
}
# Main execution
main() {
    while true; do
        clear
        print_banner
        show_main_menu
        
        read -p "Enter your choice (1-10 or q): " choice
        
        case $choice in
            1)
                show_database_menu
                ;;
            2)
                show_cost_monitor
                ;;
            3)
                show_deployment_menu
                ;;
            4)
                show_infrastructure_menu
                ;;
            5)
                show_dashboard_menu
                ;;
            6)
                show_documentation
                ;;
            7)
                show_dev_setup
                ;;
            8)
                show_query_tools_menu
                ;;
            9)
                ./scripts/setup-aurora.sh
                ;;
            10)
                show_advanced_config
                ;;
            q|Q)
                echo -e "${GREEN}Happy learning! 🚀${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Check if running as script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
