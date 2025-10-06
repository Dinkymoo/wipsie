# 🚀 GitHub Actions CI/CD Setup Guide

This guide explains how to set up and configure the GitHub Actions workflows for the Wipsie application.

## 📁 Workflow Files

The following workflow files have been created in `.github/workflows/`:

1. **`backend-ci.yml`** - Backend CI/CD pipeline
2. **`frontend-ci.yml`** - Frontend CI/CD pipeline  
3. **`lambda-deploy.yml`** - AWS Lambda deployment
4. **`database-migration.yml`** - Database migration management
5. **`security-scan.yml`** - Security and dependency scanning
6. **`infrastructure.yml`** - Infrastructure deployment (Terraform)
7. **`cost-estimation.yml`** - Cost monitoring and estimation

## 🎓 Learning Environment

For **learning purposes**, we've optimized everything to work with **AWS Free Tier**:

- **Total monthly cost: $0.00** for 12 months!
- All services covered by AWS Free Tier
- Public GitHub repository (unlimited Actions)
- Optimized resource usage for education

**Quick start for learners:**
```bash
# Check learning costs (should be $0!)
python tools/cost-estimation/simple_cost_estimator.py learning

# See detailed free tier breakdown
python tools/cost-estimation/learning_quick_test.py
```

📚 **See [Learning Setup Guide](../docs/LEARNING_SETUP.md) for complete instructions.**

## 🔑 Required Secrets

### Repository Secrets

Configure these secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

#### Docker Hub
```
DOCKER_USERNAME=your_docker_username
DOCKER_PASSWORD=your_docker_password_or_token
```

#### AWS Staging Environment
```
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_REGION=us-east-1
```

#### AWS Production Environment
```
AWS_ACCESS_KEY_ID_PROD=your_production_aws_access_key
AWS_SECRET_ACCESS_KEY_PROD=your_production_aws_secret_key
```

#### Database Connections
```
STAGING_DATABASE_URL=postgresql://user:password@staging-host:5432/wipsie_staging
PRODUCTION_DATABASE_URL=postgresql://user:password@production-host:5432/wipsie_production
```

#### S3 and CloudFront (Frontend Deployment)
```
S3_BUCKET_STAGING=wipsie-frontend-staging
S3_BUCKET_PRODUCTION=wipsie-frontend-production
CLOUDFRONT_DISTRIBUTION_ID_STAGING=E1234567890ABC
CLOUDFRONT_DISTRIBUTION_ID_PRODUCTION=E0987654321DEF
```

