# IAM Permissions Request for AWS Admin User

## Request Overview
**User:** `aws-admin` (arn:aws:iam::554510949034:user/aws-admin)  
**Account:** `554510949034`  
**Environment:** Staging Infrastructure Deployment  
**Project:** Wipsie Application Infrastructure  
**Request Date:** October 7, 2025  

## Current Status
The `aws-admin` user currently has limited permissions that prevent the creation and management of IAM resources required for our Terraform infrastructure deployment. We need additional IAM permissions to deploy a complete staging environment.

## Infrastructure Requirements
We are deploying a complete AWS infrastructure using Terraform that includes:

### Core Services Being Deployed
- ✅ **VPC & Networking** - Currently working
- ✅ **RDS PostgreSQL Database** - Currently working  
- ✅ **ElastiCache Redis** - Currently working
- ✅ **Application Load Balancer** - Currently working
- ✅ **ECS Cluster** - Currently working
- ✅ **S3 Buckets** - Currently working
- ✅ **CloudFront Distribution** - Currently working
- ✅ **SQS Queues** - Currently working
- ❌ **IAM Roles & Policies** - **BLOCKED** - Need permissions
- ❌ **ECS Services & Tasks** - **BLOCKED** - Depends on IAM roles
- ❌ **Lambda Functions** - **BLOCKED** - Depends on IAM roles

## Specific IAM Permissions Required

### 1. IAM Role Management
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:UpdateRole",
                "iam:GetRole",
                "iam:ListRoles",
                "iam:PassRole"
            ],
            "Resource": [
                "arn:aws:iam::554510949034:role/wipsie-*",
                "arn:aws:iam::554510949034:role/*ecs-task*",
                "arn:aws:iam::554510949034:role/*lambda*"
            ]
        }
    ]
}
```

### 2. IAM Policy Management
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreatePolicy",
                "iam:DeletePolicy",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:ListPolicies",
                "iam:CreatePolicyVersion",
                "iam:DeletePolicyVersion",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:GetRolePolicy",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies"
            ],
            "Resource": [
                "arn:aws:iam::554510949034:role/wipsie-*",
                "arn:aws:iam::554510949034:policy/wipsie-*"
            ]
        }
    ]
}
```

### 3. Instance Profile Management
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:ListInstanceProfiles",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile"
            ],
            "Resource": [
                "arn:aws:iam::554510949034:instance-profile/wipsie-*"
            ]
        }
    ]
}
```

### 4. Self-Management Permissions (for debugging)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetUser",
                "iam:ListAttachedUserPolicies",
                "iam:ListUserPolicies"
            ],
            "Resource": "arn:aws:iam::554510949034:user/aws-admin"
        }
    ]
}
```

## Required IAM Roles for Infrastructure

### 1. ECS Task Execution Role
**Purpose:** Allows ECS to pull container images and write logs  
**Managed Policies:** `arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy`  
**Custom Policies:** Access to Secrets Manager and Parameter Store  

### 2. ECS Task Role
**Purpose:** Runtime permissions for the application containers  
**Permissions:** SQS, S3, Lambda invocation, Secrets Manager access  

### 3. Lambda Execution Role
**Purpose:** Permissions for Lambda functions to run  
**Managed Policies:** `arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole`  
**Custom Policies:** VPC access, SQS, RDS, S3, Secrets Manager  

### 4. EC2 Instance Role (Optional)
**Purpose:** For any EC2 instances that might be needed  
**Permissions:** CloudWatch, Systems Manager, Secrets Manager  

## Security Considerations

### Resource Restrictions
- All IAM resources are restricted to the `wipsie-*` naming pattern
- Roles are scoped to specific service principals (ECS, Lambda, EC2)
- Policies follow principle of least privilege
- No cross-account access or administrative privileges

### Temporary Nature
- These permissions are for staging environment deployment
- Resources can be easily cleaned up after testing
- All infrastructure is managed via Terraform with state tracking

## Business Justification

### Current Impact
- **Infrastructure deployment is 60% complete** but blocked on IAM permissions
- **Development team is waiting** for staging environment to test application
- **CI/CD pipeline cannot be completed** without Lambda functions and ECS services

### Benefits of Granting Permissions
- ✅ Complete staging environment for application testing
- ✅ Automated deployments via Terraform
- ✅ Proper security boundaries with IAM roles
- ✅ Production-ready infrastructure patterns
- ✅ Cost-effective staging setup using t3.micro instances

## Alternative Solutions Considered

### Option 1: Manual IAM Creation (Not Recommended)
- Creates drift between Terraform and actual infrastructure
- Harder to maintain and reproduce
- Manual process prone to errors

### Option 2: Pre-created IAM Roles (Possible Alternative)
- Could create roles manually and reference in Terraform
- Would require providing role ARNs
- Less automated and flexible

### Option 3: Separate IAM Account/User (Complex)
- Would require additional AWS account setup
- More complex credential management
- Unnecessary for staging environment

## Recommended IAM Policy

Here's a comprehensive policy that can be attached to the `aws-admin` user:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "WipsieIAMRoleManagement",
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:UpdateRole",
                "iam:GetRole",
                "iam:ListRoles",
                "iam:PassRole",
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:ListInstanceProfiles",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile"
            ],
            "Resource": [
                "arn:aws:iam::554510949034:role/wipsie-*",
                "arn:aws:iam::554510949034:instance-profile/wipsie-*"
            ]
        },
        {
            "Sid": "WipsieIAMPolicyManagement",
            "Effect": "Allow",
            "Action": [
                "iam:CreatePolicy",
                "iam:DeletePolicy",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:ListPolicies",
                "iam:CreatePolicyVersion",
                "iam:DeletePolicyVersion",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:GetRolePolicy",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies"
            ],
            "Resource": [
                "arn:aws:iam::554510949034:role/wipsie-*",
                "arn:aws:iam::554510949034:policy/wipsie-*"
            ]
        },
        {
            "Sid": "SelfManagement",
            "Effect": "Allow",
            "Action": [
                "iam:GetUser",
                "iam:ListAttachedUserPolicies",
                "iam:ListUserPolicies"
            ],
            "Resource": "arn:aws:iam::554510949034:user/aws-admin"
        }
    ]
}
```

## Implementation Steps

1. **Create IAM Policy**: Copy the recommended policy above
2. **Attach to User**: Attach the policy to the `aws-admin` user
3. **Verify Permissions**: Run `aws iam get-user` to confirm access
4. **Resume Deployment**: Uncomment IAM resources in Terraform and run `terraform apply`

## Contact Information

**Technical Contact:** Development Team  
**Project:** Wipsie Staging Infrastructure  
**Urgency:** Medium - Blocking development progress  

## Rollback Plan

If permissions need to be revoked:
1. Run `terraform destroy` to clean up all resources
2. Detach the IAM policy from the `aws-admin` user
3. All project-specific IAM resources will be removed

---

**This request follows AWS security best practices with resource-specific permissions and clear business justification.**
