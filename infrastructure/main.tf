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

# ====================================================================
# IAM ROLES AND POLICIES FOR SECURE CREDENTIAL MANAGEMENT
# ====================================================================
# Following AWS best practices: Use IAM roles instead of access keys
# This provides temporary, rotating credentials automatically

# ====================================================================
# ECS TASK EXECUTION ROLE
# ====================================================================
# Role for ECS Fargate tasks to pull container images and write logs

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.name_prefix}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-ecs-task-execution"
    Component = "ECS"
    Purpose   = "Task Execution"
  })
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for accessing Secrets Manager and Parameter Store
resource "aws_iam_role_policy" "ecs_task_execution_additional" {
  name = "${local.name_prefix}-ecs-task-execution-additional"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParametersByPath",
          "kms:Decrypt"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*",
          "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
        ]
      }
    ]
  })
}

# ====================================================================
# ECS TASK ROLE (for application runtime)
# ====================================================================
# Role for the actual application running in ECS tasks

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.name_prefix}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-ecs-task"
    Component = "ECS"
    Purpose   = "Application Runtime"
  })
}

# Policy for ECS tasks to access AWS services needed by the application
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${local.name_prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # SQS permissions for message processing
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = [
          "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.project_name}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          # S3 permissions for file storage
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          # Lambda invocation for background processing
          "lambda:InvokeFunction"
        ]
        Resource = [
          "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          # Secrets Manager access for database credentials
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
        ]
      }
    ]
  })
}

# ====================================================================
# LAMBDA EXECUTION ROLES
# ====================================================================
# Roles for Lambda functions with specific permissions

resource "aws_iam_role" "lambda_execution_role" {
  name = "${local.name_prefix}-lambda-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-lambda-execution"
    Component = "Lambda"
    Purpose   = "Function Execution"
  })
}

# Attach AWS managed policy for Lambda basic execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for Lambda functions
resource "aws_iam_role_policy" "lambda_custom_policy" {
  name = "${local.name_prefix}-lambda-custom"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # VPC permissions for Lambda in VPC
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          # SQS permissions for Lambda triggers and processing
          "sqs:ReceiveMessage",
          "sqs:SendMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = [
          "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.project_name}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          # RDS Data API permissions (if using serverless RDS)
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction"
        ]
        Resource = [
          "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster:${var.project_name}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          # Secrets Manager for database credentials
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          # S3 permissions for data processing
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
        ]
      }
    ]
  })
}

# ====================================================================
# EC2 INSTANCE PROFILE (if using EC2 instances)
# ====================================================================
# Role for EC2 instances to access AWS services

resource "aws_iam_role" "ec2_instance_role" {
  name = "${local.name_prefix}-ec2-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-ec2-instance"
    Component = "EC2"
    Purpose   = "Instance Profile"
  })
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.name_prefix}-ec2-instance"
  role = aws_iam_role.ec2_instance_role.name

  tags = local.common_tags
}

# Policy for EC2 instances
resource "aws_iam_role_policy" "ec2_instance_policy" {
  name = "${local.name_prefix}-ec2-instance-policy"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # CloudWatch for monitoring and logging
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          # Systems Manager for parameter store
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          # Secrets Manager access
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
        ]
      }
    ]
  })
}

# ====================================================================
# GITHUB ACTIONS OIDC ROLE (for CI/CD)
# ====================================================================
# Role for GitHub Actions to deploy infrastructure securely

# OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-github-oidc"
    Component = "CI/CD"
    Purpose   = "GitHub Actions OIDC"
  })
}

# Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "${local.name_prefix}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Dinkymoo/learn-work:*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-github-actions"
    Component = "CI/CD"
    Purpose   = "GitHub Actions Deployment"
  })
}

# Policy for GitHub Actions deployment
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "${local.name_prefix}-github-actions-policy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Full access for infrastructure deployment
          "iam:*",
          "ec2:*",
          "ecs:*",
          "rds:*",
          "lambda:*",
          "s3:*",
          "sqs:*",
          "secretsmanager:*",
          "ssm:*",
          "cloudformation:*",
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })
}
