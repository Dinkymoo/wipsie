# 🔐 IAM Roles Implementation Guide

This document explains how to use the IAM roles created in your Terraform infrastructure for secure AWS access without hardcoded credentials.

## 🎯 Overview

Instead of using access keys and secret keys, we've implemented **IAM roles** that provide:
- ✅ **Temporary credentials** that rotate automatically
- ✅ **Principle of least privilege** access
- ✅ **No hardcoded secrets** in your code
- ✅ **Audit trail** of all access

## 🏗️ Roles Created

### 1. ECS Task Execution Role
**Purpose**: Allows ECS to pull container images and write logs
**Usage**: Assigned to ECS task definitions

```hcl
# Example ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "wipsie-app"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.ecs_task_cpu
  memory                  = var.ecs_task_memory
  
  # Use the IAM role for secure access
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([{
    name  = "wipsie-app"
    image = "your-app-image:latest"
    # No AWS credentials needed - provided by IAM role
    environment = [
      {
        name  = "AWS_REGION"
        value = var.aws_region
      }
    ]
  }])
}
```

### 2. ECS Task Role (Application Runtime)
**Purpose**: Provides your application access to AWS services
**Permissions**: SQS, S3, Lambda, Secrets Manager

### 3. Lambda Execution Role
**Purpose**: Allows Lambda functions to access AWS services
**Usage**: Assigned to Lambda functions

```hcl
# Example Lambda Function
resource "aws_lambda_function" "data_processor" {
  filename         = "data_processor.zip"
  function_name    = "wipsie-data-processor"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "main.handler"
  runtime         = "python3.11"
  
  # No AWS credentials needed in environment variables
  environment {
    variables = {
      AWS_REGION = var.aws_region
      # Database credentials from Secrets Manager
      DB_SECRET_ARN = aws_secretsmanager_secret.db_credentials.arn
    }
  }
}
```

### 4. EC2 Instance Profile
**Purpose**: Provides EC2 instances access to AWS services
**Usage**: Attached to EC2 instances

```hcl
# Example EC2 Instance
resource "aws_instance" "app_server" {
  ami                  = "ami-12345678"
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  
  # No AWS credentials needed in user data
  user_data = <<-EOF
    #!/bin/bash
    # Install your application
    # AWS credentials automatically available via instance metadata
    aws s3 cp s3://my-bucket/config.json /app/config.json
  EOF
}
```

### 5. GitHub Actions OIDC Role
**Purpose**: Allows GitHub Actions to deploy infrastructure securely
**Usage**: Referenced in GitHub Actions workflows

## 🔧 Application Code Examples

### Python Boto3 (Automatic Role Detection)
```python
import boto3

# No credentials needed - boto3 automatically uses IAM role
sqs = boto3.client('sqs', region_name='us-east-1')
s3 = boto3.client('s3', region_name='us-east-1')

# Example: Send message to SQS
queue_url = 'https://sqs.us-east-1.amazonaws.com/123456789/wipsie-queue'
sqs.send_message(
    QueueUrl=queue_url,
    MessageBody='Hello from IAM role!'
)
```

### FastAPI Application
```python
import boto3
from fastapi import FastAPI

app = FastAPI()

# Initialize AWS clients without credentials
sqs_client = boto3.client('sqs')
secrets_client = boto3.client('secretsmanager')

@app.get("/health")
async def health_check():
    # Access AWS services using IAM role
    try:
        # Get database credentials from Secrets Manager
        response = secrets_client.get_secret_value(
            SecretId='wipsie/staging/database'
        )
        return {"status": "healthy", "aws_access": "working"}
    except Exception as e:
        return {"status": "error", "message": str(e)}
```

### Lambda Function Code
```python
import json
import boto3

def lambda_handler(event, context):
    # AWS credentials automatically provided by Lambda runtime
    sqs = boto3.client('sqs')
    
    # Process SQS messages
    queue_url = 'https://sqs.us-east-1.amazonaws.com/123456789/wipsie-processing'
    
    response = sqs.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=10
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Messages processed successfully')
    }
```

## 🔄 GitHub Actions Integration

Update your GitHub Actions workflows to use OIDC instead of access keys:

```yaml
# .github/workflows/deploy.yml
name: Deploy Infrastructure

on:
  push:
    branches: [main]

permissions:
  id-token: write   # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_GITHUB_ACTIONS_ROLE_ARN }}
          aws-region: us-east-1
          # No access keys needed!
      
      - name: Deploy with Terraform
        run: |
          cd infrastructure
          terraform init
          terraform apply -auto-approve
```

## 🛡️ Security Benefits

### 1. No Long-Term Credentials
- ❌ No access keys in environment variables
- ❌ No secrets in Docker images
- ✅ Temporary credentials that expire automatically

### 2. Least Privilege Access
- Each role has only the minimum permissions needed
- Scoped to specific resources and regions
- Regular permission reviews possible

### 3. Audit Trail
- All API calls logged in CloudTrail
- Clear visibility of which service accessed what
- Compliance-ready logging

## 🔧 Setup Instructions

### 1. Deploy IAM Roles
```bash
cd infrastructure
terraform plan
terraform apply
```

### 2. Update Application Code
Remove any hardcoded AWS credentials and rely on IAM roles:

```python
# ❌ Old way - hardcoded credentials
client = boto3.client(
    'sqs',
    aws_access_key_id='AKIA...',
    aws_secret_access_key='...'
)

# ✅ New way - use IAM role
client = boto3.client('sqs')  # Automatically uses IAM role
```

### 3. Update Deployment Scripts
Remove AWS credentials from deployment environments and use IAM roles.

### 4. Test Access
Verify that your services can access AWS resources using the new roles.

## 🚨 Migration Checklist

- [ ] Deploy IAM roles with Terraform
- [ ] Update ECS task definitions to use execution/task roles
- [ ] Update Lambda functions to use execution role
- [ ] Remove hardcoded AWS credentials from code
- [ ] Update GitHub Actions to use OIDC
- [ ] Test all AWS service access
- [ ] Remove old access keys from AWS console
- [ ] Update documentation

## 🔍 Troubleshooting

### Common Issues

1. **"AccessDenied" errors**
   - Check IAM role permissions
   - Verify resource ARNs in policies
   - Ensure role is attached to the service

2. **"Unable to locate credentials"**
   - Ensure IAM role is properly attached
   - Check AWS region configuration
   - Verify service has network access to AWS metadata endpoint

3. **GitHub Actions authentication fails**
   - Verify OIDC provider is configured
   - Check repository name in role trust policy
   - Ensure `id-token: write` permission is set

### Debugging Commands

```bash
# Check what credentials are being used
aws sts get-caller-identity

# Test SQS access
aws sqs list-queues

# Verify role assumptions
aws sts assume-role --role-arn arn:aws:iam::123456789:role/test-role --role-session-name test
```

This IAM roles approach is the **AWS recommended best practice** and provides enterprise-grade security for your infrastructure! 🛡️