#### Notifications
```
SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

#### Code Quality (Optional)
```
SONAR_TOKEN=your_sonarcloud_token
```

## 🌍 Environment Configuration

### GitHub Environments

Create these environments in your repository (`Settings > Environments`):

#### 1. **staging**
- **Protection Rules**: None (auto-deploy on develop branch)
- **Environment Secrets**: Use staging AWS credentials
- **Reviewers**: Optional

#### 2. **production**  
- **Protection Rules**: Required reviewers (recommend 2+ reviewers)
- **Environment Secrets**: Use production AWS credentials
- **Reviewers**: Senior developers, DevOps team

## 🔄 Workflow Triggers

### Backend CI/CD (`backend-ci.yml`)
- **Triggers**: 
  - Push to `main`, `develop`, `feat/*` branches
  - Changes to `backend/`, `requirements.txt`, `docker/`
- **Actions**:
  - ✅ Run tests with PostgreSQL/Redis
  - 🎨 Code formatting (Black, isort)
  - 🔍 Linting (Flake8, MyPy)
  - 🔒 Security scanning (Safety, Bandit)
  - 🐳 Build and push Docker images
  - 🚀 Deploy to staging/production

### Frontend CI/CD (`frontend-ci.yml`)
- **Triggers**:
  - Push to `main`, `develop`, `feat/*` branches  
  - Changes to `frontend/`, `package.json`
- **Actions**:
  - 🧪 Run unit and E2E tests
  - 🎨 Lint TypeScript code
  - 🔨 Build production bundle
  - 🐳 Build and push Docker images
  - 🚀 Deploy to S3/CloudFront

### Lambda Deployment (`lambda-deploy.yml`)
- **Triggers**:
  - Push to `main`, `develop` branches
  - Changes to `aws-lambda/`
- **Actions**:
  - 🧪 Test Lambda functions locally
  - 📦 Package functions with dependencies
  - 🚀 Deploy to AWS Lambda
  - 🏗️ Update CloudFormation infrastructure

### Database Migration (`database-migration.yml`)
- **Triggers**:
  - Push to `main`, `develop` branches
  - Changes to `backend/alembic/versions/`, `backend/models/`
  - Manual workflow dispatch
- **Actions**:
  - 🧪 Validate migrations on test database
  - 📊 Check current migration status
  - 🗄️ Run migrations on staging/production
  - 💾 Backup production database (before prod migrations)

### Security Scanning (`security-scan.yml`)
- **Triggers**:
  - Schedule: Every Monday at 9 AM UTC
  - Push to `main` branch
  - Changes to dependency files
  - Manual workflow dispatch
- **Actions**:
  - 🔍 Dependency vulnerability scanning
  - 🕵️ Secret scanning with TruffleHog
  - 🔬 Code quality analysis
  - 🏗️ Infrastructure security scanning
  - 📤 Dependency update recommendations

### Infrastructure (`infrastructure.yml`)
- **Triggers**:
  - Push to `main` branch
  - Changes to `infrastructure/`
  - Manual workflow dispatch
- **Actions**:
  - 🔍 Terraform validation and formatting
  - 📋 Generate Terraform plans
  - 🚀 Apply infrastructure changes
  - 📊 Export infrastructure outputs

## 🛠️ Setup Instructions

### 1. **Initial Repository Setup**

```bash
# Ensure all workflow files are in place
ls -la .github/workflows/

# Commit the workflow files
git add .github/
git commit -m "🚀 Add comprehensive GitHub Actions workflows"
git push origin main
```

### 2. **Configure Repository Secrets**

1. Go to your repository on GitHub
2. Navigate to `Settings > Secrets and variables > Actions`
3. Add all required secrets listed above
4. Test with a small change to trigger workflows

### 3. **Set Up GitHub Environments**

1. Go to `Settings > Environments`
2. Create `staging` and `production` environments
3. Configure protection rules for production
4. Add environment-specific secrets

### 4. **Configure AWS Infrastructure**

```bash
# Create S3 buckets for Terraform state
aws s3 mb s3://wipsie-terraform-state-staging
aws s3 mb s3://wipsie-terraform-state-production

# Create S3 buckets for frontend hosting
aws s3 mb s3://wipsie-frontend-staging
aws s3 mb s3://wipsie-frontend-production

# Set up CloudFront distributions (or use Terraform)
```

### 5. **Test the Workflows**

```bash
# Test backend workflow
git checkout -b test/backend-ci
echo "# Test change" >> backend/README.md
git add . && git commit -m "test: trigger backend CI"
git push origin test/backend-ci

# Create PR to test full pipeline
```

## 📊 Monitoring and Notifications

### Slack Integration

1. Create a Slack webhook in your workspace
2. Add the webhook URL to `SLACK_WEBHOOK` secret
3. Workflows will notify:
   - `#deployments` - Deployment status
   - `#security` - Security scan results
   - `#infrastructure` - Infrastructure changes
   - `#database` - Migration status

### Workflow Status

Monitor workflow status in:
- **GitHub Actions tab** - Real-time status
- **PR checks** - Automatic status on pull requests
- **Slack notifications** - Automated team updates
- **Email notifications** - GitHub default notifications

## 🔧 Customization

### Environment-Specific Configuration

Modify workflows for your specific needs:

```yaml
# Example: Add custom environment variables
env:
  MY_CUSTOM_VAR: ${{ secrets.MY_CUSTOM_VAR }}
  
# Example: Change trigger conditions
on:
  push:
    branches: [ main, develop, release/* ]  # Add release branches
```

### Adding New Environments

1. Create new environment in GitHub
2. Add environment-specific secrets
3. Update workflow files to include new environment
4. Configure deployment targets

### Custom Deployment Targets

Modify deployment steps for your infrastructure:

```yaml
# Example: Deploy to Kubernetes
- name: 🚀 Deploy to Kubernetes
  run: |
    kubectl apply -f k8s/
    kubectl rollout status deployment/wipsie-backend
```

## 🚨 Troubleshooting

### Common Issues

1. **Workflow fails with "Secret not found"**
   - Check secret names match exactly
   - Verify secrets are set in correct scope (repo vs environment)

2. **Docker build fails**
   - Check Dockerfile paths in workflow
   - Verify Docker Hub credentials

3. **AWS deployment fails**
   - Verify AWS credentials have sufficient permissions
   - Check AWS region configuration

4. **Database migration fails**
   - Verify database connection strings
   - Check Alembic configuration

### Debug Steps

```bash
# Enable workflow debugging
# Add this to workflow environment:
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## 📚 Best Practices

1. **Security**:
   - Use environment-specific secrets
   - Rotate credentials regularly
   - Never commit secrets to code

2. **Testing**:
   - Test workflows on feature branches
   - Use PR checks before merging
   - Monitor workflow performance

3. **Deployment**:
   - Use staging environment for testing
   - Require manual approval for production
   - Implement rollback procedures

4. **Monitoring**:
   - Set up proper notifications
   - Monitor deployment metrics
   - Track workflow execution times

---

**Your CI/CD pipeline is now ready for production use! 🎉**

For questions or issues, check the GitHub Actions documentation or contact the DevOps team.
