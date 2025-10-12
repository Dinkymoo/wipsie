#!/bin/bash
# Quick cost monitoring script
# Shows current AWS costs and database configuration

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}=====================================
💰 WIPSIE COST MONITOR
=====================================${NC}"
}

print_section() {
    echo -e "${BLUE}$1${NC}"
}

get_current_costs() {
    print_section "📊 Current Month AWS Costs"
    
    START_DATE=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d)
    END_DATE=$(date +%Y-%m-%d)
    
    # Get total costs
    echo "Fetching costs from $START_DATE to $END_DATE..."
    
    TOTAL_COST=$(aws ce get-cost-and-usage \
        --time-period Start=$START_DATE,End=$END_DATE \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
        --output text 2>/dev/null || echo "0")
    
    echo "Total Month-to-Date: \$$(printf "%.2f" $TOTAL_COST)"
    
    # Get costs by service
    echo ""
    echo "Costs by Service:"
    aws ce get-cost-and-usage \
        --time-period Start=$START_DATE,End=$END_DATE \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --query 'ResultsByTime[0].Groups[?Total.BlendedCost.Amount>`0.01`].[Keys[0],Total.BlendedCost.Amount]' \
        --output table 2>/dev/null || echo "Unable to fetch service breakdown"
}

get_database_status() {
    print_section "🗄️ Database Configuration"
    
    cd /workspaces/wipsie/infrastructure 2>/dev/null || {
        echo "❌ Infrastructure directory not found"
        return
    }
    
    # Check if Terraform state exists
    if [[ ! -f terraform.tfstate ]]; then
        echo "⚠️  No Terraform state found - infrastructure may not be deployed"
        return
    fi
    
    # Check RDS instances
    RDS_COUNT=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | select(.type=="aws_db_instance") | .address' | wc -l || echo "0")
    
    if [[ $RDS_COUNT -gt 0 ]]; then
        echo "🗄️  RDS Database: ACTIVE"
        
        DB_CLASS=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | select(.type=="aws_db_instance") | .values.instance_class' | head -1)
        DB_STORAGE=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | select(.type=="aws_db_instance") | .values.allocated_storage' | head -1)
        
        echo "   Instance: $DB_CLASS"
        echo "   Storage: ${DB_STORAGE}GB"
        
        # Estimate RDS costs
        case $DB_CLASS in
            "db.t3.micro")
                echo "   Estimated Cost: \$12-15/month"
                ;;
            "db.t3.small")
                echo "   Estimated Cost: \$25-30/month"
                ;;
            *)
                echo "   Estimated Cost: Check AWS calculator"
                ;;
        esac
    else
        echo "🗄️  RDS Database: NOT ACTIVE"
    fi
    
    # Check containerized database
    ECS_DB_COUNT=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | select(.type=="aws_ecs_service" and (.address | contains("database"))) | .address' | wc -l || echo "0")
    
    if [[ $ECS_DB_COUNT -gt 0 ]]; then
        echo "🐳 Containerized DB: ACTIVE"
        echo "   Estimated Cost: \$1-5/month"
    else
        echo "🐳 Containerized DB: NOT ACTIVE"
    fi
    
    # Check if using SQLite (no external database)
    if [[ $RDS_COUNT -eq 0 && $ECS_DB_COUNT -eq 0 ]]; then
        echo "💾 Database Mode: SQLite (Ultra-Budget)"
        echo "   Cost: \$0/month"
    fi
}

get_fargate_status() {
    print_section "🚀 Fargate Services"
    
    cd /workspaces/wipsie/infrastructure 2>/dev/null || return
    
    FARGATE_SERVICES=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | select(.type=="aws_ecs_service") | .address' | wc -l || echo "0")
    
    if [[ $FARGATE_SERVICES -gt 0 ]]; then
        echo "Active Services: $FARGATE_SERVICES"
        
        # List services
        terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | select(.type=="aws_ecs_service") | "   " + .values.name' || echo "   Unable to list services"
        
        echo "   Estimated Cost: \$5-15/month (with Spot pricing)"
    else
        echo "No Fargate services active"
    fi
}

show_optimization_tips() {
    print_section "💡 Cost Optimization Tips"
    
    echo "1. 🗄️  Database Optimization:"
    echo "   • Ultra-Budget: Use SQLite (\$0/month)"
    echo "   • Learning: Use containerized PostgreSQL (\$1-5/month)"
    echo "   • Production: Use minimal RDS (\$12-15/month)"
    echo ""
    echo "2. 🚀 Compute Optimization:"
    echo "   • Use Fargate Spot pricing (70% savings)"
    echo "   • Scale services to zero when not learning"
    echo "   • Use smallest instance sizes for learning"
    echo ""
    echo "3. 🔧 Quick Actions:"
    echo "   • Run: ./scripts/database-cost-optimizer.sh"
    echo "   • Stop all: ./scripts/stop-all-services.sh"
    echo "   • Start learning: ./scripts/start-learning-environment.sh"
}

show_quick_commands() {
    print_section "⚡ Quick Commands"
    
    echo "Database Management:"
    echo "  ./scripts/database-cost-optimizer.sh    # Switch database modes"
    echo ""
    echo "Service Management:"
    echo "  aws ecs update-service --cluster wipsie-cluster --service backend --desired-count 0  # Stop backend"
    echo "  aws ecs update-service --cluster wipsie-cluster --service backend --desired-count 1  # Start backend"
    echo ""
    echo "Cost Monitoring:"
    echo "  aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost"
}

# Main execution
main() {
    print_header
    echo ""
    
    get_current_costs
    echo ""
    
    get_database_status
    echo ""
    
    get_fargate_status
    echo ""
    
    show_optimization_tips
    echo ""
    
    show_quick_commands
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
