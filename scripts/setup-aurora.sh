#!/bin/bash
# Aurora PostgreSQL Deployment Script
# Enables AWS Query Editor functionality

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

print_banner() {
    echo -e "${PURPLE}
╔═══════════════════════════════════════════════════════════════╗
║               🌟 AURORA POSTGRESQL SETUP                     ║
║              Enable AWS Query Editor Access                  ║
╚═══════════════════════════════════════════════════════════════╝${NC}"
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

show_aurora_options() {
    echo ""
    echo "🎯 Aurora PostgreSQL Setup Options:"
    echo ""
    echo "1. 💰 Aurora + Keep RDS (~$25-30/month)"
    echo "   • Keep existing RDS for comparison"
    echo "   • Add Aurora for Query Editor access"
    echo "   • Learn differences between RDS and Aurora"
    echo ""
    echo "2. 🚀 Aurora Serverless Only (~$15-20/month)"
    echo "   • Replace RDS with Aurora Serverless v2"
    echo "   • Auto-scaling, cost-optimized"
    echo "   • AWS Query Editor enabled"
    echo ""
    echo "3. 🏢 Production Aurora (~$30-45/month)"
    echo "   • Full Aurora cluster with high availability"
    echo "   • Performance insights enabled"
    echo "   • Production-grade setup"
    echo ""
    echo "4. 📊 Current Status"
    echo "   • Check current Aurora deployment"
    echo ""
}

deploy_aurora_learning() {
    print_step "Deploying Aurora + RDS Learning Environment..."
    
    print_warning "This will add Aurora alongside your existing RDS"
    print_warning "Estimated additional cost: ~$10-15/month"
    
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        return
    fi
    
    cd /workspaces/wipsie/infrastructure
    
    print_step "Planning Aurora deployment..."
    terraform plan -var-file="aurora-learning.tfvars"
    
    read -p "Apply this plan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply -var-file="aurora-learning.tfvars" -auto-approve
        
        print_success "Aurora PostgreSQL deployed!"
        show_connection_info
    fi
}

deploy_aurora_serverless() {
    print_step "Deploying Aurora Serverless v2 (replaces RDS)..."
    
    print_warning "This will DISABLE your existing RDS database"
    print_warning "All RDS data will be lost unless you backup first"
    print_warning "Estimated cost: ~$15-20/month"
    
    read -p "Backup current RDS data first? (recommended) (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_rds_data
    fi
    
    read -p "Continue with Aurora Serverless deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        return
    fi
    
    cd /workspaces/wipsie/infrastructure
    
    print_step "Planning Aurora Serverless deployment..."
    terraform plan -var-file="aurora-serverless.tfvars"
    
    read -p "Apply this plan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply -var-file="aurora-serverless.tfvars" -auto-approve
        
        print_success "Aurora Serverless v2 deployed!"
        show_connection_info
    fi
}

deploy_aurora_production() {
    print_step "Deploying Production Aurora Cluster..."
    
    print_warning "This is a more expensive setup (~$30-45/month)"
    
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        return
    fi
    
    cd /workspaces/wipsie/infrastructure
    
    terraform apply \
        -var="enable_aurora=true" \
        -var="aurora_serverless_v2=false" \
        -var="aurora_instance_class=db.r5.large" \
        -var="database_performance_insights=true" \
        -var="database_monitoring_interval=60" \
        -auto-approve
    
    print_success "Production Aurora deployed!"
    show_connection_info
}

backup_rds_data() {
    print_step "Creating RDS backup snapshot..."
    
    cd /workspaces/wipsie/infrastructure
    
    # Get RDS identifier if it exists
    if terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="aws_db_instance.main[0]") | .values.id' 2>/dev/null | grep -q "db-"; then
        RDS_ID=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="aws_db_instance.main[0]") | .values.id' 2>/dev/null)
        SNAPSHOT_ID="pre-aurora-migration-$(date +%Y%m%d-%H%M%S)"
        
        print_step "Creating snapshot: $SNAPSHOT_ID"
        aws rds create-db-snapshot \
            --db-instance-identifier "$RDS_ID" \
            --db-snapshot-identifier "$SNAPSHOT_ID"
        
        print_success "Backup snapshot created: $SNAPSHOT_ID"
    else
        print_warning "No RDS instance found to backup"
    fi
}

