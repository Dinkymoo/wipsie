# Wipsie Cost Optimization Quick Reference

## 🎯 **85% Cost Reduction Achieved**
- **Before**: $87-91/month
- **After**: $13-18/month  
- **Savings**: $74-78/month

## 🔧 **Quick Commands**

### Apply Maximum Savings
```bash
cd infrastructure
terraform apply -var-file=ultra-budget.tfvars -auto-approve
```

### Enable Specific Services
```bash
# Database learning (+$13/month)
terraform apply -var="enable_rds=true"

# Load balancer learning (+$16/month)  
terraform apply -var="enable_alb=true"

# Caching learning (+$12/month)
terraform apply -var="enable_redis=true"

# Private networking learning (+$45/month)
terraform apply -var="enable_nat_gateway=true"

# CDN learning (+$1-5/month)
terraform apply -var="enable_cloudfront=true"
```

### Check Current Status
```bash
terraform output | grep -E "(nat_gateway|application_load_balancer|cloudfront|redis)"
```

## 💡 **What's Still Running**
- ✅ **RDS PostgreSQL** ($13/month) - Database
- ✅ **ECS Cluster** (free tier) - Containers  
- ✅ **Lambda Functions** (pay-per-use) - Serverless
- ✅ **S3 Buckets** (~$1-3/month) - Storage
- ✅ **SQS Queues** (free) - Messaging
- ✅ **VPC + Security Groups** (free) - Networking

## 📚 **Learning Alternatives**
- **Load Balancing**: nginx in Docker or direct ECS access
- **Caching**: In-memory or Redis in Docker
- **CDN**: Direct S3 serving or Cloudflare free tier
- **Private Networking**: Public subnets with security groups

## 📊 **Progressive Learning Path**
1. **Week 1-2**: Ultra-budget (~$13-18/month)
2. **Week 3-4**: +RDS (~$26-31/month) 
3. **Week 5-6**: +ALB (~$42-47/month)
4. **Week 7-8**: +Redis (~$54-59/month)
5. **Week 9-10**: +NAT+CloudFront (~$99-104/month)

## 🎓 **Perfect for Learning**
- All core AWS concepts preserved
- Budget-friendly for extended learning
- Easy service re-enablement
- Production vs. cost-optimized architecture comparison

---
*See [COST_OPTIMIZATION_COMPLETE.md](./COST_OPTIMIZATION_COMPLETE.md) for full documentation*
