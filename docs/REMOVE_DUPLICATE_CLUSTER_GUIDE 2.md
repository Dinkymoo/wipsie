# 🗑️ Remove Duplicate Aurora Cluster Guide

## 🎯 Current Situation
You have **2 Aurora PostgreSQL clusters**:
1. **`wipsie`** - The original cluster (may not have Data API)
2. **`wipsie-learning-aurora`** - Our new cluster (✅ Data API enabled)

## 💡 Recommendation: Keep `wipsie-learning-aurora`
- ✅ Has Data API enabled (confirmed)
- ✅ Ready for Query Editor  
- ✅ Serverless v2 optimized
- ✅ We have all deployment scripts for it

## 🗑️ Remove the `wipsie` cluster

### **Step 1: Check if `wipsie` cluster has any important data**

In the RDS console that just opened:
1. Click on the **`wipsie`** cluster (not wipsie-learning-aurora)
2. Check if it has any databases/data you need
3. If it has data, we'll need to export it first

### **Step 2: Delete the `wipsie` cluster**

**Via AWS Console (Recommended):**
1. Select the **`wipsie`** cluster (the one WITHOUT "learning" in the name)
2. Click **"Actions" → "Delete"**
3. **Uncheck** "Create final snapshot" (unless you need backup)
4. **Check** "I acknowledge that automated backups will be deleted"
5. Type **`delete me`** in the confirmation box
6. Click **"Delete DB cluster"**

**⚠️ This will also delete the associated instance:** `wipsie-instance-1`

### **Step 3: Verify removal**
- Wait 5-10 minutes for deletion to complete
- Refresh the RDS console
- Should only see `wipsie-learning-aurora` remaining

## 💰 **Cost Savings**
Removing one cluster saves: **~$15-30/month**

## 🛡️ **Safety Check Commands**

Before deletion, you can check if the old cluster has data:

```bash
# Check if the old cluster has any databases (if accessible)
aws rds describe-db-clusters --db-cluster-identifier wipsie --query 'DBClusters[0].DatabaseName'

# List all databases in old cluster (if password known)
PGPASSWORD="old_password" psql -h wipsie-cluster-endpoint -U postgres -l
```

## 🚨 **Important Notes**

1. **Double-check cluster names** - Make sure you're deleting `wipsie` NOT `wipsie-learning-aurora`
2. **No final snapshot needed** - We're keeping the better cluster
3. **Associated instances** - Deleting cluster also deletes `wipsie-instance-1`
4. **Irreversible** - Once deleted, the cluster cannot be recovered

## ✅ **After Deletion**

You'll have:
- ✅ **1 Aurora cluster**: `wipsie-learning-aurora` 
- ✅ **Data API enabled**: Ready for Query Editor
- ✅ **Cost optimized**: ~$15-30/month instead of $30-60
- ✅ **Clean setup**: No confusion about which cluster to use

---

## 🔗 **Quick Links**
- **RDS Console**: https://console.aws.amazon.com/rds/home?region=us-east-1#databases:
- **After deletion, test Query Editor**: https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:

**Ready to clean up! Delete the `wipsie` cluster and keep `wipsie-learning-aurora`** 🧹
