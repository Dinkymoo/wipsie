# 🚀 Complete Testing & Deployment Plan

## 📊 Current Architecture Status
✅ **Infrastructure Code**: Terraform with IAM roles, VPC, ECS, RDS, Lambda
✅ **Lambda Functions**: data_poller.py & task_processor.py ready for staging
✅ **Backend API**: FastAPI with Celery, database models, task management
✅ **Frontend**: Angular application structure
✅ **CI/CD**: GitHub Actions with OIDC authentication
✅ **Documentation**: Comprehensive guides and security setup

## 🎯 Step-by-Step Deployment & Testing Plan

### Phase 1: Bootstrap Infrastructure (15-30 minutes)

#### Step 1.1: Get Admin AWS Credentials
```bash
# Contact your AWS administrator for temporary credentials with these policies:
# - PowerUserAccess OR
# - Custom policy with EC2, IAM, ECS, RDS, Lambda, S3 permissions
```

#### Step 1.2: Bootstrap OIDC Infrastructure
```bash
# Configure admin credentials
aws configure --profile bootstrap
export AWS_PROFILE=bootstrap

# Run bootstrap deployment
./scripts/bootstrap-oidc.sh

# Expected output: GitHub Actions role ARN
# Example: arn:aws:iam::554510949034:role/wipsie-github-actions-role
```

#### Step 1.3: Set GitHub Repository Variable
1. Go to: https://github.com/Dinkymoo/learn-work/settings/variables/actions
2. Create variable:
   - Name: `GITHUB_ACTIONS_ROLE_ARN`
   - Value: `<ARN from step 1.2>`

#### Step 1.4: Clean Up Bootstrap Credentials
```bash
unset AWS_PROFILE
aws configure delete --profile bootstrap
```

### Phase 2: Validate Infrastructure Deployment (10 minutes)

#### Step 2.1: Verify Infrastructure in AWS Console
```bash
# Check these resources were created:
# - IAM Roles: wipsie-staging-*
# - VPC: wipsie-staging-vpc
# - ECS Cluster: wipsie-staging-cluster
# - RDS Subnet Groups: wipsie-staging-db-subnet-group
```

#### Step 2.2: Test GitHub Actions OIDC
1. Go to: https://github.com/Dinkymoo/learn-work/actions
2. Run "Infrastructure Deployment" workflow manually
3. Select: staging environment, plan action
4. Verify: No credential errors

### Phase 3: Deploy Lambda Functions (5-10 minutes)

#### Step 3.1: Trigger Lambda Deployment
The Lambda deployment should happen automatically from your develop branch push.
If not:
1. Go to: https://github.com/Dinkymoo/learn-work/actions
2. Find "AWS Lambda Deployment" workflow
3. Re-run if failed, or trigger manually

#### Step 3.2: Verify Lambda Deployment
```bash
# Check AWS Console for:
# - wipsie-staging-data_poller
# - wipsie-staging-task_processor
# Both should be in us-east-1 region
```

#### Step 3.3: Test Lambda Functions
```bash
# Test data_poller
aws lambda invoke \
  --function-name wipsie-staging-data_poller \
  --payload '{"test": true}' \
  response.json
cat response.json

# Test task_processor
aws lambda invoke \
  --function-name wipsie-staging-task_processor \
  --payload '{"task_data": {"type": "email_notification", "id": "test-123", "recipient": "test@example.com", "subject": "Test Email"}}' \
  response.json
cat response.json
```

### Phase 4: Deploy Backend API (20-30 minutes)

#### Step 4.1: Set Up Backend Environment
```bash
# Configure Python environment
cd backend/
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### Step 4.2: Configure Environment Variables
```bash
# Create .env file from example
cp ../.env.example .env

# Update .env with staging values:
# DATABASE_URL=postgresql://user:pass@staging-rds-endpoint/wipsie
# REDIS_URL=redis://staging-redis-endpoint:6379/0
# AWS_REGION=us-east-1
# ENVIRONMENT=staging
```

#### Step 4.3: Run Database Migrations
```bash
# Initialize database
alembic upgrade head

# Verify tables created
psql $DATABASE_URL -c "\dt"
```

#### Step 4.4: Test Backend Locally
```bash
# Start FastAPI server
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Test endpoints (in another terminal)
curl http://localhost:8000/health
curl http://localhost:8000/api/tasks
curl -X POST http://localhost:8000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Task", "description": "Testing API"}'
```

### Phase 5: Deploy to ECS (30-45 minutes)

#### Step 5.1: Build and Push Docker Image
```bash
# Build Docker image
docker build -t wipsie-backend .

# Tag for ECR (replace with your account ID)
docker tag wipsie-backend:latest 554510949034.dkr.ecr.us-east-1.amazonaws.com/wipsie-staging:latest

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 554510949034.dkr.ecr.us-east-1.amazonaws.com

# Push image
docker push 554510949034.dkr.ecr.us-east-1.amazonaws.com/wipsie-staging:latest
```

#### Step 5.2: Deploy ECS Service
```bash
# Update ECS service with new image
aws ecs update-service \
  --cluster wipsie-staging-cluster \
  --service wipsie-staging-backend \
  --force-new-deployment
```

#### Step 5.3: Verify ECS Deployment
```bash
# Check service status
aws ecs describe-services \
  --cluster wipsie-staging-cluster \
  --services wipsie-staging-backend

# Check task health
aws ecs list-tasks --cluster wipsie-staging-cluster
```

### Phase 6: Deploy Frontend (15-20 minutes)

#### Step 6.1: Build Angular Application
```bash
cd frontend/wipsie-app/
npm install
ng build --configuration production
```

#### Step 6.2: Deploy to S3
```bash
# Sync to S3 bucket
aws s3 sync dist/ s3://wipsie-staging-frontend/

