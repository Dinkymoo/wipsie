# 🏗️ Wipsie Infrastructure Documentation

This directory contains the Terraform Infrastructure as Code (IaC) for the **Wipsie** learning application. The infrastructure is designed to be cloud-native, scalable, and follows AWS best practices.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [File Structure](#file-structure)
- [Infrastructure Components](#infrastructure-components)
- [Environment Configuration](#environment-configuration)
- [Deployment Guide](#deployment-guide)
- [Cost Optimization](#cost-optimization)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

The Wipsie infrastructure is a **multi-tier architecture** designed for a full-stack learning application with:

- **Frontend**: Angular SPA hosted on S3/CloudFront
- **Backend**: FastAPI application running on ECS
- **Database**: PostgreSQL on RDS with Redis for caching
- **Serverless**: AWS Lambda functions for background processing
- **Messaging**: SQS for asynchronous task processing

## 🏛️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CloudFront    │    │   Application   │    │    Database     │
│   (Frontend)    │◄──►│  Load Balancer  │◄──►│      Layer      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
    ┌─────────┐              ┌─────────┐          ┌─────────────┐
    │   S3    │              │   ECS   │          │     RDS     │
    │ Bucket  │              │ Cluster │          │ PostgreSQL  │
    └─────────┘              └─────────┘          └─────────────┘
                                  │                       │
                                  │                ┌─────────────┐
                             ┌─────────┐          │    Redis    │
                             │ Lambda  │          │   Cache     │
                             │Functions│          └─────────────┘
                             └─────────┘
                                  │
                             ┌─────────┐
                             │   SQS   │
                             │ Queues  │
                             └─────────┘
```

## 📁 File Structure

```
infrastructure/
├── README.md           # This documentation file
├── main.tf            # Core infrastructure configuration
├── variables.tf       # Input variable definitions
├── outputs.tf         # Output value definitions
├── versions.tf        # Provider version constraints
└── modules/           # Reusable Terraform modules (planned)
    ├── vpc/
    ├── ecs/
    ├── rds/
    └── lambda/
```

## 🔧 Infrastructure Components

### Core Configuration (`main.tf`)

The main configuration file defines:

```hcl
# AWS Provider Configuration
provider "aws" {
  region = var.aws_region  # Default: us-east-1
}

# Data Sources
data "aws_availability_zones" "available"    # Available AZs
data "aws_caller_identity" "current"         # AWS Account Info

# Random Resources for Unique Naming
resource "random_id" "db_suffix"             # Database naming
resource "random_id" "redis_suffix"          # Redis naming
```

**Key Features:**
- ✅ Multi-AZ deployment support
- ✅ Unique resource naming with random suffixes
- ✅ Environment-agnostic configuration

### Variables (`variables.tf`)

**Environment Variables:**
- `aws_region`: AWS deployment region (default: `us-east-1`)
- `environment`: Environment name with validation (`staging` | `production`)
- `project_name`: Project identifier (default: `wipsie`)

**Network Configuration:**
- `vpc_cidr`: VPC CIDR block (default: `10.0.0.0/16`)
- `enable_nat_gateway`: NAT Gateway for private subnets (default: `true`)

**Database Configuration:**
- `rds_instance_class`: RDS instance type (default: `db.t3.micro`)

**Compute Configuration:**
- `ecs_task_cpu`: ECS task CPU units (default: `256`)
- `ecs_task_memory`: ECS task memory in MB (default: `512`)

### Outputs (`outputs.tf`)

**Infrastructure Outputs:**
- Account and region information
- Network identifiers (VPC, subnets)
- Service endpoints (RDS, Redis, ECS)
- Load balancer configuration

**Current Status:** 
- 🚧 Outputs are currently **placeholder values**
- 📋 Will be updated when actual resources are created

## 🌍 Environment Configuration

### Staging Environment
```bash
environment = "staging"
rds_instance_class = "db.t3.micro"
enable_nat_gateway = true
```

### Production Environment
```bash
environment = "production"
rds_instance_class = "db.t3.small"  # Larger instance
enable_nat_gateway = true
ecs_task_cpu = 512                   # More CPU
ecs_task_memory = 1024              # More memory
```

## 🚀 Deployment Guide

### Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS credentials** set up (IAM user or role)

### Required IAM Permissions

The deploying user/role needs permissions for:
- EC2 (VPC, subnets, security groups)
- RDS (database instances, subnet groups)
- ECS (clusters, services, task definitions)
- Lambda (functions, permissions)
- SQS (queues, permissions)
- S3 (buckets for state storage)

### Deployment Steps

1. **Initialize Terraform:**
   ```bash
   cd infrastructure/
   terraform init
   ```

2. **Plan Infrastructure:**
   ```bash
   terraform plan -var="environment=staging"
   ```

3. **Apply Infrastructure:**
   ```bash
   terraform apply -var="environment=staging"
   ```

4. **Verify Deployment:**
   ```bash
   terraform output
   ```

### Environment-Specific Deployment

**Staging:**
```bash
terraform apply -var-file="staging.tfvars"
```

**Production:**
```bash
terraform apply -var-file="production.tfvars"
```

## 💰 Cost Optimization

### Current Cost Profile

**Estimated Monthly Costs (Staging):**
- RDS db.t3.micro: ~$13/month
- ECS Fargate (minimal): ~$15/month
- Lambda (first 1M requests free): $0
- SQS (first 1M requests free): $0
- **Total: ~$30/month**

**Production Scaling:**
- RDS db.t3.small: ~$25/month
- ECS Fargate (scaled): ~$45/month
- **Total: ~$75/month**

### Cost Optimization Features

- 🎯 **Right-sized instances** for each environment
- 🕐 **Auto-scaling** for ECS services
- 💾 **Spot instances** for non-critical workloads (planned)
- 📊 **CloudWatch monitoring** for cost tracking

## 🔒 Security Considerations

### Network Security
- **VPC isolation** with private subnets
- **Security groups** with least-privilege access
- **NAT Gateway** for secure outbound access
- **Private database subnets**

### Data Protection
- **RDS encryption** at rest and in transit
- **Redis encryption** for cache data
- **S3 bucket encryption** for static assets
- **Secrets Manager** for sensitive configuration

### Access Control
- **IAM roles** for service-to-service communication
- **No hardcoded credentials** in configuration
- **Environment-specific secrets**

## 🔍 Troubleshooting

### Common Issues

**1. Terraform State Lock**
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

**2. Provider Authentication**
```bash
# Verify AWS credentials
aws sts get-caller-identity
```

**3. Resource Limits**
- Check AWS service quotas
- Verify AZ availability for instance types

### Validation Commands

**Terraform Validation:**
```bash
terraform validate
terraform fmt -check
terraform plan -detailed-exitcode
```

**AWS Resource Verification:**
```bash
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=staging"
aws rds describe-db-instances
aws ecs list-clusters
```

## 📈 Future Enhancements

### Planned Infrastructure
- [ ] **Auto Scaling Groups** for ECS services
- [ ] **CloudWatch Dashboards** for monitoring
- [ ] **AWS WAF** for application protection
- [ ] **Route 53** for DNS management
- [ ] **Certificate Manager** for SSL/TLS
- [ ] **Backup strategies** for RDS and S3

### Modularization
- [ ] Split into reusable Terraform modules
- [ ] Environment-specific variable files
- [ ] Remote state management with S3 backend
