# Outputs for Wipsie Infrastructure

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "availability_zones" {
  description = "Available AWS availability zones"
  value       = data.aws_availability_zones.available.names
}

# Placeholder outputs for future infrastructure
# These will be updated when actual resources are created

output "vpc_id" {
  description = "ID of the VPC (placeholder)"
  value       = "vpc-placeholder-${var.environment}"
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC (placeholder)"
  value       = var.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (placeholder)"
  value       = ["subnet-placeholder-public-1-${var.environment}", "subnet-placeholder-public-2-${var.environment}"]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (placeholder)"
  value       = ["subnet-placeholder-private-1-${var.environment}", "subnet-placeholder-private-2-${var.environment}"]
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group (placeholder)"
  value       = "wipsie-${var.environment}-db-subnet-group"
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster (placeholder)"
  value       = "wipsie-${var.environment}-cluster"
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster (placeholder)"
  value       = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/wipsie-${var.environment}-cluster"
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer (placeholder)"
  value       = "wipsie-${var.environment}-alb.${var.aws_region}.elb.amazonaws.com"
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer (placeholder)"
  value       = "Z35SXDOTRQ7X7K" # Example ALB zone ID for us-east-1
}

output "rds_endpoint" {
  description = "RDS instance endpoint (placeholder)"
  value       = "wipsie-${var.environment}-db.${random_id.db_suffix.hex}.${var.aws_region}.rds.amazonaws.com"
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis cluster endpoint (placeholder)"
  value       = "wipsie-${var.environment}-redis.${random_id.redis_suffix.hex}.cache.amazonaws.com"
  sensitive   = true
}
