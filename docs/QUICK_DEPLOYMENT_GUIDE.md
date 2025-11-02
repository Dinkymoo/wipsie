# 🚀 Quick Lambda Staging Deployment Guide

## 🚨 Current Issue: GitHub Actions Credentials Error
```
Error: Credentials could not be loaded, please check your action inputs: 
Could not load credentials from any providers
```

**Root Cause**: The `GITHUB_ACTIONS_ROLE_ARN` repository variable hasn't been set yet.

## 🔄 The Bootstrap Problem
This is a "chicken-and-egg" situation:
- ❌ Need infrastructure deployed to get the GitHub Actions role ARN
- ❌ Need GitHub Actions role ARN to deploy infrastructure via GitHub Actions
- ❌ Current AWS user `wipsie-sqs-user` has limited permissions for local deployment

## ✅ Bootstrap Solutions (Choose One)

### Option 1: Manual Infrastructure Bootstrap (RECOMMENDED)
If you have access to admin AWS credentials:

1. **Get admin AWS credentials** (temporary, just for bootstrap)
2. **Deploy infrastructure once** to create the OIDC role:
   ```bash
   # Configure admin credentials temporarily
   aws configure --profile bootstrap
   export AWS_PROFILE=bootstrap
   
   # Deploy infrastructure
   cd infrastructure/
   terraform init
   terraform apply -var-file="staging.tfvars"
   
   # Get the role ARN
   terraform output github_actions_role_arn
   ```

3. **Set repository variable** with the ARN from step 2
4. **Remove admin credentials** - future deployments use OIDC
5. **Re-run failed GitHub Actions workflows**

### Option 2: Request IT/DevOps Team
Ask your DevOps team to:
1. **Create the GitHub Actions OIDC role** manually in AWS
2. **Provide you with the role ARN**: `arn:aws:iam::554510949034:role/wipsie-github-actions-role`
3. **You set it as repository variable**

### Option 3: Temporary IAM User for Bootstrap
Create a temporary IAM user with infrastructure deployment permissions:
1. **Create IAM user** with `PowerUserAccess` or custom infrastructure policy
2. **Use for initial deployment** only
3. **Delete the user** after OIDC is working

### Step 1: Deploy Infrastructure via GitHub Actions
**⚠️ PREREQUISITE**: You need the `GITHUB_ACTIONS_ROLE_ARN` repository variable set first!

After you've bootstrapped the infrastructure (see Bootstrap Solutions above):
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
