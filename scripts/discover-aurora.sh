#!/bin/bash
# Aurora Discovery and Deployment Script
# Finds existing Aurora clusters or guides you to create one

set -e

echo "🔍 Aurora PostgreSQL Discovery & Setup"
echo "======================================"

# Check AWS CLI access
echo "1. Testing AWS CLI access..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run: aws configure"
    exit 1
fi

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")
echo "✅ AWS Access OK - Account: $ACCOUNT, Region: $REGION"
echo ""

# Check for Aurora clusters
echo "2. Scanning for Aurora clusters..."
AURORA_CLUSTERS=$(aws rds describe-db-clusters --query 'DBClusters[*]' --output json 2>/dev/null || echo "[]")
CLUSTER_COUNT=$(echo "$AURORA_CLUSTERS" | jq length 2>/dev/null || echo "0")

if [ "$CLUSTER_COUNT" -gt 0 ]; then
    echo "✅ Found $CLUSTER_COUNT Aurora cluster(s):"
    echo "$AURORA_CLUSTERS" | jq -r '.[] | "  📊 \(.DBClusterIdentifier) (\(.Engine)) - \(.Status) - Data API: \(.HttpEndpointEnabled // false)"'
    echo ""
    
    # Check for Query Editor compatible clusters
    DATA_API_CLUSTERS=$(echo "$AURORA_CLUSTERS" | jq -r '.[] | select(.HttpEndpointEnabled == true) | .DBClusterIdentifier')
    if [ -n "$DATA_API_CLUSTERS" ]; then
        echo "🎯 Query Editor compatible clusters (Data API enabled):"
        echo "$DATA_API_CLUSTERS" | while read cluster; do
            echo "  ✅ $cluster"
        done
        echo ""
        
        # Get the first compatible cluster
        FIRST_CLUSTER=$(echo "$DATA_API_CLUSTERS" | head -n1)
        CLUSTER_ENDPOINT=$(echo "$AURORA_CLUSTERS" | jq -r ".[] | select(.DBClusterIdentifier == \"$FIRST_CLUSTER\") | .Endpoint")
        
        echo "🚀 Using cluster: $FIRST_CLUSTER"
        echo "📍 Endpoint: $CLUSTER_ENDPOINT"
        echo ""
        
        # Export for deployment
        export AURORA_ENDPOINT="$CLUSTER_ENDPOINT"
        export CLUSTER_NAME="$FIRST_CLUSTER"
        
        # Ask for password
        if [ -z "$DB_PASSWORD" ]; then
            echo "Please set the DB_PASSWORD environment variable for cluster '$FIRST_CLUSTER':"
            echo "export DB_PASSWORD='your-cluster-password'"
            echo ""
            echo "Then run this script again: ./scripts/discover-aurora.sh"
            exit 0
        fi
        
        echo "✅ Password provided, proceeding with deployment..."
        exec ./scripts/deploy-aurora-db.sh
        
    else
        echo "⚠️  Found Aurora clusters but none have Data API enabled (required for Query Editor)"
        echo "$AURORA_CLUSTERS" | jq -r '.[] | "  📊 \(.DBClusterIdentifier) - Data API: \(.HttpEndpointEnabled // false)"'
        echo ""
        echo "🔧 To enable Query Editor, you need Aurora Serverless with Data API enabled"
    fi
else
    echo "❌ No Aurora clusters found"
fi

# Check for regular RDS instances
echo "3. Checking for regular RDS instances..."
RDS_INSTANCES=$(aws rds describe-db-instances --query 'DBInstances[*]' --output json 2>/dev/null || echo "[]")
INSTANCE_COUNT=$(echo "$RDS_INSTANCES" | jq length 2>/dev/null || echo "0")

if [ "$INSTANCE_COUNT" -gt 0 ]; then
    echo "📋 Found $INSTANCE_COUNT RDS instance(s):"
    echo "$RDS_INSTANCES" | jq -r '.[] | "  📊 \(.DBInstanceIdentifier) (\(.Engine)) - \(.DBInstanceStatus)"'
    echo ""
    echo "⚠️  Note: Regular RDS instances do NOT support AWS Query Editor"
    echo "   Query Editor requires Aurora Serverless with Data API"
else
    echo "❌ No RDS instances found"
fi

echo ""
echo "🎯 Next Steps:"
echo "=============="

if [ "$CLUSTER_COUNT" -eq 0 ]; then
    echo "1. 🏗️  Create Aurora PostgreSQL Serverless cluster:"
    echo "   Option A (Terraform): cd infrastructure && terraform apply -var-file='aurora-serverless.tfvars'"
    echo "   Option B (Manual): https://console.aws.amazon.com/rds/home?region=$REGION#launch-dbinstance:"
    echo ""
    echo "2. ✅ Ensure these settings:"
    echo "   - Engine: Aurora PostgreSQL"
    echo "   - Capacity: Serverless v2"
    echo "   - Data API: ENABLED (critical for Query Editor)"
    echo ""
    echo "3. 🚀 Then run: ./scripts/discover-aurora.sh"
else
    COMPATIBLE_COUNT=$(echo "$AURORA_CLUSTERS" | jq '[.[] | select(.HttpEndpointEnabled == true)] | length')
    if [ "$COMPATIBLE_COUNT" -eq 0 ]; then
        echo "1. 🔧 Enable Data API on existing cluster, or"
        echo "2. 🏗️  Create new Aurora Serverless cluster with Data API enabled"
        echo "3. 🚀 Then run: ./scripts/discover-aurora.sh"
    else
        echo "1. ✅ You have Query Editor compatible Aurora cluster(s)!"
        echo "2. 🔑 Set DB_PASSWORD environment variable"
        echo "3. 🚀 Run: ./scripts/discover-aurora.sh"
    fi
fi

echo ""
echo "🔗 Useful Links:"
echo "   Query Editor: https://console.aws.amazon.com/rds/home?region=$REGION#query-editor:"
echo "   RDS Console: https://console.aws.amazon.com/rds/home?region=$REGION#databases:"
