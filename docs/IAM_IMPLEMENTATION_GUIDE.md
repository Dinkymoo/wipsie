# Quick IAM Permission Implementation Guide

## Step 1: Create the IAM Policy

### Using AWS Console:
1. Go to **IAM > Policies > Create Policy**
2. Select **JSON** tab
3. Copy the content from `docs/wipsie-iam-policy.json`
4. Name the policy: `WipsieInfrastructurePolicy`
5. Click **Create Policy**

### Using AWS CLI (if you have permissions):
```bash
aws iam create-policy \
    --policy-name WipsieInfrastructurePolicy \
    --policy-document file://docs/wipsie-iam-policy.json
```

## Step 2: Attach Policy to aws-admin User

### Using AWS Console:
1. Go to **IAM > Users > aws-admin**
2. Click **Add permissions**
3. Select **Attach existing policies directly**
4. Search for `WipsieInfrastructurePolicy`
5. Check the box and click **Next** then **Add permissions**

### Using AWS CLI (if you have permissions):
```bash
aws iam attach-user-policy \
    --user-name aws-admin \
    --policy-arn arn:aws:iam::554510949034:policy/WipsieInfrastructurePolicy
```

## Step 3: Verify Permissions
```bash
aws iam get-user
aws iam list-attached-user-policies --user-name aws-admin
```

## Step 4: Resume Infrastructure Deployment

Once permissions are granted, uncomment the IAM resources in Terraform:

```bash
cd infrastructure
# Uncomment IAM resources in main.tf and outputs.tf
terraform plan
terraform apply
```

## Security Notes

✅ **Limited Scope**: Only affects resources with `wipsie-*` naming pattern  
✅ **No Admin Access**: Cannot modify other IAM users, groups, or policies  
✅ **Resource Specific**: Restricted to specific ARN patterns  
✅ **Principle of Least Privilege**: Only permissions needed for infrastructure  

## Rollback Instructions

To remove permissions later:
```bash
# Destroy infrastructure first
terraform destroy

# Remove policy from user
aws iam detach-user-policy \
    --user-name aws-admin \
    --policy-arn arn:aws:iam::554510949034:policy/WipsieInfrastructurePolicy

# Delete the policy
aws iam delete-policy \
    --policy-arn arn:aws:iam::554510949034:policy/WipsieInfrastructurePolicy
```
