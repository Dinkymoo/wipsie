# 🔑 AWS Credentials Troubleshooting Guide

## 🚨 **Current Issue: Limited Permissions**

**Error**: `wipsie-sqs-user is not authorized to perform: ec2:DescribeAvailabilityZones`

**Root Cause**: Your current AWS user (`wipsie-sqs-user`) only has SQS permissions, but Terraform needs broader AWS access to create infrastructure.

## 🛠️ **Solutions (Choose One):**

### **Solution 1: Bootstrap Script (Recommended) 🎯**

This is the most secure approach for production environments:

```bash
# 1. Get temporary admin credentials from your AWS administrator
# Ask for: PowerUserAccess OR custom deployment policy

# 2. Configure admin profile temporarily
aws configure --profile bootstrap-admin
# Enter admin access key ID and secret access key

# 3. Use admin profile for infrastructure deployment
export AWS_PROFILE=bootstrap-admin

# 4. Deploy infrastructure
cd /workspaces/wipsie/infrastructure
terraform plan    # Should work now!
terraform apply   # Deploy infrastructure

# 5. Clean up admin credentials (security best practice)
unset AWS_PROFILE
aws configure --profile bootstrap-admin delete
```

### **Solution 2: Expand Current User Permissions**

Ask your AWS administrator to attach these policies to `wipsie-sqs-user`:

```json
{
  "Required AWS Managed Policies": [
    "AmazonEC2FullAccess",
    "AmazonRDSFullAccess", 
    "AmazonECSFullAccess",
    "IAMFullAccess",
    "AWSLambdaFullAccess",
    "AmazonS3FullAccess",
    "AmazonVPCFullAccess",
    "CloudWatchFullAccess",
    "AmazonElastiCacheFullAccess"
  ]
}
```

### **Solution 3: Create New Deployment User**

Ask your AWS administrator to create a new IAM user for infrastructure deployment:

```bash
# User: wipsie-deploy-user
# Policies: PowerUserAccess (or custom deployment policy)
# Access: Programmatic (access key)
```

## 🔍 **Check Current Permissions:**

```bash
# Test your current permissions
aws sts get-caller-identity
# Should show: arn:aws:iam::554510949034:user/wipsie-sqs-user

# Test EC2 permissions
aws ec2 describe-regions --region us-east-1
# Will fail with current user

# Test SQS permissions (should work)
aws sqs list-queues --region us-east-1
# Should work with current user
```

## 🚀 **After Getting Proper Credentials:**

```bash
# 1. Test infrastructure deployment
cd /workspaces/wipsie/infrastructure
terraform plan
# Should show: Plan: 46 to add, 0 to change, 0 to destroy

# 2. Deploy infrastructure
terraform apply
# Type 'yes' when prompted

# 3. Verify deployment
terraform output
# Should show all resource endpoints and IDs
```

## 🔐 **Security Best Practices:**

### **For Development:**
- Use admin credentials temporarily for setup
- Switch to GitHub Actions OIDC for ongoing deployments
- Never commit credentials to code

### **For Production:**
- Use OIDC authentication (no long-term credentials)
- Implement least-privilege access
- Rotate credentials regularly
- Enable CloudTrail for auditing

## 📞 **Need Help?**

### **Ask Your AWS Administrator For:**
1. **Temporary admin credentials** for initial infrastructure setup
2. **OIDC provider setup** for GitHub Actions (we have the script ready!)
3. **Custom deployment policy** instead of PowerUserAccess (more secure)

### **Or Try This Minimal Policy:**
If your admin wants a more restricted policy, they can create this custom policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "ecs:*",
        "lambda:*",
        "s3:*",
        "iam:*",
        "elasticache:*",
        "cloudwatch:*",
        "logs:*",
        "events:*",
        "sqs:*",
        "cloudfront:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## ✅ **Quick Test Commands:**

After getting proper credentials, test each service:

```bash
# Test core permissions
aws ec2 describe-availability-zones --region us-east-1  ✅
aws iam list-roles --max-items 5                        ✅  
aws rds describe-db-instances --region us-east-1        ✅
aws ecs list-clusters --region us-east-1                ✅
aws lambda list-functions --region us-east-1            ✅
aws s3 ls                                                ✅
```

**Once all tests pass, your infrastructure deployment will work!** 🎉