show_connection_info() {
    print_step "Getting Aurora connection information..."
    
    cd /workspaces/wipsie/infrastructure
    
    if terraform output aurora_cluster_identifier >/dev/null 2>&1; then
        echo ""
        echo "🌟 AURORA POSTGRESQL CONNECTION INFO:"
        echo "======================================"
        
        CLUSTER_ID=$(terraform output -raw aurora_cluster_identifier 2>/dev/null || echo "Not available")
        ENDPOINT=$(terraform output -raw aurora_cluster_endpoint 2>/dev/null || echo "Not available")
        DB_NAME=$(terraform output -raw aurora_database_name 2>/dev/null || echo "wipsie")
        QUERY_EDITOR_URL=$(terraform output -raw aurora_query_editor_url 2>/dev/null || echo "Not available")
        
        echo "🆔 Cluster ID: $CLUSTER_ID"
        echo "🌐 Endpoint: $ENDPOINT"
        echo "🗄️  Database: $DB_NAME"
        echo "👤 Username: postgres"
        echo "🔑 Password: [same as terraform.tfvars]"
        echo ""
        echo "🎯 AWS QUERY EDITOR ACCESS:"
        echo "============================"
        echo "🌐 URL: $QUERY_EDITOR_URL"
        echo ""
        echo "📋 STEPS TO ACCESS QUERY EDITOR:"
        echo "1. Open the URL above"
        echo "2. Select cluster: $CLUSTER_ID"
        echo "3. Choose 'Connect with database credentials'"
        echo "4. Enter username: postgres"
        echo "5. Enter password from terraform.tfvars"
        echo "6. Select database: $DB_NAME"
        echo "7. Start querying! 🎉"
        echo ""
        
        # Check if Data API is enabled
        print_step "Verifying Data API status..."
        DATA_API_STATUS=$(aws rds describe-db-clusters \
            --db-cluster-identifier "$CLUSTER_ID" \
            --query 'DBClusters[0].HttpEndpointEnabled' \
            --output text 2>/dev/null || echo "false")
        
        if [[ "$DATA_API_STATUS" == "true" ]]; then
            print_success "Data API is enabled - Query Editor ready!"
        else
            print_warning "Data API not enabled yet. Enabling now..."
            aws rds modify-db-cluster \
                --db-cluster-identifier "$CLUSTER_ID" \
                --enable-http-endpoint \
                --apply-immediately
            print_success "Data API enabled!"
        fi
        
    else
        print_error "Aurora cluster not found. Deployment may have failed."
    fi
}

check_aurora_status() {
    print_step "Checking current Aurora status..."
    
    cd /workspaces/wipsie/infrastructure
    
    if terraform output aurora_cluster_identifier >/dev/null 2>&1; then
        CLUSTER_ID=$(terraform output -raw aurora_cluster_identifier)
        
        echo "✅ Aurora cluster found: $CLUSTER_ID"
        
        # Get cluster status
        STATUS=$(aws rds describe-db-clusters \
            --db-cluster-identifier "$CLUSTER_ID" \
            --query 'DBClusters[0].Status' \
            --output text 2>/dev/null || echo "unknown")
        
        echo "📊 Status: $STATUS"
        
        # Check Data API
        DATA_API=$(aws rds describe-db-clusters \
            --db-cluster-identifier "$CLUSTER_ID" \
            --query 'DBClusters[0].HttpEndpointEnabled' \
            --output text 2>/dev/null || echo "false")
        
        if [[ "$DATA_API" == "true" ]]; then
            echo "🎯 Query Editor: ✅ Available"
            echo "🌐 Access: $(terraform output -raw aurora_query_editor_url)"
        else
            echo "🎯 Query Editor: ❌ Data API not enabled"
        fi
        
        # Show cost estimate
        ENGINE_MODE=$(aws rds describe-db-clusters \
            --db-cluster-identifier "$CLUSTER_ID" \
            --query 'DBClusters[0].EngineMode' \
            --output text 2>/dev/null || echo "unknown")
        
        if [[ "$ENGINE_MODE" == "serverless" ]]; then
            echo "💰 Estimated cost: $15-20/month (Serverless v2)"
        else
            echo "💰 Estimated cost: $25-35/month (Provisioned)"
        fi
        
    else
        echo "❌ No Aurora cluster deployed"
        echo "💡 Run option 1 or 2 to deploy Aurora with Query Editor support"
    fi
}

# Main menu
main_menu() {
    while true; do
        print_banner
        show_aurora_options
        
        echo "Choose an option:"
        read -p "Enter choice (1-4) or 'q' to quit: " choice
        
        case $choice in
            1)
                deploy_aurora_learning
                ;;
            2)
                deploy_aurora_serverless
                ;;
            3)
                deploy_aurora_production
                ;;
            4)
                check_aurora_status
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
