# 🔧 Deployment Issues - Quick Fix

## 🚨 **Current Deployment Errors:**

### **Error 1: IAM Role Creation Failed**
```
User: arn:aws:iam::554510949034:user/aws-admin is not authorized to perform: iam:CreateRole
```

### **Error 2: Redis Parameter Group** ✅ **FIXED**
```
CacheParameterGroupFamily redis7.x is not a valid parameter group family
```
**Fixed**: Changed from `redis7.x` to `redis6.x` in main.tf

## 🛠️ **Solutions for IAM Issue:**

### **Solution A: Add IAM Permissions to aws-admin User** ⭐ **RECOMMENDED**

**Ask your AWS administrator to add these policies to `aws-admin` user:**

#### **Option A1: Use AWS Managed Policy (Easiest)**
```json
{
  "Policy": "PowerUserAccess",
  "Note": "Gives broad permissions except billing"
}
```

#### **Option A2: Add Specific IAM Permissions**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy",
        "iam:CreateInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:PassRole",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:TagRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### **Solution B: Use Different Admin User**

If you have access to a user with broader permissions:

```bash
# Configure a different admin user
aws configure --profile super-admin
export AWS_PROFILE=super-admin

# Try deployment again
terraform apply
```

### **Solution C: Deploy Without IAM Roles (Temporary)**

Temporarily comment out the problematic IAM role:

1. **Edit infrastructure/main.tf**
2. **Comment out lines 1041-1065** (RDS monitoring role)
3. **Comment out the reference** in RDS instance (line ~1106)
4. **Deploy without monitoring role**
5. **Add it back later when you get IAM permissions**

## 🚀 **Quick Fix Commands:**

### **Step 1: Fix Redis Issue** ✅ **DONE**
Already fixed the redis6.x parameter group family.

### **Step 2: Fix IAM Issue**

#### **Option 1: Get Better Permissions (Best)**
Contact your AWS admin with this message:

```
Hi! The aws-admin user needs IAM permissions to create infrastructure roles.

Please add one of these to aws-admin user:
1. PowerUserAccess policy (easiest)
2. Custom policy with iam:CreateRole, iam:AttachRolePolicy permissions

The deployment failed when trying to create:
arn:aws:iam::554510949034:role/wipsie-rds-monitoring-staging

Thanks!
```

#### **Option 2: Temporary Workaround**
```bash
# Comment out the RDS monitoring role temporarily
sed -i '1041,1065s/^/# /' infrastructure/main.tf
sed -i 's/aws_iam_role.rds_monitoring.arn/""/g' infrastructure/main.tf

# Deploy without monitoring
terraform apply

# Add monitoring back later when you get IAM permissions
```

## 🔍 **Check Current Permissions:**

```bash
# Test what IAM actions you can perform
aws iam list-roles --max-items 5
aws iam get-user --user-name aws-admin
```

## ⚡ **After Getting Permissions:**

Once your admin adds IAM permissions:

```bash
# Try deployment again
terraform apply

# Should work for all 46 resources now!
```

## 🎯 **Recommended Next Steps:**

1. **Contact AWS admin** for PowerUserAccess on `aws-admin` user
2. **Rerun terraform apply** once permissions are added
3. **Complete deployment** should take 15-20 minutes

The infrastructure code is correct - just need the right AWS permissions! 🚀
