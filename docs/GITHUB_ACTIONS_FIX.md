# 🆘 GitHub Actions Credential Error - QUICK FIX

## 🚨 Current Error:
```
Run aws-actions/configure-aws-credentials@v4
Error: Credentials could not be loaded, please check your action inputs: 
Could not load credentials from any providers
```

## 🔍 Root Cause:
The repository variable `GITHUB_ACTIONS_ROLE_ARN` is not set in GitHub.

## ⚡ QUICK FIX STEPS:

### Option A: Bootstrap with Admin Credentials (10 minutes)

1. **Get temporary admin AWS credentials** from your AWS administrator
2. **Configure them locally**:
   ```bash
   aws configure --profile bootstrap
   # Enter admin Access Key ID, Secret Key, Region: us-east-1
   export AWS_PROFILE=bootstrap
   ```

3. **Run the bootstrap script**:
   ```bash
   ./scripts/bootstrap-oidc.sh
   ```

4. **Copy the role ARN** from the script output

5. **Set GitHub repository variable**:
   - Go to: https://github.com/Dinkymoo/learn-work/settings/variables/actions
   - Click "New repository variable"
   - Name: `GITHUB_ACTIONS_ROLE_ARN`
   - Value: `arn:aws:iam::554510949034:role/wipsie-github-actions-role`

6. **Re-run the failed GitHub Actions workflow**

7. **Clean up**: Remove bootstrap credentials:
   ```bash
   unset AWS_PROFILE
   aws configure delete --profile bootstrap
   ```

### Option B: Manual Role ARN (if you have it)

If someone can provide you with the role ARN directly:

1. **Set GitHub repository variable**:
   - Go to: https://github.com/Dinkymoo/learn-work/settings/variables/actions
   - Click "New repository variable" 
   - Name: `GITHUB_ACTIONS_ROLE_ARN`
   - Value: `arn:aws:iam::554510949034:role/wipsie-github-actions-role`

2. **Re-run the failed workflow**

## 🎯 After Fix:
- ✅ GitHub Actions workflows will use secure OIDC authentication
- ✅ Lambda functions will deploy to staging automatically
- ✅ No more credential errors
- ✅ Future deployments are fully automated

## 📞 Need Help?
Contact your AWS administrator for temporary admin credentials to complete the bootstrap process.
