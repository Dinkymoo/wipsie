#!/bin/bash
# AWS Secrets Manager Cleanup Script
# Removes duplicate/unused secrets and recreates necessary ones

set -e

echo "🔐 AWS Secrets Manager Cleanup"
echo "=============================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to list all secrets
list_secrets() {
    print_step "📋 Listing all secrets in AWS Secrets Manager..."
    
    if aws secretsmanager list-secrets --output table 2>/dev/null; then
        echo ""
        return 0
    else
        print_error "Cannot access AWS Secrets Manager via CLI"
        echo ""
        echo "📖 Manual approach:"
        echo "1. Go to: https://console.aws.amazon.com/secretsmanager/listsecrets?region=us-east-1"
        echo "2. Look for secrets related to:"
        echo "   • RDS/Aurora databases"
        echo "   • wipsie project"
        echo "   • Duplicate database credentials"
        echo ""
        return 1
    fi
}

# Function to delete a specific secret
delete_secret() {
    local secret_name="$1"
    local force_delete="$2"
    
    print_step "🗑️ Deleting secret: $secret_name"
    
    if [ "$force_delete" = "true" ]; then
        # Force delete (immediate, cannot be recovered)
        aws secretsmanager delete-secret \
            --secret-id "$secret_name" \
            --force-delete-without-recovery \
            --output text
    else
        # Standard delete (7-day recovery window)
        aws secretsmanager delete-secret \
            --secret-id "$secret_name" \
            --output text
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Secret deleted: $secret_name"
    else
        print_error "Failed to delete secret: $secret_name"
    fi
}

# Function to create Aurora secret
create_aurora_secret() {
    local cluster_id="$1"
    local password="$2"
    
    print_step "🔐 Creating new secret for Aurora cluster: $cluster_id"
    
    SECRET_VALUE=$(cat <<EOF
{
  "username": "postgres",
  "password": "$password",
  "engine": "postgres",
  "host": "$cluster_id.cluster-cq4e8fmhbjpd.us-east-1.rds.amazonaws.com",
  "port": 5432,
  "dbname": "postgres",
  "dbClusterIdentifier": "$cluster_id"
}
EOF
)
    
    aws secretsmanager create-secret \
        --name "wipsie-learning-aurora-credentials" \
        --description "Aurora PostgreSQL credentials for wipsie-learning-aurora cluster" \
        --secret-string "$SECRET_VALUE" \
        --tags Key=Project,Value=wipsie Key=Environment,Value=learning Key=ManagedBy,Value=Script \
        --output table
    
    if [ $? -eq 0 ]; then
        print_success "Aurora secret created successfully"
    else
        print_error "Failed to create Aurora secret"
    fi
}

# Interactive cleanup menu
interactive_cleanup() {
    echo "🤖 Interactive Secrets Cleanup Options:"
    echo "1. List all secrets (identify duplicates)"
    echo "2. Delete all RDS/Aurora related secrets"
    echo "3. Delete specific secret by name"
    echo "4. Create new Aurora secret for wipsie-learning-aurora"
    echo "5. Nuclear option: Delete ALL secrets (careful!)"
    echo "6. Open Secrets Manager console"
    echo "7. Exit"
    echo ""
    
    read -p "Choose option (1-7): " choice
    
    case $choice in
        1)
            list_secrets
            ;;
        2)
            delete_rds_secrets
            ;;
        3)
            delete_specific_secret
            ;;
        4)
            create_new_aurora_secret
            ;;
        5)
            nuclear_delete_all
            ;;
        6)
            echo "🔗 Opening Secrets Manager console..."
            echo "https://console.aws.amazon.com/secretsmanager/listsecrets?region=us-east-1"
            ;;
        7)
            echo "👋 Exiting"
            exit 0
            ;;
        *)
            print_error "Invalid option"
            interactive_cleanup
            ;;
    esac
}