# Enable static website hosting
aws s3 website s3://wipsie-staging-frontend \
  --index-document index.html \
  --error-document error.html
```

### Phase 7: End-to-End Testing (30 minutes)

#### Step 7.1: Test Complete Data Flow
```bash
# 1. Test data polling (Lambda)
aws lambda invoke \
  --function-name wipsie-staging-data_poller \
  --payload '{"source": "weather", "location": "London"}' \
  response.json

# 2. Verify data in database
psql $DATABASE_URL -c "SELECT * FROM data_points ORDER BY created_at DESC LIMIT 5;"

# 3. Test task processing
curl -X POST http://staging-alb-endpoint/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Integration Test", "description": "Testing full stack"}'

# 4. Verify task was processed
curl http://staging-alb-endpoint/api/tasks
```

#### Step 7.2: Test Frontend Integration
```bash
# Access frontend
# https://wipsie-staging-frontend.s3-website-us-east-1.amazonaws.com

# Test features:
# - Login/Authentication
# - Dashboard data display
# - Task creation and management
# - Data visualization
```

#### Step 7.3: Test Monitoring and Logs
```bash
# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/wipsie-staging"
aws logs describe-log-groups --log-group-name-prefix "/ecs/wipsie-staging"

# View recent logs
aws logs tail /aws/lambda/wipsie-staging-data_poller --follow
```

### Phase 8: Performance & Security Testing (20 minutes)

#### Step 8.1: Load Testing
```bash
# Install testing tools
pip install locust

# Run basic load test
locust -f tests/load_test.py --host=http://staging-alb-endpoint
```

#### Step 8.2: Security Validation
```bash
# Verify HTTPS enforcement
curl -I http://staging-alb-endpoint
# Should redirect to HTTPS

# Test authentication
curl -X GET http://staging-alb-endpoint/api/protected-endpoint
# Should return 401 without auth token
```

### Phase 9: Production Readiness (15 minutes)

#### Step 9.1: Environment Promotion
```bash
# Create production branch
git checkout main
git merge develop
git push origin main

# This will trigger production deployment pipeline
```

#### Step 9.2: Production Configuration
```bash
# Update production variables:
# - Higher resource limits (CPU/Memory)
# - Production database credentials
# - Production domain configuration
# - Enhanced monitoring and alerting
```

## 📋 Testing Checklist

### ✅ Infrastructure Tests
- [ ] All Terraform resources created successfully
- [ ] OIDC authentication working in GitHub Actions
- [ ] VPC and networking configured correctly
- [ ] Security groups allow proper traffic flow
- [ ] IAM roles have correct permissions

### ✅ Lambda Function Tests
- [ ] data_poller function deploys and executes
- [ ] task_processor function handles different task types
- [ ] Lambda functions can access RDS and other AWS services
- [ ] CloudWatch logs are being generated
- [ ] Error handling works correctly

### ✅ Backend API Tests
- [ ] FastAPI server starts without errors
- [ ] Database migrations run successfully
- [ ] All API endpoints respond correctly
- [ ] Authentication and authorization work
- [ ] Celery tasks are processed

### ✅ Frontend Tests
- [ ] Angular application builds successfully
- [ ] Static assets deploy to S3
- [ ] Frontend can communicate with backend API
- [ ] User interface renders correctly
- [ ] Authentication flow works

### ✅ Integration Tests
- [ ] End-to-end data flow works
- [ ] Frontend → Backend → Database → Lambda flow
- [ ] Task processing pipeline functions
- [ ] Real-time updates work
- [ ] Error scenarios are handled gracefully

### ✅ Security Tests
- [ ] HTTPS enforcement
- [ ] Authentication required for protected endpoints
- [ ] IAM permissions follow least privilege
- [ ] Secrets are properly managed
- [ ] CORS configuration is correct

### ✅ Performance Tests
- [ ] API response times acceptable
- [ ] Database queries optimized
- [ ] Lambda cold start times reasonable
- [ ] Frontend loading times acceptable
- [ ] System handles expected load

## 🎯 Success Criteria

### Staging Environment Complete When:
✅ All infrastructure deployed and healthy
✅ Lambda functions processing data correctly
✅ Backend API serving requests
✅ Frontend accessible and functional
✅ End-to-end data flow working
✅ Monitoring and logging operational
✅ Security measures validated

### Ready for Production When:
✅ All staging tests pass
✅ Performance benchmarks met
✅ Security audit completed
✅ Documentation updated
✅ Team trained on deployment process
✅ Rollback procedures tested

## 🚨 Troubleshooting Common Issues

### Infrastructure Deployment Fails
- Check AWS credentials and permissions
- Verify Terraform state files
- Review CloudFormation events
- Check resource quotas and limits

### Lambda Functions Not Working
- Check function logs in CloudWatch
- Verify IAM role permissions
- Test function locally first
- Check environment variables

### Backend API Issues
- Check ECS task logs
- Verify database connectivity
- Test endpoints individually
- Check environment configuration

### Frontend Not Loading
- Verify S3 bucket configuration
- Check CloudFront distribution
- Test API endpoints from browser
- Review CORS configuration

## 📞 Support Resources

- **AWS Console**: Monitor all resources
- **GitHub Actions**: Check deployment status
- **CloudWatch**: Logs and monitoring
- **Documentation**: All guides in `/docs` folder
- **Team**: Share access to staging environment

This plan should take you from current state to fully deployed and tested staging environment in approximately 2-3 hours! 🚀
