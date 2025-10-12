#!/bin/bash
# Enable deletion protection removal for Aurora clusters

set -e

echo "🔓 Aurora Cluster Deletion Protection Manager"
echo "============================================="
echo ""

# List all Aurora clusters with their deletion protection status
echo "📋 Checking Aurora clusters and deletion protection..."

# Check via AWS CLI (if working)
if aws rds describe-db-clusters --query 'DBClusters[*].{Identifier:DBClusterIdentifier,DeletionProtection:DeletionProtection}' --output table 2>/dev/null; then
    echo ""
else
    echo "❌ AWS CLI not accessible. Using manual instructions below."
    echo ""
fi

echo "🔧 To enable deletion for Aurora clusters:"
echo ""
echo "**Method 1: AWS Console (Recommended)**"
echo "1. Go to: https://console.aws.amazon.com/rds/home?region=us-east-1#databases:"
echo "2. Click on cluster: 'wipsie' (the one you want to delete)"
echo "3. Click 'Modify' button"
echo "4. Scroll to 'Deletion protection'"
echo "5. UNCHECK 'Enable deletion protection'"
echo "6. Click 'Continue' → 'Apply immediately' → 'Modify DB cluster'"
echo "7. Wait 2-3 minutes for change to apply"
echo "8. Then you can delete the cluster"
echo ""

echo "**Method 2: AWS CLI (if working)**"
echo "# Disable deletion protection on 'wipsie' cluster"
echo "aws rds modify-db-cluster \\"
echo "    --db-cluster-identifier wipsie \\"
echo "    --no-deletion-protection \\"
echo "    --apply-immediately"
echo ""
echo "# Then delete the cluster"
echo "aws rds delete-db-cluster \\"
echo "    --db-cluster-identifier wipsie \\"
echo "    --skip-final-snapshot \\"
echo "    --delete-automated-backups"
echo ""

echo "🎯 **Recommended Action:**"
echo "Remove the 'wipsie' cluster (keep 'wipsie-learning-aurora')"
echo ""
echo "✅ **Why remove 'wipsie':**"
echo "• wipsie-learning-aurora has Data API enabled (Query Editor ready)"
echo "• Saves ~\$15-30/month by removing duplicate"
echo "• Eliminates confusion about which cluster to use"
echo ""

echo "⚠️  **IMPORTANT: Double-check cluster names**"
echo "DELETE: 'wipsie' (original cluster)"
echo "KEEP: 'wipsie-learning-aurora' (our new cluster with Data API)"
echo ""

echo "🔗 **Quick Links:**"
echo "• RDS Console: https://console.aws.amazon.com/rds/home?region=us-east-1#databases:"
echo "• Query Editor (after cleanup): https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:"

# Function to disable deletion protection via CLI
disable_deletion_protection() {
    local cluster_id="$1"
    
    echo "🔓 Disabling deletion protection for: $cluster_id"
    
    aws rds modify-db-cluster \
        --db-cluster-identifier "$cluster_id" \
        --no-deletion-protection \
        --apply-immediately \
        --output table
    
    if [ $? -eq 0 ]; then
        echo "✅ Deletion protection disabled for $cluster_id"
        echo "⏳ Wait 2-3 minutes, then you can delete the cluster"
    else
        echo "❌ Failed to disable deletion protection"
        echo "Try using the AWS Console method above"
    fi
}

# Interactive mode
echo ""
echo "🤖 **Interactive Options:**"
echo "1. Disable deletion protection for 'wipsie' cluster"
echo "2. Show manual instructions only"
echo "3. Exit"
echo ""

read -p "Choose option (1-3): " choice

case $choice in
    1)
        echo ""
        echo "⚠️  About to disable deletion protection for 'wipsie' cluster"
        read -p "Are you sure? (type 'yes'): " confirm
        
        if [ "$confirm" = "yes" ]; then
            disable_deletion_protection "wipsie"
        else
            echo "❌ Operation cancelled"
        fi
        ;;
    2)
        echo "✅ Manual instructions shown above"
        ;;
    3)
        echo "👋 Exiting"
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        ;;
esac
