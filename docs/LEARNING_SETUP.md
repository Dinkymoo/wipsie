# 🎓 Wipsie Learning Environment Setup

**Total Monthly Cost: $0.00** ✨

This setup is optimized for **learning purposes** using AWS Free Tier and best practices for educational use.

## 🆓 Free Tier Coverage

All services in this project are covered by AWS Free Tier for the first 12 months:

| Service | Free Tier Limit | Your Usage | Monthly Cost |
|---------|-----------------|------------|--------------|
| 🔧 AWS Lambda | 1M requests + 400K GB-seconds | 5K requests | **$0.00** |
| 📁 Amazon S3 | 5GB + 20K requests | 2GB + 500 requests | **$0.00** |
| 🗄️ Amazon RDS | 750h t3.micro + 20GB | 300h + 15GB | **$0.00** |
| 📬 Amazon SQS | 1M requests | 10K requests | **$0.00** |
| 📧 Amazon SES | 62K emails | 100 emails | **$0.00** |
| 🌐 CloudFront | 1TB + 10M requests | 2GB + 1K requests | **$0.00** |
| ⚙️ GitHub Actions | Unlimited (public repos) | Public workflows | **$0.00** |

## 🎯 Learning Optimization Strategies

### 1. **AWS Account Setup**
```bash
# Create new AWS account (gets 12 months free tier)
# Set up billing alerts immediately
aws budgets put-budget --account-id YOUR_ACCOUNT_ID --budget '{
  "BudgetName": "LearningBudget",
  "BudgetLimit": {"Amount": "5.0", "Unit": "USD"},
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}'
```

### 2. **Cost-Conscious Development**
```bash
# Stop RDS when not coding (saves instance hours)
aws rds stop-db-instance --db-instance-identifier wipsie-learning-db

# Start when you need it
aws rds start-db-instance --db-instance-identifier wipsie-learning-db
```

### 3. **GitHub Repository**
```bash
# Make repository public for free Actions
git remote set-url origin https://github.com/yourusername/wipsie-learning.git
# Public repos get unlimited GitHub Actions minutes
```

### 4. **Resource Cleanup Script**
```bash
#!/bin/bash
# cleanup-learning-session.sh
echo "🧹 Cleaning up learning session..."

# Stop RDS
aws rds stop-db-instance --db-instance-identifier wipsie-learning-db

# Remove test S3 objects (keep bucket)
aws s3 rm s3://wipsie-learning-bucket/test-data/ --recursive

# Clear SQS test messages
aws sqs purge-queue --queue-url https://sqs.region.amazonaws.com/account/test-queue

echo "✅ Cleanup complete - costs minimized!"
```

## 📚 Learning Progression Path

### **Phase 1: Foundation ($0/month)**
- Set up AWS account and free tier
- Deploy basic Lambda functions
- Create S3 bucket for frontend
- Set up RDS database (t3.micro)
- Configure basic CI/CD pipeline

### **Phase 2: Development ($3-5/month)**
- After free tier expires or for advanced features
- Use larger instance sizes for testing
- Add monitoring and logging
- Implement advanced AWS services

### **Phase 3: Portfolio Project ($10-15/month)**
- Production-ready deployment
- Custom domain and SSL
- Advanced security features
- Performance optimization

### **Phase 4: Professional Skills ($30+/month)**
- Multi-environment setup
- Enterprise patterns
- High availability
- Advanced monitoring

## ⚠️ Important Learning Notes

### **Free Tier Limits (Track These!)**
- **RDS**: 750 hours/month (stop when not coding!)
- **Lambda**: 1M requests/month (plenty for learning)
- **S3**: 5GB storage (use small test files)
- **Data Transfer**: 15GB/month (optimize images)

### **Billing Alerts Setup**
```bash
# Set up multiple alert levels
aws cloudwatch put-metric-alarm \
  --alarm-name "Learning-Cost-Alert-1USD" \
  --alarm-description "Alert when costs exceed $1" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 1.0 \
  --comparison-operator GreaterThanThreshold
```

### **Daily Learning Checklist**
- [ ] Check AWS Cost Explorer for current spending
- [ ] Stop RDS instance when finished coding
- [ ] Use minimal test data sets
- [ ] Clean up temporary resources
- [ ] Monitor free tier usage

## 🚀 Getting Started Commands

```bash
# 1. Cost estimation
python tools/cost-estimation/simple_cost_estimator.py learning

# 2. Deploy learning environment
npm run deploy:learning

# 3. Start development session
./scripts/start-learning-session.sh

# 4. End development session
./scripts/cleanup-learning-session.sh
```

## 💡 Pro Learning Tips

1. **Use AWS CloudShell** - Free terminal in AWS console
2. **AWS Educate** - Additional credits for students
3. **GitHub Student Pack** - Extra GitHub Actions minutes
4. **Local Development** - Use LocalStack for offline testing
5. **Documentation** - Keep detailed notes of what you learn

## 🎉 Success Metrics

By the end of your learning journey, you'll have:

- ✅ Built a full-stack serverless application
- ✅ Mastered AWS core services
- ✅ Implemented CI/CD pipelines
- ✅ Understanding of cloud costs and optimization
- ✅ Portfolio-ready project for job interviews

**Total Learning Cost: $0-60** (spread over 3-6 months)

---

*Remember: The goal is learning, not perfection. Start simple, experiment freely, and scale up as you gain confidence!*
