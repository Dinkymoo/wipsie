# 🎯 Aurora PostgreSQL + Query Editor Solution

## 🚨 Current Issue
The AWS Query Editor message confirms:
> "Currently, query editor only supports Aurora Serverless databases. Only Aurora Serverless database that you have access to will be displayed."

## ✅ Solution: Create Aurora PostgreSQL Serverless

### 🔧 Quick Manual Creation (Fastest)

1. **Go to RDS Console**
   - Visit: https://console.aws.amazon.com/rds/home?region=us-east-1#databases:

2. **Create Aurora Cluster**
   ```
   ✅ Click "Create database"
   ✅ Choose "Aurora (MySQL compatible)" or "Aurora (PostgreSQL compatible)"
   ✅ Select "Aurora PostgreSQL"
   ✅ Choose "Serverless v2" 
   ✅ Enable "Data API" checkbox ⚠️ CRITICAL for Query Editor
   ```

3. **Configuration Settings**
   ```
   - Cluster identifier: wipsie-learning-aurora
   - Master username: postgres
   - Master password: [generate secure password]
   - Database name: wipsie
   - VPC: wipsie-vpc-staging (or current VPC)
   - Security groups: wipsie-rds-sg-staging
   ```

4. **Serverless v2 Scaling**
   ```
   - Minimum ACUs: 0.5 (cheapest option)
   - Maximum ACUs: 1.0 (budget-friendly)
   - Estimated cost: ~$15-30/month
   ```

5. **⚠️ CRITICAL: Enable Data API**
   ```
   Under "Additional configuration":
   ✅ Check "Enable Data API"
   ```

### 🎯 After Creation

1. **Access Query Editor**
   - URL: https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:
   - Select your Aurora cluster: `wipsie-learning-aurora`
   - Use Data API authentication

2. **Verify Data API is Enabled**
   ```bash
   aws rds describe-db-clusters \
     --db-cluster-identifier wipsie-learning-aurora \
     --query 'DBClusters[0].HttpEndpointEnabled'
   ```
   Should return: `true`

## 🛠️ Alternative: Terraform Deployment

If you prefer Infrastructure as Code:

```bash
cd /workspaces/wipsie/infrastructure
terraform apply -var-file="aurora-serverless.tfvars" -auto-approve
```

This will create the Aurora cluster with Data API enabled.

## 🔍 Troubleshooting

### "No databases that support query editor"
- ✅ Ensure Aurora Serverless v2 (not regular Aurora)
- ✅ Verify Data API is enabled
- ✅ Check region (us-east-1)
- ✅ Wait 5-10 minutes after cluster creation

### Query Editor Access
- Aurora cluster must be "Available" status
- Data API must be enabled (`HttpEndpointEnabled: true`)
- User must have RDS permissions

## 🎉 Success Criteria

When successful, you'll see:
- ✅ Aurora cluster in "Available" status
- ✅ Data API enabled
- ✅ Query Editor shows your database
- ✅ Can run SQL queries via web interface

## 💰 Cost Optimization

Aurora Serverless v2 with minimal configuration:
- **Minimum cost**: ~$15-20/month (0.5 ACU minimum)
- **Auto-scaling**: Scales down when not in use
- **No idle costs**: Perfect for learning/development

## 🔗 Direct Links

- **Create Aurora**: https://console.aws.amazon.com/rds/home?region=us-east-1#launch-dbinstance:
- **Query Editor**: https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:
- **RDS Dashboard**: https://console.aws.amazon.com/rds/home?region=us-east-1#databases:

---

**Next Step**: Create Aurora Serverless v2 with Data API enabled, then access Query Editor! 🚀
