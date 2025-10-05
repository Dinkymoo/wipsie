# ====================================================================
# WIPSIE INFRASTRUCTURE OUTPUTS
# ====================================================================
# This file defines output values that can be used by other systems,
# CI/CD pipelines, or for debugging and validation purposes.

# ====================================================================
# CORE INFRASTRUCTURE OUTPUTS
# ====================================================================

output "aws_region" {
  description = "AWS region where infrastructure is deployed"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name (staging/production)"
  value       = var.environment
}

output "project_name" {
  description = "Project name used for resource naming"
  value       = var.project_name
}

output "account_id" {
  description = "AWS Account ID where resources are deployed"
  value       = data.aws_caller_identity.current.account_id
}

output "availability_zones" {
  description = "List of available AWS availability zones in the region"
  value       = data.aws_availability_zones.available.names
}

# ====================================================================
# NETWORKING OUTPUTS (PLACEHOLDER - TO BE IMPLEMENTED)
# ====================================================================
# These outputs will be updated when actual VPC resources are created

output "vpc_id" {
  description = "ID of the VPC (placeholder until VPC is created)"
  value       = "vpc-placeholder-${var.environment}"
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = var.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (placeholder until subnets are created)"
  value = [
    "subnet-placeholder-public-1-${var.environment}",
    "subnet-placeholder-public-2-${var.environment}"
  ]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (placeholder until subnets are created)"
  value = [
    "subnet-placeholder-private-1-${var.environment}",
    "subnet-placeholder-private-2-${var.environment}"
  ]
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group (placeholder until created)"
  value       = "wipsie-${var.environment}-db-subnet-group"
}

# ====================================================================
# COMPUTE OUTPUTS (PLACEHOLDER - TO BE IMPLEMENTED)
# ====================================================================

output "ecs_cluster_name" {
  description = "Name of the ECS cluster (placeholder until cluster is created)"
  value       = "wipsie-${var.environment}-cluster"
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster (placeholder until cluster is created)"
  value       = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/wipsie-${var.environment}-cluster"
}

output "load_balancer_dns_name" {
  description = "DNS name of the application load balancer (placeholder until ALB is created)"
  value       = "wipsie-${var.environment}-alb.${var.aws_region}.elb.amazonaws.com"
}

output "load_balancer_zone_id" {
  description = "Hosted zone ID of the load balancer for Route 53 alias records"
  value       = "Z35SXDOTRQ7X7K" # Standard ALB zone ID for us-east-1 (will be dynamic when ALB is created)
}

# ====================================================================
# DATABASE OUTPUTS (PLACEHOLDER - TO BE IMPLEMENTED)
# ====================================================================

output "rds_endpoint" {
  description = "RDS PostgreSQL instance endpoint (placeholder until RDS is created)"
  value       = "wipsie-${var.environment}-db.${random_id.db_suffix.hex}.${var.aws_region}.rds.amazonaws.com"
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis cluster primary endpoint (placeholder until ElastiCache is created)"
  value       = "wipsie-${var.environment}-redis.${random_id.redis_suffix.hex}.cache.amazonaws.com"
  sensitive   = true
}

# ====================================================================
# SECURITY OUTPUTS (PLACEHOLDER - TO BE IMPLEMENTED)
# ====================================================================

output "app_security_group_id" {
  description = "Security group ID for application servers (placeholder)"
  value       = "sg-placeholder-app-${var.environment}"
}

output "database_security_group_id" {
  description = "Security group ID for database servers (placeholder)"
  value       = "sg-placeholder-db-${var.environment}"
}

output "secrets_manager_arn" {
  description = "ARN of Secrets Manager secret for database credentials (placeholder)"
  value       = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:wipsie-${var.environment}-db-credentials"
  sensitive   = true
}

# ====================================================================
# INTEGRATION OUTPUTS
# ====================================================================
# These outputs are designed for integration with CI/CD pipelines and external systems

output "deployment_info" {
  description = "Key information for deployment scripts and CI/CD pipelines"
  value = {
    region             = var.aws_region
    environment        = var.environment
    vpc_cidr           = var.vpc_cidr
    rds_instance_class = var.rds_instance_class
    ecs_cpu            = var.ecs_task_cpu
    ecs_memory         = var.ecs_task_memory
    db_suffix          = random_id.db_suffix.hex
    redis_suffix       = random_id.redis_suffix.hex
  }
}

# ====================================================================
# COST TRACKING OUTPUTS
# ====================================================================

output "cost_allocation_tags" {
  description = "Tags for cost allocation and tracking"
  value = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CostCenter  = "Engineering"
  }
}
