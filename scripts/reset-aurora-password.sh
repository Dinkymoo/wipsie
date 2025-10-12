#!/bin/bash
# Reset Aurora Master Password for wipsie-learning-aurora

set -e

echo "🔐 Resetting Aurora master password for wipsie-learning-aurora..."

# Set a new password we know
NEW_PASSWORD="WipsieAurora2024!"
CLUSTER_ID="wipsie-learning-aurora"

echo "📝 Setting new master password for cluster: $CLUSTER_ID"

# Reset the master password
aws rds modify-db-cluster \
    --db-cluster-identifier "$CLUSTER_ID" \
    --master-user-password "$NEW_PASSWORD" \
    --apply-immediately \
    --output table

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Password reset successful!"
    echo ""
    echo "🔐 New connection details:"
    echo "   Cluster: $CLUSTER_ID"
    echo "   Username: postgres"
    echo "   Password: $NEW_PASSWORD"
    echo ""
    echo "⚠️  Please wait 2-3 minutes for the change to take effect."
    echo ""
    echo "🔗 Then test in Query Editor:"
    echo "   https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:"
    echo ""
    echo "💾 Save this password securely!"
else
    echo "❌ Password reset failed. Please try resetting via AWS Console:"
    echo "   https://console.aws.amazon.com/rds/home?region=us-east-1#database:id=wipsie-learning-aurora;is-cluster=true"
fi
