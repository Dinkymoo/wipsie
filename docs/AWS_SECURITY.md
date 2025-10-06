# 🔐 AWS Security Guide for Wipsie

## Overview
This document outlines secure practices for setting up and managing AWS credentials and SQS queues for the Wipsie application.

## ⚠️ **SECURITY WARNINGS**

### ❌ **NEVER DO THIS:**
- ❌ Commit `.env` files to version control
- ❌ Hard-code AWS credentials in source code
- ❌ Use root AWS account credentials
- ❌ Share AWS access keys via email/chat
- ❌ Use overly broad IAM permissions
- ❌ Leave unused access keys active

### ✅ **ALWAYS DO THIS:**
- ✅ Use IAM users with minimal required permissions
- ✅ Rotate access keys regularly
- ✅ Use environment variables for credentials
- ✅ Enable CloudTrail for audit logging
- ✅ Monitor AWS usage and billing
- ✅ Use AWS IAM policies with least privilege

## 🔑 **Secure AWS Setup**

### **Step 1: Create IAM User with Minimal Permissions**

#### **Recommended IAM Policy (Least Privilege):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:CreateQueue",
        "sqs:DeleteQueue",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ListQueues",
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:PurgeQueue",
        "sqs:ChangeMessageVisibility"
      ],
      "Resource": [
        "arn:aws:sqs:*:*:wipsie-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ListQueues"
      ],
      "Resource": "*"
    }
  ]
}
```

#### **Policy Explanation:**
- **Resource Restriction**: Only allows access to queues starting with `wipsie-`
- **Action Limitation**: Only SQS operations needed for Celery
- **No Admin Rights**: Cannot create/delete other AWS resources

### **Step 2: Secure Credential Management**

#### **Environment Variables (Recommended for Development):**
```bash
# In .env file (NEVER commit this file)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

#### **AWS CLI Profile (Alternative):**
```bash
# Configure AWS CLI with profile
aws configure --profile wipsie-dev
# Then use: export AWS_PROFILE=wipsie-dev
```

#### **Production Alternatives:**
- **AWS ECS/EC2**: Use IAM roles instead of access keys
- **AWS Lambda**: Use execution roles
- **Kubernetes**: Use AWS IAM Roles for Service Accounts (IRSA)

### **Step 3: .gitignore Configuration**

Ensure your `.gitignore` includes:
```gitignore
# Environment files
.env
.env.local
.env.production
*.env

# AWS credentials
.aws/credentials
.aws/config

# Logs that might contain sensitive data
*.log
logs/
```

## 🛡️ **Security Monitoring**

### **CloudTrail Setup** (Recommended for Production)
1. Enable AWS CloudTrail in your account
2. Monitor SQS API calls
3. Set up alerts for unusual activity

### **Cost Monitoring**
1. Set up AWS Billing Alerts
2. Monitor SQS usage in AWS Console
3. Review monthly AWS bills

### **Access Key Rotation**
```bash
# Rotate access keys every 90 days
# 1. Create new access key
# 2. Update applications
# 3. Test thoroughly
# 4. Delete old access key
```

## 🔧 **Development vs Production**

### **Development Environment:**
- Use IAM user with limited SQS permissions
- Store credentials in `.env` file (not committed)
- Use development-specific queue names (`wipsie-dev-*`)
- Default region: `us-east-1` (Ireland)

### **Production Environment:**
- Use IAM roles instead of access keys when possible
- Use AWS Systems Manager Parameter Store or AWS Secrets Manager
- Implement proper logging and monitoring
- Use production queue names (`wipsie-prod-*`)
- Consider region selection based on your users' location

## 📋 **Security Checklist**

### **Initial Setup:**
- [ ] Created IAM user with minimal permissions
- [ ] Generated access keys
- [ ] Configured `.env` file
- [ ] Added `.env` to `.gitignore`
- [ ] Tested SQS connection
- [ ] Created required queues

### **Ongoing Security:**
- [ ] Rotate access keys every 90 days
- [ ] Monitor AWS usage monthly
- [ ] Review IAM permissions quarterly
- [ ] Update dependencies regularly
- [ ] Monitor CloudTrail logs (if enabled)

### **Production Deployment:**
- [ ] Use IAM roles instead of access keys
- [ ] Enable CloudTrail logging
- [ ] Set up billing alerts
- [ ] Configure proper VPC security groups
- [ ] Enable AWS Config rules
- [ ] Implement secret rotation

## 🚨 **Incident Response**

### **If Credentials are Compromised:**
1. **Immediately**: Disable the compromised access key in AWS Console
2. **Generate**: New access keys
3. **Update**: All applications with new credentials
4. **Monitor**: CloudTrail logs for unauthorized activity
5. **Review**: Recent AWS usage and billing
6. **Report**: If required by your organization's security policy

### **Emergency Contacts:**
- AWS Support: [AWS Support Center](https://console.aws.amazon.com/support/)
- AWS Abuse: abuse@amazonaws.com

## 📚 **Additional Resources**

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS SQS Security](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-security.html)
- [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)

---

## ⚡ **Quick Reference**

### **Check Current Setup:**
```bash
# Test AWS connection
python -c "import boto3; print(boto3.client('sts').get_caller_identity())"

# List SQS queues
python scripts/setup_sqs.py
```

### **Troubleshooting:**
```bash
# Check environment variables
echo $AWS_ACCESS_KEY_ID
echo $AWS_REGION

# Test specific queue
aws sqs get-queue-url --queue-name wipsie-default
```

**Remember: Security is everyone's responsibility! 🛡️**
