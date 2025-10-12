#!/bin/bash
# Remove duplicate Aurora cluster - Keep wipsie-learning-aurora, remove wipsie

set -e

echo "🗑️ Aurora Cluster Cleanup Script"
echo "================================"
echo ""
echo "Current clusters (from your screenshot):"
echo "1. wipsie (TO BE DELETED)"
echo "2. wipsie-learning-aurora (KEEPING - has Data API)"
echo ""

# Safety check
read -p "⚠️  Are you sure you want to DELETE the 'wipsie' cluster? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Operation cancelled. No clusters were deleted."
    exit 0
fi

echo ""
echo "🔍 Checking cluster status..."

# Check if clusters exist
CLUSTER_TO_DELETE="wipsie"
CLUSTER_TO_KEEP="wipsie-learning-aurora"

# Verify the cluster we want to delete exists
aws rds describe-db-clusters --db-cluster-identifier "$CLUSTER_TO_DELETE" --query 'DBClusters[0].Status' 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Cluster '$CLUSTER_TO_DELETE' not found. Maybe already deleted?"
    exit 1
fi

# Verify the cluster we want to keep exists
aws rds describe-db-clusters --db-cluster-identifier "$CLUSTER_TO_KEEP" --query 'DBClusters[0].Status' 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Cluster '$CLUSTER_TO_KEEP' not found. Cannot proceed safely."
    exit 1
fi

echo "✅ Both clusters found. Proceeding with deletion of '$CLUSTER_TO_DELETE'..."

# Delete the duplicate cluster
echo "🗑️ Deleting cluster: $CLUSTER_TO_DELETE"
aws rds delete-db-cluster \
    --db-cluster-identifier "$CLUSTER_TO_DELETE" \
    --skip-final-snapshot \
    --delete-automated-backups

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deletion initiated successfully!"
    echo ""
    echo "⏳ Cluster deletion in progress (5-10 minutes)..."
    echo "📊 Remaining cluster: $CLUSTER_TO_KEEP"
    echo "💰 Cost savings: ~$15-30/month"
    echo ""
    echo "🔗 Monitor deletion progress:"
    echo "   https://console.aws.amazon.com/rds/home?region=us-east-1#databases:"
    echo ""
    echo "🎯 After deletion, test Query Editor:"
    echo "   https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:"
else
    echo "❌ Deletion failed. Please try via AWS Console:"
    echo "   https://console.aws.amazon.com/rds/home?region=us-east-1#databases:"
fi
