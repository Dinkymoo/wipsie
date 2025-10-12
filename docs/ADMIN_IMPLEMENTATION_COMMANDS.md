# AWS Administrator Implementation Commands

## Step 1: Create the IAM Policy
aws iam create-policy \
    --policy-name WipsieInfrastructurePolicy \
    --policy-document file://docs/wipsie-iam-policy.json \
    --description "Limited IAM permissions for Wipsie staging infrastructure deployment"

## Step 2: Attach Policy to User
aws iam attach-user-policy \
    --user-name aws-admin \
    --policy-arn arn:aws:iam::554510949034:policy/WipsieInfrastructurePolicy

## Step 3: Verify Implementation
aws iam list-attached-user-policies --user-name aws-admin

## Step 4: Test User Permissions (as aws-admin user)
aws iam get-user --user-name aws-admin

## Optional: Review Policy Details
aws iam get-policy --policy-arn arn:aws:iam::554510949034:policy/WipsieInfrastructurePolicy
aws iam get-policy-version \
    --policy-arn arn:aws:iam::554510949034:policy/WipsieInfrastructurePolicy \
    --version-id v1

## Cleanup Commands (if needed later)
# Remove policy from user
aws iam detach-user-policy \
    --user-name aws-admin \
    --policy-arn arn:aws:iam::554510949034:policy/WipsieInfrastructurePolicy

# Delete the policy
aws iam delete-policy \
    --policy-arn arn:aws:iam::554510949034:policy/WipsieInfrastructurePolicy
