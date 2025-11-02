# 🚀 Wipsie Full-Stack Deployment Plan

## 🎯 Current Status
- ✅ Aurora PostgreSQL cluster: `wipsie-learning-aurora` (deployed)
- ✅ Backend: FastAPI with SQLAlchemy ORM (ready)
- ✅ Frontend: Angular 17 with dashboard (ready)
- ✅ Infrastructure: Terraform configuration (ready)

## 🚀 Deployment Strategy: Budget-Optimized with Aurora

### **Phase 1: Frontend Deployment (Angular)**
1. **Build for Production**
   - Angular production build with optimization
   - Configure API endpoints for direct Aurora connection
   - Static asset optimization

2. **Deploy to S3 + CloudFront**
   - **Static hosting**: S3 bucket for Angular build
   - **CDN**: CloudFront for global distribution
   - **Cost**: ~$1-5/month (much cheaper than ECS)

### **Phase 2: Backend API (Simplified)**
1. **Option A: Lambda Functions** (Recommended)
   - Convert FastAPI endpoints to AWS Lambda
   - API Gateway for routing
   - Cost: Pay-per-request (~$0-10/month)

2. **Option B: EC2 Micro Instance**
   - Single t3.micro instance (free tier eligible)
   - Direct FastAPI deployment
   - Cost: $0-8/month

### **Phase 3: Database Setup**
1. **Connect to Aurora**
   - Update backend configuration for Aurora connection
   - Run Alembic migrations on Aurora
   - Populate with production data

## 🛠️ Implementation Steps (Budget-Optimized)

### Step 1: Deploy Frontend to S3 + CloudFront
```bash
# Build Angular for production
cd frontend/wipsie-app
npm run build:prod

# Deploy to S3
aws s3 sync dist/wipsie-app/ s3://your-bucket-name --delete

# Setup CloudFront distribution
aws cloudfront create-distribution --distribution-config file://cloudfront-config.json
```

### Step 2: Deploy Backend as Lambda (Option A)
```bash
# Package FastAPI as Lambda
cd backend
pip install -r requirements.txt -t package/
cp -r . package/
cd package && zip -r ../lambda-backend.zip .

# Deploy via Terraform or AWS CLI
aws lambda create-function --function-name wipsie-backend --runtime python3.11 --zip-file fileb://lambda-backend.zip
```

### Step 3: Deploy Backend to EC2 (Option B)
```bash
# Connect to EC2 instance
ssh -i your-key.pem ec2-user@your-instance

# Clone and setup
git clone your-repo
cd backend
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Step 4: Database Migration
```bash
# Connect to Aurora and migrate
cd backend
alembic upgrade head
python populate_database.py
```

## 🔧 Configuration Requirements (Budget Setup)

### **Environment Variables for Backend (Lambda/EC2)**
```env
DATABASE_URL=postgresql://postgres:WipsieAurora2024!@wipsie-learning-aurora.cluster-xxx.us-east-1.rds.amazonaws.com:5432/wipsie
CORS_ORIGINS=https://your-cloudfront-domain.cloudfront.net
LOG_LEVEL=INFO
AWS_REGION=us-east-1
```

### **Environment Variables for Frontend**
```typescript
export const environment = {
  production: true,
  apiUrl: 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod/api/v1'
  // OR for EC2: 'http://your-ec2-public-ip:8000/api/v1'
};
```

## 💰 Cost Estimate (Budget-Optimized)
- **Aurora Serverless v2**: $15-25/month (existing)
- **S3 + CloudFront**: $1-5/month
- **API Gateway + Lambda**: $0-10/month (pay-per-request)
- **OR EC2 t3.micro**: $0-8/month (free tier eligible)
- **Total**: ~$16-40/month (vs $40-65 with ECS+ALB)

## 🔐 Security Considerations (Simplified)
- ✅ Aurora in private subnets (existing)
- ✅ CloudFront HTTPS encryption
- ✅ Lambda/EC2 with IAM roles
- ✅ Environment variable secrets
- ✅ Database connection encryption
- ⚠️ No load balancer (single point of failure for EC2 option)
- ✅ Environment variable secrets
- ✅ Database connection encryption

## 🚦 Next Steps (Budget-Optimized)

**Ready to deploy? Choose your backend approach:**

1. **Lambda + API Gateway** (Recommended for learning)
   - Serverless, pay-per-request
   - Auto-scaling, no server management
   - Cost: ~$16-35/month total

2. **EC2 t3.micro** (Free tier eligible)
   - Traditional server deployment
   - Always-on, simple setup
   - Cost: ~$16-33/month total

3. **Local Development Only**
   - Keep using local PostgreSQL
   - Frontend deployed to S3/CloudFront
   - Cost: ~$1-5/month total

**Cost savings by removing ECS Fargate + Load Balancer: ~$25-30/month**

Which budget approach would you like to take?
