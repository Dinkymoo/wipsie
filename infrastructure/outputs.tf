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
# NETWORKING OUTPUTS
# ====================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways (single NAT for cost optimization)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[*].id : []
}

# ====================================================================
# COMPUTE OUTPUTS
# ====================================================================

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "application_load_balancer_dns" {
  description = "DNS name of the Application Load Balancer (empty if ALB disabled)"
  value       = var.enable_alb ? aws_lb.main[0].dns_name : ""
}

output "application_load_balancer_arn" {
  description = "ARN of the Application Load Balancer (empty if ALB disabled)"
  value       = var.enable_alb ? aws_lb.main[0].arn : ""
}

# output "ecs_service_name" {
#   description = "Name of the ECS service"
#   value       = aws_ecs_service.backend.name
# }

# ====================================================================
# DATABASE OUTPUTS
# ====================================================================

output "rds_endpoint" {
  description = "RDS PostgreSQL instance endpoint"
  value       = var.enable_database ? aws_db_instance.main[0].endpoint : null
  sensitive   = true
}

output "rds_database_name" {
  description = "Name of the database"
  value       = var.enable_database ? aws_db_instance.main[0].db_name : var.db_name
}

output "redis_endpoint" {
  description = "Redis cluster primary endpoint (empty if Redis disabled)"
  value       = var.enable_redis ? aws_elasticache_replication_group.main[0].primary_endpoint_address : ""
  sensitive   = true
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = aws_db_subnet_group.main.name
}

# ====================================================================
# SECURITY OUTPUTS
# ====================================================================

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs.id
}

output "database_security_group_id" {
  description = "Security group ID for database servers"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "Security group ID for Redis cluster"
  value       = aws_security_group.redis.id
}

output "lambda_security_group_id" {
  description = "Security group ID for Lambda functions"
  value       = aws_security_group.lambda.id
}

# ====================================================================
# LAMBDA OUTPUTS
# ====================================================================

# output "lambda_data_poller_arn" {
#   description = "ARN of the data poller Lambda function"
#   value       = aws_lambda_function.data_poller.arn
# }

# output "lambda_task_processor_arn" {
#   description = "ARN of the task processor Lambda function"
#   value       = aws_lambda_function.task_processor.arn
# }

output "sqs_task_queue_url" {
  description = "URL of the main task queue"
  value       = aws_sqs_queue.task_queue.url
}

output "sqs_dlq_url" {
  description = "URL of the dead letter queue"
  value       = aws_sqs_queue.task_dlq.url
}

# ====================================================================
# S3 AND CLOUDFRONT OUTPUTS
# ====================================================================

output "s3_frontend_bucket" {
  description = "Name of the S3 bucket for frontend assets"
  value       = aws_s3_bucket.frontend.bucket
}

output "s3_lambda_deployments_bucket" {
  description = "Name of the S3 bucket for Lambda deployment packages"
  value       = aws_s3_bucket.lambda_deployments.bucket
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution (empty if CloudFront disabled)"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].id : ""
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution (empty if CloudFront disabled)"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].domain_name : ""
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

# ====================================================================
# IAM ROLES OUTPUTS - Commented out due to IAM permissions
# ====================================================================

# output "ecs_task_execution_role_arn" {
#   description = "ARN of the ECS task execution role"
#   value       = aws_iam_role.ecs_task_execution_role.arn
# }

# output "ecs_task_role_arn" {
#   description = "ARN of the ECS task role for application runtime"
#   value       = aws_iam_role.ecs_task_role.arn
# }

# output "lambda_execution_role_arn" {
#   description = "ARN of the Lambda execution role"
#   value       = aws_iam_role.lambda_execution_role.arn
# }

# output "ec2_instance_profile_name" {
#   description = "Name of the EC2 instance profile"
#   value       = aws_iam_instance_profile.ec2_instance_profile.name
# }

# output "ec2_instance_role_arn" {
#   description = "ARN of the EC2 instance role"
#   value       = aws_iam_role.ec2_instance_role.arn
# }

# GitHub Actions role output - commented out due to IAM permissions
# output "github_actions_role_arn" {
#   description = "ARN of the GitHub Actions role for CI/CD"
#   value       = aws_iam_role.github_actions_role.arn
#   sensitive   = true
# }

# output "iam_roles_summary" {
#   description = "Summary of all IAM roles created for secure access"
#   value = {
#     ecs_task_execution_role = aws_iam_role.ecs_task_execution_role.name
#     ecs_task_role           = aws_iam_role.ecs_task_role.name
#     lambda_execution_role   = aws_iam_role.lambda_execution_role.name
#     ec2_instance_role       = aws_iam_role.ec2_instance_role.name
#     # github_actions_role     = aws_iam_role.github_actions_role.name
#   }
# }
