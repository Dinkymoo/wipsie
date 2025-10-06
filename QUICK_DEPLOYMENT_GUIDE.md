# 🚀 Quick Lambda Staging Deployment Guide

## 🚨 Current Issue: AWS Permissions
Your current AWS user `wipsie-sqs-user` has limited permissions and cannot deploy infrastructure.

## ✅ Recommended Solution: Use GitHub Actions

### Step 1: Deploy Infrastructure via GitHub Actions
1. **Go to your GitHub repository**
2. **Click "Actions" tab**
3. **Find "Infrastructure Deployment" workflow**
4. **Click "Run workflow"**
5. **Select:**
   - Branch: `main`
   - Action: `apply`
   - Environment: `staging`
6. **Click "Run workflow"**

### Step 2: Get GitHub Actions Role ARN
After infrastructure deployment completes:
1. **Check workflow output** for the GitHub Actions role ARN
2. **OR** if you have admin AWS access: `terraform output github_actions_role_arn`

### Step 3: Set Repository Variable
1. **Go to GitHub repo** → Settings → Secrets and variables → Actions → Variables
2. **Create new variable:**
   - Name: `GITHUB_ACTIONS_ROLE_ARN`
   - Value: `arn:aws:iam::554510949034:role/wipsie-github-actions-role`

### Step 4: Deploy Lambda Functions
Lambda deployment should happen automatically since you pushed to `develop` branch.
If not, manually trigger:
1. **Go to Actions** → "AWS Lambda Deployment"
2. **Check if it ran** after your recent push to develop
3. **If failed**, re-run after setting the repository variable

## 🎯 Expected Result
After completion, you'll have:
- ✅ Infrastructure deployed to staging
- ✅ Lambda functions: `wipsie-staging-data_poller` and `wipsie-staging-task_processor`
- ✅ Secure OIDC authentication configured

## 🔍 Monitor Progress
- **GitHub Actions**: Watch workflow progress
- **AWS Console**: Check Lambda functions in us-east-1 region
- **CloudWatch**: Check logs at `/aws/lambda/wipsie-staging-*`

## 🚨 Alternative: If You Have Admin AWS Access
If you have AWS admin credentials:
```bash
# Configure admin credentials
aws configure --profile admin
export AWS_PROFILE=admin

# Run the deployment script
./scripts/deploy-staging.sh
```

The GitHub Actions approach is recommended as it's more secure and doesn't require local admin credentials! 🛡️
