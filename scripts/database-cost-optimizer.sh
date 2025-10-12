#!/bin/bash
# Database Cost Optimization Manager
# Switch between different database configurations for cost optimization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${PURPLE}=================================${NC}"
    echo -e "${PURPLE}🗄️  DATABASE COST OPTIMIZER${NC}"
    echo -e "${PURPLE}=================================${NC}"
}

print_step() {
    echo -e "${BLUE}🚀 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_database_options() {
    echo ""
    echo "📊 Available Database Configurations:"
    echo ""
    echo "1. 💰 ULTRA-BUDGET (~\$0/month)"
    echo "   • SQLite in containers"
    echo "   • No managed database costs"
    echo "   • Data persists in container only"
    echo ""
    echo "2. 🐳 CONTAINERIZED (~\$1-5/month)"
    echo "   • PostgreSQL in Fargate Spot"
    echo "   • Optional EFS persistence"
    echo "   • Scales to zero when not learning"
    echo ""
    echo "3. 🎓 LEARNING RDS (~\$12-15/month)"
    echo "   • Managed PostgreSQL t3.micro"
    echo "   • Minimal backups and monitoring"
    echo "   • Always-on but cost-optimized"
    echo ""
    echo "4. 🚀 DEVELOPMENT RDS (~\$25-35/month)"
    echo "   • Managed PostgreSQL with features"
    echo "   • Backups and monitoring enabled"
    echo "   • Better for serious development"
    echo ""
    echo "5. 📊 CURRENT STATUS"
    echo "   • Show current database configuration"
    echo ""
}

get_current_status() {
    print_step "Checking current database status..."
    
    cd /workspaces/wipsie/infrastructure
    
    # Check if RDS is enabled
    if terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="aws_db_instance.main[0]") | .values.id' 2>/dev/null | grep -q "db-"; then
        echo "🗄️  Current: RDS PostgreSQL (Managed)"
        
        # Get RDS details
        DB_CLASS=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="aws_db_instance.main[0]") | .values.instance_class' 2>/dev/null || echo "unknown")
        DB_STORAGE=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="aws_db_instance.main[0]") | .values.allocated_storage' 2>/dev/null || echo "unknown")
        DB_MULTI_AZ=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="aws_db_instance.main[0]") | .values.multi_az' 2>/dev/null || echo "unknown")
        
        echo "   Instance: ${DB_CLASS}"
        echo "   Storage: ${DB_STORAGE}GB"
        echo "   Multi-AZ: ${DB_MULTI_AZ}"
        
    elif terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="aws_ecs_service.database_container[0]") | .values.id' 2>/dev/null | grep -q "database"; then
        echo "🐳 Current: Containerized PostgreSQL (Fargate)"
        
        # Check if persistence is enabled
        if terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="aws_efs_file_system.database[0]") | .values.id' 2>/dev/null | grep -q "fs-"; then
            echo "   Persistence: EFS enabled"
        else
            echo "   Persistence: Temporary (no EFS)"
        fi
        
    else
        echo "💾 Current: SQLite or No Database"
        echo "   Cost: $0/month"
        echo "   Note: Data stored in application containers"
    fi
}

estimate_costs() {
    local mode=$1
    
    echo ""
    echo "💰 Estimated Monthly Costs for $mode:"
    
    case $mode in
        "ultra-budget")
            echo "   Database: \$0"
            echo "   Storage: \$0"
            echo "   Total: \$0/month"
            echo "   ⚠️  Note: Data lost when containers restart"
            ;;
        "containerized")
            echo "   Fargate Spot: \$1-3/month (when running)"
            echo "   EFS Storage: \$1-2/month (if persistent)"
            echo "   Total: \$1-5/month"
            echo "   ✅ Can scale to zero when not learning"
            ;;
        "learning")
            echo "   RDS t3.micro: \$12-15/month"
            echo "   Storage (20GB): \$2-3/month"
            echo "   Total: \$12-18/month"
            echo "   ✅ Always available, managed backups"
            ;;
        "development")
            echo "   RDS t3.small: \$25-30/month"
            echo "   Storage (50GB): \$5-6/month"
            echo "   Monitoring: \$2-3/month"
            echo "   Total: \$25-40/month"
            echo "   ✅ Production-like features"
            ;;
    esac
}

switch_to_ultra_budget() {
    print_step "Switching to Ultra-Budget mode (SQLite)..."
    
    print_warning "This will destroy your RDS database if it exists!"
    print_warning "All data will be lost unless you backup first."
    
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        return
    fi
    
    cd /workspaces/wipsie/infrastructure
    
    terraform apply \
        -var-file="database-ultra-budget.tfvars" \
        -auto-approve
    
    print_success "Switched to Ultra-Budget mode"
    estimate_costs "ultra-budget"
}

switch_to_containerized() {
    print_step "Switching to Containerized PostgreSQL..."
    
    read -p "Enable EFS persistence? (adds cost but keeps data) (y/N): " -n 1 -r
    echo
    ENABLE_PERSISTENCE=$([[ $REPLY =~ ^[Yy]$ ]] && echo "true" || echo "false")
    
    cd /workspaces/wipsie/infrastructure
    
    terraform apply \
        -var="enable_database=false" \
        -var="enable_database_container=true" \
        -var="enable_database_persistence=$ENABLE_PERSISTENCE" \
        -auto-approve
    
    print_success "Switched to Containerized PostgreSQL"
    estimate_costs "containerized"
}

switch_to_learning() {
    print_step "Switching to Learning RDS mode..."
    
    cd /workspaces/wipsie/infrastructure
    
    terraform apply \
        -var-file="database-learning.tfvars" \
        -auto-approve
    
    print_success "Switched to Learning RDS mode"
    estimate_costs "learning"
}

switch_to_development() {
    print_step "Switching to Development RDS mode..."
    
    cd /workspaces/wipsie/infrastructure
    
    terraform apply \
        -var="enable_database=true" \
        -var="database_mode=development" \
        -var="database_backup_retention=7" \
        -var="database_performance_insights=true" \
        -var="database_monitoring_interval=60" \
        -auto-approve
    
    print_success "Switched to Development RDS mode"
    estimate_costs "development"
}

backup_current_database() {
    print_step "Creating database backup..."
    
    # Check current database type and create appropriate backup
    cd /workspaces/wipsie/infrastructure
    
    if terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="aws_db_instance.main[0]") | .values.id' 2>/dev/null | grep -q "db-"; then
        DB_IDENTIFIER=$(terraform output -raw rds_endpoint 2>/dev/null | cut -d':' -f1)
        
        print_step "Creating RDS snapshot..."
        SNAPSHOT_ID="manual-backup-$(date +%Y%m%d-%H%M%S)"
        
        aws rds create-db-snapshot \
            --db-instance-identifier "$DB_IDENTIFIER" \
            --db-snapshot-identifier "$SNAPSHOT_ID"
        
        print_success "RDS snapshot created: $SNAPSHOT_ID"
        
    else
        print_warning "No RDS database found - cannot create snapshot"
        print_warning "Consider using application-level backup if using containers"
    fi
}

# Main menu
main_menu() {
    while true; do
        print_banner
        show_database_options
        
        echo "Choose an option:"
        read -p "Enter choice (1-5) or 'q' to quit: " choice
        
        case $choice in
            1)
                switch_to_ultra_budget
                ;;
            2)
                switch_to_containerized
                ;;
            3)
                switch_to_learning
                ;;
            4)
                switch_to_development
                ;;
            5)
                get_current_status
                ;;
            q|Q)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Check if running as script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    clear
    main_menu
fi
