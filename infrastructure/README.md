# Wipsie Infrastructure

This directory contains Terraform configuration files for deploying the Wipsie learning application infrastructure on AWS.

## Structure

- `main.tf` - Main Terraform configuration
- `variables.tf` - Variable definitions
- `outputs.tf` - Output definitions
- `versions.tf` - Provider version constraints
- `staging.tfvars` - Staging environment configuration
- `production.tfvars` - Production environment configuration

## Prerequisites

1. **Terraform** >= 1.0
2. **AWS CLI** configured with appropriate credentials
3. **AWS Account** with sufficient permissions

## Usage

### Staging Environment

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="staging.tfvars"

# Apply changes
terraform apply -var-file="staging.tfvars"
```

### Production Environment

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="production.tfvars"

# Apply changes
terraform apply -var-file="production.tfvars"
```

## Infrastructure Components

Currently, this is a basic setup that will be expanded to include:

- **VPC** with public and private subnets
- **ECS Cluster** for container orchestration
- **RDS** for PostgreSQL database
- **ElastiCache** for Redis
- **Application Load Balancer**
- **CloudFront** distribution
- **S3 buckets** for static assets
- **Lambda functions** for serverless tasks

## Cost Optimization

The staging environment uses smaller instance types and disables NAT Gateway to minimize costs while still providing a production-like environment for testing.

## Security

- All sensitive outputs are marked as `sensitive = true`
- Infrastructure follows AWS security best practices
- Network isolation with private subnets for databases

## Next Steps

1. Implement actual resource definitions in `main.tf`
2. Configure remote state management with S3 backend
3. Add monitoring and logging infrastructure
4. Implement CI/CD deployment automation
