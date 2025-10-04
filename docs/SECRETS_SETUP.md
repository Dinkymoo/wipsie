# GitHub Repository Secrets Configuration

This document lists all the secrets that need to be configured in your GitHub repository for the CI/CD workflows to work properly.

## Required Secrets

### Docker Hub (for container builds)
- `DOCKER_USERNAME` - Your Docker Hub username
- `DOCKER_PASSWORD` - Your Docker Hub password or access token

### AWS (for infrastructure and deployment)
- `AWS_ACCESS_KEY_ID` - AWS access key for staging environment
- `AWS_SECRET_ACCESS_KEY` - AWS secret key for staging environment
- `AWS_ACCESS_KEY_ID_PROD` - AWS access key for production environment
- `AWS_SECRET_ACCESS_KEY_PROD` - AWS secret key for production environment
- `AWS_REGION` - AWS region (e.g., us-east-1)

### S3 and CloudFront (for frontend deployment)
- `S3_BUCKET_STAGING` - S3 bucket name for staging frontend
- `S3_BUCKET_PRODUCTION` - S3 bucket name for production frontend
- `CLOUDFRONT_DISTRIBUTION_ID_STAGING` - CloudFront distribution ID for staging
- `CLOUDFRONT_DISTRIBUTION_ID_PRODUCTION` - CloudFront distribution ID for production

### Notifications (optional)
- `SLACK_WEBHOOK` - Slack webhook URL for deployment notifications

## How to Configure Secrets

1. Go to your GitHub repository
2. Click on "Settings" tab
3. In the sidebar, click "Secrets and variables" → "Actions"
4. Click "New repository secret"
5. Add each secret with its name and value

## Current Status

The CI/CD workflows are configured with `continue-on-error: true` for both Docker login and AWS credentials configuration steps, so they will not fail if credentials are missing. This allows other parts of the pipeline to work while you configure the necessary credentials.

### Error Handling Features

- **AWS Credentials**: All `aws-actions/configure-aws-credentials@v4` steps have `continue-on-error: true`
- **Docker Login**: All `docker/login-action@v3` steps have `continue-on-error: true`  
- **Graceful Degradation**: Workflows continue running even when secrets are missing
- **Clear Messaging**: Missing credentials are logged but don't cause workflow failures

## Priority Setup

For basic functionality, you'll need:
1. AWS credentials for infrastructure deployment
2. Docker Hub credentials for container builds (if you plan to use Docker)
3. S3/CloudFront configuration for frontend deployment

The workflows will skip steps that require missing secrets gracefully.
