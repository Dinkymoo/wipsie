# 🚀 Aurora PostgreSQL for Query Editor - Step by Step

## 🎯 Goal: Enable AWS Query Editor for PostgreSQL

You confirmed that Query Editor shows: *"No databases that support query editor. Currently, query editor only supports Aurora Serverless databases."*

## ⚡ Quick Manual Setup (5 minutes)

### Step 1: Create Aurora Cluster
1. **Open AWS RDS Console**
   - Direct link: https://console.aws.amazon.com/rds/home?region=us-east-1#launch-dbinstance:

2. **Database Creation Method**
   - ✅ Choose "Standard create"

3. **Engine Options**
   - ✅ Select "Aurora (PostgreSQL Compatible)"
   - Engine Version: PostgreSQL 13.7-compatible

4. **Capacity Type** 
   - ✅ Select "Serverless v2" (NOT Provisioned)

5. **Settings**
   ```
   DB cluster identifier: wipsie-learning-aurora
   Master username: postgres
   Master password: [Create strong password]
   ```

6. **Instance Configuration**
   ```
   Serverless v2 scaling configuration:
   - Minimum ACUs: 0.5 (lowest cost)
   - Maximum ACUs: 1.0 (budget control)
   ```

7. **Connectivity**
   ```
   Virtual Private Cloud (VPC): [Select your existing VPC]
   Subnet group: [Select existing subnet group]
   Public access: No
   VPC security groups: [Select existing security group for database]
   ```

8. **🔑 CRITICAL: Additional Configuration**
   - ✅ **Enable "Data API"** checkbox
   - Database name: wipsie
   - Backup retention: 1 day (cost savings)
   - ✅ **Enable "Data API"** (this enables Query Editor!)

### Step 2: Wait for Creation (5-10 minutes)
- Status will show "Creating" → "Available"
- Aurora cluster will appear in RDS dashboard

### Step 3: Access Query Editor
1. **Open Query Editor**
   - Direct link: https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:

2. **Connect to Database**
   - Select your cluster: `wipsie-learning-aurora`
   - Authentication: Use Data API
   - Database: wipsie

3. **Test Query**
   ```sql
   SELECT version();
   SELECT current_timestamp;
   ```

## ✅ Success Indicators

When working correctly:
- ✅ Aurora cluster shows "Available" status
- ✅ Data API shows as "Enabled"
- ✅ Query Editor displays your cluster
- ✅ Can execute SQL queries via web interface

## 💰 Cost Estimate

Aurora Serverless v2 (0.5-1.0 ACUs):
- **Base cost**: ~$15-25/month
- **Auto-scaling**: Scales down when not in use
- **Perfect for**: Learning and development

## 🔧 Terraform Alternative

If the current deployment completes, you'll have Aurora ready automatically!

## 🆘 Troubleshooting

**"No databases that support query editor"**
- Ensure you selected "Serverless v2" (not Provisioned)
- Verify "Data API" is enabled
- Wait for "Available" status
- Refresh Query Editor page

**Data API Not Available**
- Only Aurora Serverless supports Data API
- Regular RDS PostgreSQL does NOT support Query Editor
- Must be Aurora PostgreSQL Serverless v2

---

## 🎉 Next Steps

Once Aurora is ready:
1. Test Query Editor access
2. Run sample queries
3. Connect your application to Aurora endpoint

**Timeline**: 5 minutes setup + 10 minutes creation = Ready in 15 minutes! 🚀
