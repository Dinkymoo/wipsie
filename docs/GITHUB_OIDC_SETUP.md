# 🔐 GitHub Actions OIDC Setup Guide

This guide will help you configure GitHub Actions to use OpenID Connect (OIDC) authentication with AWS instead of long-lived access keys.

## 📋 Prerequisites

1. ✅ Terraform infrastructure deployed with IAM roles
2. ✅ GitHub repository with admin access
3. ✅ AWS account with proper permissions

## 🎯 Step 1: Deploy Terraform Infrastructure

First, ensure your Terraform infrastructure is deployed with the GitHub Actions OIDC role:

```bash
cd infrastructure/
terraform init
terraform plan
terraform apply
```

After deployment, get the GitHub Actions role ARN:

```bash
terraform output github_actions_role_arn
```

## 🔧 Step 2: Configure GitHub Repository Variables

### 2.1 Repository Variables

Go to your GitHub repository settings and add the following **Repository Variables**:

1. Navigate to: `Settings` → `Secrets and variables` → `Actions` → `Variables` tab
2. Add the following variable:

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `GITHUB_ACTIONS_ROLE_ARN` | `arn:aws:iam::YOUR_ACCOUNT:role/wipsie-github-actions-role` | The ARN from Terraform output |

### 2.2 Environment Variables (Optional)

If you use environment-specific deployments, you can also set variables at the environment level:

1. Go to `Settings` → `Environments`
2. For each environment (`staging`, `production`), add the same variable

## 🔄 Step 3: Update Workflow Files

The following workflow files have been updated to use OIDC:

### ✅ Updated Files:
- `.github/workflows/lambda-deploy.yml` - Lambda deployment workflows
- `.github/workflows/cost-estimation.yml` - Cost monitoring workflows  
- `.github/workflows/infrastructure.yml` - Terraform workflows

### 📝 Key Changes Made:

1. **Added Permissions**: Each job now includes:
   ```yaml
   permissions:
     id-token: write
     contents: read
   ```

2. **Updated AWS Configuration**: Replaced access keys with role assumption:
   ```yaml
   - name: 🔧 Configure AWS Credentials
     uses: aws-actions/configure-aws-credentials@v4
     with:
       role-to-assume: ${{ vars.GITHUB_ACTIONS_ROLE_ARN }}
       aws-region: ${{ env.AWS_REGION }}
   ```

## 🧪 Step 4: Test the Configuration

### 4.1 Test with a Simple Workflow

Create a test workflow to verify OIDC authentication:

```yaml
name: Test OIDC
on:
  workflow_dispatch:

jobs:
  test-oidc:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.GITHUB_ACTIONS_ROLE_ARN }}
          aws-region: us-east-1
      
      - name: Test AWS Access
        run: |
          aws sts get-caller-identity
          aws s3 ls
```

### 4.2 Run Existing Workflows

1. Push changes to trigger workflows
2. Check workflow logs for successful authentication
3. Verify no access key errors

## 🚨 Troubleshooting

### Common Issues and Solutions

#### 1. "Context access might be invalid: GITHUB_ACTIONS_ROLE_ARN"

**Problem**: GitHub workflow validation error.

**Solution**: Ensure the repository variable is set correctly:
- Go to `Settings` → `Secrets and variables` → `Actions` → `Variables`
- Verify `GITHUB_ACTIONS_ROLE_ARN` exists and has the correct ARN value

#### 2. "AssumeRoleWithWebIdentity" errors

**Problem**: GitHub Actions cannot assume the IAM role.

**Solution**: Check the OIDC provider and role configuration:

```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers

# Check role trust policy
aws iam get-role --role-name wipsie-github-actions-role
```

#### 3. "Access Denied" errors

**Problem**: IAM role doesn't have sufficient permissions.

**Solution**: Review and update IAM policies:

```bash
# List attached policies
aws iam list-attached-role-policies --role-name wipsie-github-actions-role

# Check specific policy
aws iam get-policy-version --policy-arn arn:aws:iam::YOUR_ACCOUNT:policy/wipsie-github-actions-policy --version-id v1
```

#### 4. Repository not found in role trust policy

**Problem**: Role trust policy doesn't include your repository.

**Solution**: Update the Terraform configuration in `infrastructure/main.tf`:

```hcl
# Update the repository name in the trust policy
data "aws_iam_policy_document" "github_actions_trust_policy" {
  statement {
    # ... existing configuration ...
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:YOUR_GITHUB_USERNAME/wipsie:*"]  # Update this line
    }
  }
}
```

## 🔒 Security Best Practices

### 1. Principle of Least Privilege
- ✅ Each role has only necessary permissions
- ✅ Time-limited tokens (no long-lived credentials)
- ✅ Repository-specific access control

### 2. Monitoring and Auditing
- ✅ CloudTrail logs all API calls
- ✅ Workflow logs show authentication details
- ✅ Regular permission reviews

### 3. Credential Rotation
- ✅ No manual credential rotation needed
- ✅ Tokens automatically expire
- ✅ No stored secrets in GitHub

## 📊 Migration Checklist

- [ ] Deploy Terraform infrastructure with OIDC provider
- [ ] Get GitHub Actions role ARN from Terraform output
- [ ] Set `GITHUB_ACTIONS_ROLE_ARN` repository variable
- [ ] Remove old AWS access key secrets (after testing)
- [ ] Test workflows with OIDC authentication
- [ ] Update team documentation
- [ ] Monitor workflow logs for issues

## 🚀 Benefits of OIDC Authentication

1. **Enhanced Security**: No long-lived credentials stored in GitHub
2. **Automatic Rotation**: Tokens are short-lived and automatically managed
3. **Fine-grained Access**: Repository and branch-specific permissions
4. **Audit Trail**: All authentication events logged in CloudTrail
5. **Simplified Management**: No manual credential rotation required

## 📚 Additional Resources

- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS IAM OIDC Provider Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [GitHub Actions Security Guide](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

---

## ⚠️ Important Notes

1. **Remove Old Secrets**: After confirming OIDC works, remove the old AWS access key secrets from GitHub
2. **Test Thoroughly**: Test all workflows before removing backup authentication
3. **Monitor Logs**: Watch CloudTrail and workflow logs for any authentication issues
4. **Team Communication**: Ensure all team members understand the new authentication method

By following this guide, you'll have secure, keyless authentication between GitHub Actions and AWS using OIDC! 🎉
