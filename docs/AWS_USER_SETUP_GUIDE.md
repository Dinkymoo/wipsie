# 🔐 AWS User Setup Quick Reference

## 🎯 Goal
Create a new AWS IAM user with full permissions to deploy Aurora PostgreSQL and complete Wipsie infrastructure.

## 📋 Current Status
- **Current User**: `wipsie-sqs-user` (limited SQS-only permissions)
- **Target User**: `wipsie-infrastructure-user` (full infrastructure permissions)
- **Account ID**: `554510949034`

## 🚀 Quick Setup Steps

### 1. Go to AWS Console
🔗 **AWS IAM Console**: https://console.aws.amazon.com/iam/home#/users

### 2. Create New User
- **Username**: `wipsie-infrastructure-user`
- **Access type**: Programmatic access + Console access (optional)

### 3. Attach These AWS Managed Policies
Copy and paste these policy names:
```
AmazonRDSFullAccess
AmazonVPCFullAccess
IAMFullAccess
CloudWatchFullAccess
AmazonECS_FullAccess
AmazonS3FullAccess
AmazonSQSFullAccess
AWSLambda_FullAccess
CloudFrontFullAccess
SecretsManagerReadWrite
ApplicationAutoScalingFullAccess
```

### 4. Create Access Key
- Go to user → Security credentials tab
- Create access key → CLI
- **SAVE THE CREDENTIALS!**

### 5. Configure AWS CLI
```bash
aws configure set aws_access_key_id YOUR_ACCESS_KEY_ID
aws configure set aws_secret_access_key YOUR_SECRET_ACCESS_KEY
aws configure set default.region us-east-1
```

### 6. Test Configuration
```bash
aws sts get-caller-identity
# Should show the new user ARN

aws rds describe-db-instances --max-items 1
# Should work without permission errors
```

## 🎯 After Setup - Deploy Aurora
Once the new user is configured:
```bash
cd /workspaces/wipsie
./scripts/setup-aurora.sh
# Choose option 2: Aurora Serverless Only
```

## 🔧 Alternative: Use Custom Policy
If you prefer a custom policy instead of managed policies, use the JSON file:
- File: `/workspaces/wipsie/docs/aws-iam-policy.json`
- Create custom policy in IAM → Policies
- Copy the JSON content from the file
- Attach the custom policy to the user

## ⚠️ Security Notes
- These are broad permissions for learning/development
- For production, use least-privilege principle
- Consider using IAM roles instead of users for applications
- Regularly rotate access keys

## 🆘 Troubleshooting
If you get permission errors after setup:
1. Verify user has all required policies attached
2. Check AWS CLI configuration: `aws configure list`
3. Test specific service: `aws rds describe-db-instances`
4. Run the user setup script: `./scripts/setup-aws-user.sh`