# Delete RDS/Aurora related secrets
delete_rds_secrets() {
    print_warning "About to delete RDS/Aurora related secrets"
    
    # Common patterns for RDS secrets
    PATTERNS=(
        "rds-db-credentials"
        "aurora"
        "wipsie.*rds"
        "wipsie.*db"
        "postgres"
        "database"
    )
    
    echo "Will search for secrets matching these patterns:"
    for pattern in "${PATTERNS[@]}"; do
        echo "  • $pattern"
    done
    echo ""
    
    read -p "Continue with RDS secret deletion? (type 'yes'): " confirm
    
    if [ "$confirm" = "yes" ]; then
        for pattern in "${PATTERNS[@]}"; do
            # This would need to be implemented with actual secret names
            echo "🔍 Searching for secrets matching: $pattern"
            # aws secretsmanager list-secrets --query "SecretList[?contains(Name, '$pattern')].Name" --output text
        done
        
        print_warning "Use manual console approach for precise control"
        echo "https://console.aws.amazon.com/secretsmanager/listsecrets?region=us-east-1"
    else
        echo "❌ RDS secret deletion cancelled"
    fi
}

# Delete specific secret
delete_specific_secret() {
    echo ""
    read -p "Enter the exact secret name to delete: " secret_name
    
    if [ -z "$secret_name" ]; then
        print_error "No secret name provided"
        return
    fi
    
    echo ""
    print_warning "About to delete secret: $secret_name"
    read -p "Are you sure? (type 'yes'): " confirm
    
    if [ "$confirm" = "yes" ]; then
        read -p "Force delete (immediate, no recovery)? (y/n): " force
        
        if [ "$force" = "y" ]; then
            delete_secret "$secret_name" "true"
        else
            delete_secret "$secret_name" "false"
        fi
    else
        echo "❌ Secret deletion cancelled"
    fi
}

# Create new Aurora secret
create_new_aurora_secret() {
    echo ""
    print_step "Creating secret for wipsie-learning-aurora cluster"
    
    read -p "Enter Aurora password (or press Enter for WipsieAurora2024!): " password
    password=${password:-"WipsieAurora2024!"}
    
    create_aurora_secret "wipsie-learning-aurora" "$password"
}

# Nuclear option - delete ALL secrets
nuclear_delete_all() {
    print_error "⚠️  NUCLEAR OPTION: DELETE ALL SECRETS"
    echo ""
    echo "This will delete ALL secrets in your AWS account!"
    echo "This action cannot be easily undone!"
    echo ""
    
    read -p "Type 'NUCLEAR DELETE' to confirm: " confirm
    
    if [ "$confirm" = "NUCLEAR DELETE" ]; then
        print_warning "Proceeding with nuclear deletion..."
        
        # Get all secret names and delete them
        SECRET_NAMES=$(aws secretsmanager list-secrets --query 'SecretList[*].Name' --output text 2>/dev/null)
        
        if [ -n "$SECRET_NAMES" ]; then
            for secret in $SECRET_NAMES; do
                print_step "Deleting: $secret"
                delete_secret "$secret" "true"
            done
            
            print_success "All secrets deleted"
        else
            print_error "Could not retrieve secret list"
        fi
    else
        print_success "Nuclear deletion cancelled - good choice!"
    fi
}

# Main execution
main() {
    echo "🎯 Current situation:"
    echo "• Aurora cluster 'wipsie' deleted ✅"
    echo "• Keeping 'wipsie-learning-aurora' ✅"
    echo "• Need to clean up duplicate secrets 🧹"
    echo ""
    
    if ! list_secrets; then
        echo "🔗 **Manual Cleanup via Console:**"
        echo "https://console.aws.amazon.com/secretsmanager/listsecrets?region=us-east-1"
        echo ""
        echo "Look for and delete:"
        echo "• Secrets for the deleted 'wipsie' cluster"
        echo "• Any duplicate Aurora credentials"
        echo "• Old RDS-related secrets"
        echo ""
        echo "Keep secrets for:"
        echo "• wipsie-learning-aurora cluster"
        echo "• Any application-specific secrets you need"
        echo ""
    fi
    
    interactive_cleanup
}

# Run main function
main
