# 🐳 Docker Configuration for IAM Roles

## Local Development with IAM Roles

When running locally, you can simulate IAM role access using AWS profiles or temporary credentials.

### Option 1: AWS Profile (Recommended for Local Development)

```yaml
# docker-compose.iam-roles.yml
version: '3.8'

services:
  wipsie-backend:
    build: ./backend
    environment:
      # Use AWS profile instead of hardcoded credentials
      - AWS_PROFILE=wipsie-dev
      - AWS_REGION=us-east-1
      # No AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY needed!
    volumes:
      # Mount AWS credentials directory
      - ~/.aws:/root/.aws:ro
    ports:
      - "8000:8000"
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: wipsie
      POSTGRES_USER: wipsie_user
      POSTGRES_PASSWORD: wipsie_password
    ports:
      - "5432:5432"
```

### Option 2: Temporary Credentials

```bash
# Get temporary credentials for local testing
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT:role/wipsie-staging-ecs-task \
  --role-session-name local-dev \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text

# Export as environment variables
export AWS_ACCESS_KEY_ID=ASIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

## Production ECS Configuration

In production, ECS automatically provides IAM role credentials:

### ECS Task Definition

```json
{
  "family": "wipsie-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/wipsie-staging-ecs-task-execution",
  "taskRoleArn": "arn:aws:iam::ACCOUNT:role/wipsie-staging-ecs-task",
  "containerDefinitions": [
    {
      "name": "wipsie-app",
      "image": "your-registry/wipsie-app:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "AWS_REGION",
          "value": "us-east-1"
        },
        {
          "name": "ENVIRONMENT",
          "value": "staging"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/wipsie-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

## Application Code Changes

### Before (Hardcoded Credentials)
```python
# ❌ Insecure - hardcoded credentials
import boto3

sqs = boto3.client(
    'sqs',
    aws_access_key_id='AKIA...',
    aws_secret_access_key='...',
    region_name='us-east-1'
)
```

### After (IAM Roles)
```python
# ✅ Secure - uses IAM role
import boto3

# Automatically uses IAM role in ECS/Lambda
# or AWS profile in local development
sqs = boto3.client('sqs', region_name='us-east-1')
```

## Environment Variables

### Development
```bash
# .env.local
AWS_PROFILE=wipsie-dev
AWS_REGION=us-east-1
# No access keys!
```

### Production (ECS)
```bash
# Environment variables in ECS task
AWS_REGION=us-east-1
# Credentials provided automatically by ECS + IAM role
```

## Testing IAM Role Access

```python
# test_iam_access.py
import boto3
import json

def test_aws_access():
    """Test that IAM role provides correct access"""
    try:
        # Test STS (always available)
        sts = boto3.client('sts')
        identity = sts.get_caller_identity()
        print(f"✅ AWS Identity: {identity}")
        
        # Test SQS access
        sqs = boto3.client('sqs')
        queues = sqs.list_queues()
        print(f"✅ SQS Access: Found {len(queues.get('QueueUrls', []))} queues")
        
        # Test S3 access
        s3 = boto3.client('s3')
        buckets = s3.list_buckets()
        print(f"✅ S3 Access: Found {len(buckets['Buckets'])} buckets")
        
        return True
    except Exception as e:
        print(f"❌ AWS Access Error: {e}")
        return False

if __name__ == "__main__":
    test_aws_access()
```

## Troubleshooting

### Common Issues

1. **"Unable to locate credentials"**
   ```bash
   # Check AWS configuration
   aws configure list
   aws sts get-caller-identity
   ```

2. **"Access Denied"**
   ```bash
   # Check IAM role permissions
   aws iam get-role --role-name wipsie-staging-ecs-task
   aws iam list-attached-role-policies --role-name wipsie-staging-ecs-task
   ```

3. **Local Development Issues**
   ```bash
   # Setup AWS profile
   aws configure --profile wipsie-dev
   export AWS_PROFILE=wipsie-dev
   ```

This approach eliminates the security risks of hardcoded credentials while providing seamless AWS access! 🔐
