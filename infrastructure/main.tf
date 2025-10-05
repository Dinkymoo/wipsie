# Wipsie Infrastructure - Main Configuration
# This file defines the core infrastructure for the Wipsie learning application
# 
# Architecture Overview:
# ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
# │   CloudFront    │    │   Application   │    │    Database     │
# │   (Frontend)    │◄──►│  Load Balancer  │◄──►│      Layer      │
# └─────────────────┘    └─────────────────┘    └─────────────────┘
#          │                       │                       │
#          │                       │                       │
#     ┌─────────┐              ┌─────────┐          ┌─────────────┐
#     │   S3    │              │   ECS   │          │     RDS     │
#     │ Bucket  │              │ Cluster │          │ PostgreSQL  │
#     └─────────┘              └─────────┘          └─────────────┘
#                                   │                       │
#                                   │                ┌─────────────┐
#                              ┌─────────┐          │    Redis    │
#                              │ Lambda  │          │   Cache     │
#                              │Functions│          └─────────────┘
#                              └─────────┘
#                                   │
#                              ┌─────────┐
#                              │   SQS   │
#                              │ Queues  │
#                              └─────────┘
#
# Current Status: Foundation setup with basic AWS provider and data sources
# Next Steps: Implement VPC, ECS, RDS, and Lambda infrastructure

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "wipsie"
    }
  }
}

# Data sources for infrastructure discovery
data "aws_availability_zones" "available" {
  state = "available"

  # Filter out wavelength zones and local zones for cost optimization
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {
  # Used for constructing ARNs and resource naming
}

# Random resources for unique naming to avoid conflicts
resource "random_id" "db_suffix" {
  byte_length = 4

  keepers = {
    # Regenerate when environment changes
    environment = var.environment
  }
}

resource "random_id" "redis_suffix" {
  byte_length = 4

  keepers = {
    # Regenerate when environment changes
    environment = var.environment
  }
}

# ====================================================================
# PLANNED INFRASTRUCTURE COMPONENTS
# ====================================================================
# 
# The following resources will be implemented in future iterations:
#
# 1. NETWORKING
#    - VPC with public and private subnets across multiple AZs
#    - Internet Gateway and NAT Gateways
#    - Route tables and security groups
#    - VPC endpoints for AWS services
#
# 2. COMPUTE
#    - ECS Cluster with Fargate capacity providers
#    - Application Load Balancer with HTTPS termination
#    - Auto Scaling policies based on CPU and memory
#    - CloudWatch monitoring and alerting
#
# 3. DATABASE
#    - RDS PostgreSQL with Multi-AZ for production
#    - ElastiCache Redis for session storage and caching
#    - Database subnet groups and parameter groups
#    - Automated backups and encryption
#
# 4. SERVERLESS
#    - Lambda functions for background processing
#    - SQS queues for async task processing
#    - EventBridge for event-driven architecture
#    - API Gateway for external integrations
#
# 5. STORAGE
#    - S3 buckets for static assets and file uploads
#    - CloudFront distribution for global CDN
#    - S3 lifecycle policies for cost optimization
#
# 6. SECURITY
#    - AWS Secrets Manager for sensitive configuration
#    - KMS keys for encryption
#    - WAF for application protection
#    - CloudTrail for audit logging
#
# 7. MONITORING
#    - CloudWatch dashboards and alarms
#    - X-Ray for distributed tracing
#    - AWS Config for compliance monitoring
#
# ====================================================================

# Locals for computed values and resource naming
locals {
  # Common resource naming convention
  name_prefix = "${var.project_name}-${var.environment}"

  # Database configuration
  db_name = "${var.project_name}_${var.environment}"

  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedBy   = data.aws_caller_identity.current.user_id
    Repository  = "wipsie"
  }
}

# ====================================================================
# OUTPUTS FOR DEBUGGING AND VALIDATION
# ====================================================================

# Debug output to verify configuration
output "debug_info" {
  description = "Debug information for infrastructure setup"
  value = {
    aws_region         = var.aws_region
    environment        = var.environment
    availability_zones = data.aws_availability_zones.available.names
    account_id         = data.aws_caller_identity.current.account_id
    db_suffix          = random_id.db_suffix.hex
    redis_suffix       = random_id.redis_suffix.hex
    name_prefix        = local.name_prefix
  }
}
