# Wipsie Infrastructure - Main Configuration
# This file defines the core infrastructure for the Wipsie learning application
# 
# Architecture Overview - Cost-Optimized Learning Environment:
# ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
# │   CloudFront    │    │   Application   │    │    Database     │
# │  (Optional)     │◄──►│ Load Balancer   │◄──►│      Layer      │
# │  var.enable_cf  │    │  (Optional)     │    │   (Required)    │
# └─────────────────┘    │ var.enable_alb  │    └─────────────────┘
#          │              └─────────────────┘              │
#          │                       │                       │
#     ┌─────────┐              ┌─────────┐          ┌─────────────┐
#     │   S3    │              │   ECS   │          │     RDS     │
#     │ Bucket  │              │ Fargate │          │ PostgreSQL  │
#     │(Static) │              │Cluster  │          │  (Required) │
#     └─────────┘              │(Ready)  │          └─────────────┘
#          │                   └─────────┘                  │
#          │                        │                       │
#          │                        │                ┌─────────────┐
#          │                   ┌─────────┐          │    Redis    │
#          │                   │ Lambda  │          │  (Optional) │
#          │                   │Functions│          │var.enable_r │
#          │                   │(Ready)  │          └─────────────┘
#          │                   └─────────┘
#          │                        │
#          │                   ┌─────────┐
#          └──────────────────►│   SQS   │
#                              │ Queues  │
#                              │(Ready)  │
#                              └─────────┘
#
# Cost Optimization Strategy:
# ┌────────────────────────────────────────────────────────────────────┐
# │ 🎯 ULTRA-BUDGET MODE: $13-18/month (85% cost reduction)           │
# │ • NAT Gateway: DISABLED (var.enable_nat_gateway = false)          │
# │ • Redis Cache: DISABLED (var.enable_redis = false)                │
# │ • Load Balancer: DISABLED (var.enable_alb = false)                │
# │ • CloudFront: DISABLED (var.enable_cloudfront = false)            │
# │ • ECS Fargate: ON-DEMAND (pay per second when learning)           │
# │ • RDS PostgreSQL: t3.micro (always-on but minimal cost)           │
# └────────────────────────────────────────────────────────────────────┘
#
# Network Architecture (Cost-Optimized):
# ┌─────────────────────────────────────────────────────────────────────┐
# │ VPC: 10.0.0.0/16                                                   │
# │ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────┐ │
# │ │ Public Subnets  │ │ Private Subnets │ │   Database Subnets      │ │
# │ │ 10.0.1.0/24     │ │ 10.0.101.0/24   │ │   10.0.201.0/24         │ │
# │ │ 10.0.2.0/24     │ │ 10.0.102.0/24   │ │   10.0.202.0/24         │ │
# │ │                 │ │                 │ │                         │ │
# │ │ • Internet GW   │ │ • NAT Gateway   │ │   • RDS PostgreSQL      │ │
# │ │ • ECS Fargate   │ │   (Optional)    │ │   • Redis (Optional)    │ │
# │ │   (when no NAT) │ │ • ECS Fargate   │ │   • Isolated Network    │ │
# │ │                 │ │   (when NAT on) │ │                         │ │
# │ └─────────────────┘ └─────────────────┘ └─────────────────────────┘ │
# └─────────────────────────────────────────────────────────────────────┘
#
# Current Status: Infrastructure foundation with conditional cost optimization
# Next Steps: Deploy Fargate services and configure auto-scaling for learning sessions

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
# NETWORKING INFRASTRUCTURE
# ====================================================================

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-${var.environment}"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}-${var.environment}"
    Type = "public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}-${var.environment}"
    Type = "private"
  }
}

# Database Subnets
resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-database-subnet-${count.index + 1}-${var.environment}"
    Type = "database"
  }
}

# Elastic IPs for NAT Gateway (single for cost optimization)
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-eip-nat-${var.environment}"
  }
}

# NAT Gateway (single for cost optimization)
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat-${var.environment}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}"
  }
}

# Route table for private subnets (single table routing to single NAT Gateway)
resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${var.environment}"
  }
}

# Route table for database subnets
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-database-rt-${var.environment}"
  }
}

# Route table associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = var.enable_nat_gateway ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# ====================================================================
# SECURITY GROUPS
# ====================================================================

# Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-${var.environment}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg-${var.environment}"
  }
}

# ECS Security Group
resource "aws_security_group" "ecs" {
  name_prefix = "${var.project_name}-ecs-${var.environment}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg-${var.environment}"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-${var.environment}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id, aws_security_group.lambda.id]
  }

  tags = {
    Name = "${var.project_name}-rds-sg-${var.environment}"
  }
}

# Redis Security Group
resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-redis-${var.environment}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from ECS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id, aws_security_group.lambda.id]
  }

  tags = {
    Name = "${var.project_name}-redis-sg-${var.environment}"
  }
}

# Lambda Security Group
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-lambda-${var.environment}"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-lambda-sg-${var.environment}"
  }
}

# ====================================================================
# LOAD BALANCER
# ====================================================================

# Application Load Balancer
resource "aws_lb" "main" {
  count              = var.enable_alb ? 1 : 0
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb-${var.environment}"
  }
}

# Target Group for ECS Service
resource "aws_lb_target_group" "ecs" {
  count    = var.enable_alb ? 1 : 0
  name     = "${var.project_name}-ecs-tg-${var.environment}"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name = "${var.project_name}-ecs-tg-${var.environment}"
  }
}

# ALB Listener
resource "aws_lb_listener" "main" {
  count             = var.enable_alb ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs[0].arn
  }

  tags = {
    Name = "${var.project_name}-alb-listener-${var.environment}"
  }
}

# ====================================================================
# ECS CLUSTER
# ====================================================================

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster-${var.environment}"
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-ecs-logs-${var.environment}"
  }
}

# ECS Task Definition
# Commented out due to IAM role dependencies
# resource "aws_ecs_task_definition" "backend" {
#   family                   = "${var.project_name}-backend-${var.environment}"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = 512
#   memory                   = 1024
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn           = aws_iam_role.ecs_task_role.arn

#   container_definitions = jsonencode([
#     {
#       name  = "backend"
#       image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-backend:latest"
      
#       portMappings = [
#         {
#           containerPort = 8000
#           protocol      = "tcp"
#         }
#       ]

#       environment = [
#         {
#           name  = "ENVIRONMENT"
#           value = var.environment
#         },
#         {
#           name  = "DATABASE_URL"
#           value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
#         },
#         {
#           name  = "REDIS_URL"
#           value = "redis://${aws_elasticache_replication_group.main.primary_endpoint_address}:6379"
#         }
#       ]

#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
#           "awslogs-region"        = var.aws_region
#           "awslogs-stream-prefix" = "ecs"
#         }
#       }

#       essential = true
#     }
#   ])

#   tags = {
#     Name = "${var.project_name}-backend-task-${var.environment}"
#   }
# }

# ECS Service
# Commented out due to IAM role dependencies
# resource "aws_ecs_service" "backend" {
#   name            = "${var.project_name}-backend-${var.environment}"
#   cluster         = aws_ecs_cluster.main.id
#   task_definition = aws_ecs_task_definition.backend.arn
#   desired_count   = var.environment == "production" ? 2 : 1

#   capacity_provider_strategy {
#     capacity_provider = "FARGATE"
#     weight            = 100
#   }

#   network_configuration {
#     subnets          = aws_subnet.private[*].id
#     security_groups  = [aws_security_group.ecs.id]
#     assign_public_ip = false
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.ecs.arn
#     container_name   = "backend"
#     container_port   = 8000
#   }

#   depends_on = [
#     aws_lb_listener.main,
#     aws_iam_role_policy_attachment.ecs_task_execution_role_policy
#   ]

#   tags = {
#     Name = "${var.project_name}-backend-service-${var.environment}"
#   }
# }
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

# IAM Role for ECS Task Execution
# Commented out due to IAM permissions - aws-admin user cannot create roles
# resource "aws_iam_role" "ecs_task_execution_role" {
#   name = "${var.project_name}-${var.environment}-ecs-task-execution"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       }
#     ]
#   })

#   tags = merge(var.common_tags, {
#     Name      = "${var.project_name}-${var.environment}-ecs-task-execution"
#     Component = "ECS"
#     Purpose   = "Task Execution"
#     CreatedBy = data.aws_caller_identity.current.user_id
#   })
# }

# Attach AWS managed policy for ECS task execution
# Commented out due to IAM permissions
# resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# Additional policy for accessing Secrets Manager and Parameter Store
# Commented out due to IAM permissions
# resource "aws_iam_role_policy" "ecs_task_execution_additional" {
#   name = "${local.name_prefix}-ecs-task-execution-additional"
#   role = aws_iam_role.ecs_task_execution_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "secretsmanager:GetSecretValue",
#           "ssm:GetParameters",
#           "ssm:GetParameter",
#           "ssm:GetParametersByPath",
#           "kms:Decrypt"
#         ]
#         Resource = [
#           "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*",
#           "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*",
#           "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
#         ]
#       }
#     ]
#   })
# }

# ====================================================================
# ECS TASK ROLE (for application runtime)
# ====================================================================
# Role for the actual application running in ECS tasks
# Commented out due to IAM permissions

# resource "aws_iam_role" "ecs_task_role" {
#   name = "${local.name_prefix}-ecs-task"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       }
#     ]
#   })

#   tags = merge(local.common_tags, {
#     Name      = "${local.name_prefix}-ecs-task"
#     Component = "ECS"
#     Purpose   = "Application Runtime"
#   })
# }

# Policy for ECS tasks to access AWS services needed by the application
# Commented out due to IAM permissions
# resource "aws_iam_role_policy" "ecs_task_policy" {
#   name = "${local.name_prefix}-ecs-task-policy"
#   role = aws_iam_role.ecs_task_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           # SQS permissions for message processing
#           "sqs:ReceiveMessage",
#           "sqs:SendMessage",
#           "sqs:DeleteMessage",
#           "sqs:GetQueueAttributes",
#           "sqs:GetQueueUrl"
#         ]
#         Resource = [
#           "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.project_name}-*"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           # S3 permissions for file storage
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           "arn:aws:s3:::${var.project_name}-${var.environment}-*",
#           "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           # Lambda invocation for background processing
#           "lambda:InvokeFunction"
#         ]
#         Resource = [
#           "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           # Secrets Manager access for database credentials
#           "secretsmanager:GetSecretValue"
#         ]
#         Resource = [
#           "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
#         ]
#       }
#     ]
#   })
# }

# ====================================================================
# LAMBDA EXECUTION ROLES
# ====================================================================
# Roles for Lambda functions with specific permissions
# Commented out due to IAM permissions

# resource "aws_iam_role" "lambda_execution_role" {
#   name = "${local.name_prefix}-lambda-execution"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })

#   tags = merge(local.common_tags, {
#     Name      = "${local.name_prefix}-lambda-execution"
#     Component = "Lambda"
#     Purpose   = "Function Execution"
#   })
# }

# Attach AWS managed policy for Lambda basic execution
# Commented out due to IAM permissions
# resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
#   role       = aws_iam_role.lambda_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# Custom policy for Lambda functions
# Commented out due to IAM permissions
# resource "aws_iam_role_policy" "lambda_custom_policy" {
#   name = "${local.name_prefix}-lambda-custom"
#   role = aws_iam_role.lambda_execution_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           # VPC permissions for Lambda in VPC
#           "ec2:CreateNetworkInterface",
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:DeleteNetworkInterface"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           # SQS permissions for Lambda triggers and processing
#           "sqs:ReceiveMessage",
#           "sqs:SendMessage",
#           "sqs:DeleteMessage",
#           "sqs:GetQueueAttributes",
#           "sqs:GetQueueUrl"
#         ]
#         Resource = [
#           "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.project_name}-*"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           # RDS Data API permissions (if using serverless RDS)
#           "rds-data:ExecuteStatement",
#           "rds-data:BatchExecuteStatement",
#           "rds-data:BeginTransaction",
#           "rds-data:CommitTransaction",
#           "rds-data:RollbackTransaction"
#         ]
#         Resource = [
#           "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster:${var.project_name}-*"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           # Secrets Manager for database credentials
#           "secretsmanager:GetSecretValue"
#         ]
#         Resource = [
#           "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           # S3 permissions for data processing
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject"
#         ]
#         Resource = [
#           "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
#         ]
#       }
#     ]
#   })
# }

# ====================================================================
# EC2 INSTANCE PROFILE (if using EC2 instances)
# ====================================================================
# Role for EC2 instances to access AWS services
# Commented out due to IAM permissions

# resource "aws_iam_role" "ec2_instance_role" {
#   name = "${local.name_prefix}-ec2-instance"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })

#   tags = merge(local.common_tags, {
#     Name      = "${local.name_prefix}-ec2-instance"
#     Component = "EC2"
#     Purpose   = "Instance Profile"
#   })
# }

# Instance profile for EC2
# Commented out due to IAM permissions
# resource "aws_iam_instance_profile" "ec2_instance_profile" {
#   name = "${local.name_prefix}-ec2-instance"
#   role = aws_iam_role.ec2_instance_role.name

#   tags = local.common_tags
# }

# Policy for EC2 instances
# Commented out due to IAM permissions
# resource "aws_iam_role_policy" "ec2_instance_policy" {
#   name = "${local.name_prefix}-ec2-instance-policy"
#   role = aws_iam_role.ec2_instance_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           # CloudWatch for monitoring and logging
#           "cloudwatch:PutMetricData",
#           "cloudwatch:GetMetricStatistics",
#           "cloudwatch:ListMetrics",
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#           "logs:DescribeLogStreams"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           # Systems Manager for parameter store
#           "ssm:GetParameter",
#           "ssm:GetParameters",
#           "ssm:GetParametersByPath"
#         ]
#         Resource = [
#           "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*"
#         ]
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           # Secrets Manager access
#           "secretsmanager:GetSecretValue"
#         ]
#         Resource = [
#           "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
#         ]
#       }
#     ]
#   })
# }

# ====================================================================
# GITHUB ACTIONS OIDC ROLE (for CI/CD)
# ====================================================================
# Role for GitHub Actions to deploy infrastructure securely

# OIDC Provider for GitHub Actions - COMMENTED OUT DUE TO IAM PERMISSIONS
# resource "aws_iam_openid_connect_provider" "github_actions" {
#   url = "https://token.actions.githubusercontent.com"
# 
#   client_id_list = [
#     "sts.amazonaws.com",
#   ]
# 
#   thumbprint_list = [
#     "6938fd4d98bab03faadb97b34396831e3780aea1",
#     "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
#   ]
# 
#   tags = merge(local.common_tags, {
#     Name      = "${local.name_prefix}-github-oidc"
#     Component = "CI/CD"
#     Purpose   = "GitHub Actions OIDC"
#   })
# }

# Role for GitHub Actions - COMMENTED OUT DUE TO IAM PERMISSIONS  
# resource "aws_iam_role" "github_actions_role" {
#   name = "${local.name_prefix}-github-actions"
# 
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.github_actions.arn
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
#           }
#           StringLike = {
#             "token.actions.githubusercontent.com:sub" = "repo:Dinkymoo/learn-work:*"
#           }
#         }
#       }
#     ]
#   })
# 
#   tags = merge(local.common_tags, {
#     Name      = "${local.name_prefix}-github-actions"
#     Component = "CI/CD"
#     Purpose   = "GitHub Actions Deployment"
#   })
# }
# 
# # Policy for GitHub Actions deployment - COMMENTED OUT
# resource "aws_iam_role_policy" "github_actions_policy" {
#   name = "${local.name_prefix}-github-actions-policy"
#   role = aws_iam_role.github_actions_role.id

# 
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           # Full access for infrastructure deployment
#           "iam:*",
#           "ec2:*",
#           "ecs:*",
#           "rds:*",
#           "lambda:*",
#           "s3:*",
#           "sqs:*",
#           "secretsmanager:*",
#           "ssm:*",
#           "cloudformation:*",
#           "cloudwatch:*",
#           "logs:*"
#         ]
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "aws:RequestedRegion" = var.aws_region
#           }
#         }
#       }
#     ]
#   })
# }

# ====================================================================
# RDS MONITORING ROLE - COMMENTED OUT DUE TO IAM PERMISSIONS
# ====================================================================
# Uncomment when aws-admin user gets PowerUserAccess policy

# # RDS Enhanced Monitoring Role
# resource "aws_iam_role" "rds_monitoring" {
#   name = "${var.project_name}-rds-monitoring-${var.environment}"
# 
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "monitoring.rds.amazonaws.com"
#         }
#       }
#     ]
#   })
# 
#   tags = {
#     Name = "${var.project_name}-rds-monitoring-${var.environment}"
#   }
# }
# 
# resource "aws_iam_role_policy_attachment" "rds_monitoring" {
#   role       = aws_iam_role.rds_monitoring.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
# }

# ====================================================================
# DATABASE INFRASTRUCTURE
# ====================================================================

# Database Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group-${var.environment}"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = "${var.project_name}-db-params-${var.environment}"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name = "${var.project_name}-db-params-${var.environment}"
  }
}

# RDS Instance with Cost Optimization
resource "aws_db_instance" "main" {
  count = var.enable_database ? 1 : 0
  
  identifier = "${var.project_name}-db-${var.environment}-${random_id.db_suffix.hex}"

  # Engine Configuration
  engine         = "postgres"
  engine_version = "15.12"
  
  # Instance class based on database mode
  instance_class = local.database_instance_class

  # Database Configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Storage Configuration - optimized based on mode
  allocated_storage     = local.database_storage_size
  max_allocated_storage = local.database_max_storage
  storage_type          = "gp3"
  storage_encrypted     = var.database_mode != "ultra-budget"

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # High Availability - cost optimization
  multi_az = var.enable_database_multi_az

  # Backup Configuration - major cost saver
  backup_retention_period = var.database_backup_retention
  backup_window          = var.database_backup_retention > 0 ? "03:00-04:00" : null
  maintenance_window     = "sun:04:00-sun:05:00"

  # Performance and Monitoring - cost controls
  performance_insights_enabled = var.database_performance_insights
  monitoring_interval         = var.database_monitoring_interval

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.main.name

  # Deletion Protection - learning environment settings
  deletion_protection = var.database_deletion_protection
  skip_final_snapshot = var.database_skip_final_snapshot

  tags = {
    Name = "${var.project_name}-db-${var.environment}"
    Mode = var.database_mode
    CostOptimized = var.database_mode == "ultra-budget" ? "true" : "false"
  }
}

# Local values for database cost optimization
locals {
  database_configs = {
    "ultra-budget" = {
      instance_class = "db.t3.micro"
      storage_size   = 20
      max_storage    = 50
    }
    "learning" = {
      instance_class = "db.t3.micro"
      storage_size   = 20
      max_storage    = 100
    }
    "development" = {
      instance_class = "db.t3.small"
      storage_size   = 50
      max_storage    = 200
    }
    "production" = {
      instance_class = "db.t3.medium"
      storage_size   = 100
      max_storage    = 1000
    }
  }
  
  database_instance_class = local.database_configs[var.database_mode].instance_class
  database_storage_size   = local.database_configs[var.database_mode].storage_size
  database_max_storage    = local.database_configs[var.database_mode].max_storage
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  count      = var.enable_redis ? 1 : 0
  name       = "${var.project_name}-cache-subnet-group-${var.environment}"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${var.project_name}-cache-subnet-group-${var.environment}"
  }
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  count  = var.enable_redis ? 1 : 0
  family = "redis6.x"
  name   = "${var.project_name}-cache-params-${var.environment}"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = {
    Name = "${var.project_name}-cache-params-${var.environment}"
  }
}

# ElastiCache Replication Group (Redis)
resource "aws_elasticache_replication_group" "main" {
  count                      = var.enable_redis ? 1 : 0
  replication_group_id       = "${var.project_name}-cache-${var.environment}-${random_id.redis_suffix.hex}"
  description                = "Redis cache for ${var.project_name} ${var.environment}"

  # Node Configuration
  engine_version     = "6.2"
  node_type          = var.environment == "production" ? "cache.t3.medium" : "cache.t3.micro"
  port               = 6379
  parameter_group_name = aws_elasticache_parameter_group.main[0].name

  # Replication Configuration
  num_cache_clusters = var.environment == "production" ? 2 : 1

  # Network Configuration
  subnet_group_name  = aws_elasticache_subnet_group.main[0].name
  security_group_ids = [aws_security_group.redis.id]

  # Security - Simplified for staging
  at_rest_encryption_enabled = false
  transit_encryption_enabled = false
  # auth_token                 = var.redis_auth_token  # Disabled for simplicity

  # Backup Configuration
  snapshot_retention_limit = var.environment == "production" ? 5 : 1
  snapshot_window         = "03:00-05:00"

  # Maintenance
  maintenance_window = "sun:05:00-sun:07:00"

  # Automatic Failover
  automatic_failover_enabled = var.environment == "production"
  multi_az_enabled          = var.environment == "production"

  tags = {
    Name = "${var.project_name}-cache-${var.environment}"
  }
}

# ====================================================================
# LAMBDA FUNCTIONS
# ====================================================================

# S3 Bucket for Lambda Deployment Packages
resource "aws_s3_bucket" "lambda_deployments" {
  bucket = "${var.project_name}-lambda-deployments-${var.environment}-${random_id.db_suffix.hex}"

  tags = {
    Name = "${var.project_name}-lambda-deployments-${var.environment}"
  }
}

resource "aws_s3_bucket_versioning" "lambda_deployments" {
  bucket = aws_s3_bucket.lambda_deployments.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_deployments" {
  bucket = aws_s3_bucket.lambda_deployments.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Log Groups for Lambda Functions
resource "aws_cloudwatch_log_group" "data_poller" {
  name              = "/aws/lambda/${var.project_name}-data-poller-${var.environment}"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-data-poller-logs-${var.environment}"
  }
}

resource "aws_cloudwatch_log_group" "task_processor" {
  name              = "/aws/lambda/${var.project_name}-task-processor-${var.environment}"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-task-processor-logs-${var.environment}"
  }
}

# Lambda Function: Data Poller
# Commented out due to IAM role dependencies
# resource "aws_lambda_function" "data_poller" {
#   function_name = "${var.project_name}-data-poller-${var.environment}"
#   role         = aws_iam_role.lambda_execution_role.arn
#   handler      = "data_poller.lambda_handler"
#   runtime      = "python3.11"
#   timeout      = 300

#   # Deployment package (will be updated via CI/CD)
#   filename         = "${path.module}/../aws-lambda/packages/data_poller.zip"
#   source_code_hash = filebase64sha256("${path.module}/../aws-lambda/packages/data_poller.zip")

#   vpc_config {
#     subnet_ids         = aws_subnet.private[*].id
#     security_group_ids = [aws_security_group.lambda.id]
#   }

#   environment {
#     variables = {
#       ENVIRONMENT     = var.environment
#       DATABASE_URL    = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
#       BACKEND_API_URL = "http://${aws_lb.main.dns_name}"
#       SQS_QUEUE_URL   = aws_sqs_queue.task_queue.url
#     }
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.lambda_basic_execution,
#     aws_cloudwatch_log_group.data_poller
#   ]

#   tags = {
#     Name = "${var.project_name}-data-poller-${var.environment}"
#   }
# }

# Lambda Function: Task Processor
# Commented out due to IAM role dependencies
# resource "aws_lambda_function" "task_processor" {
#   function_name = "${var.project_name}-task-processor-${var.environment}"
#   role         = aws_iam_role.lambda_execution_role.arn
#   handler      = "task_processor.lambda_handler"
#   runtime      = "python3.11"
#   timeout      = 900

#   # Deployment package (will be updated via CI/CD)
#   filename         = "${path.module}/../aws-lambda/packages/task_processor.zip"
#   source_code_hash = filebase64sha256("${path.module}/../aws-lambda/packages/task_processor.zip")

#   vpc_config {
#     subnet_ids         = aws_subnet.private[*].id
#     security_group_ids = [aws_security_group.lambda.id]
#   }

#   environment {
#     variables = {
#       ENVIRONMENT     = var.environment
#       DATABASE_URL    = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
#       BACKEND_API_URL = "http://${aws_lb.main.dns_name}"
#       REDIS_URL       = "redis://${aws_elasticache_replication_group.main.primary_endpoint_address}:6379"
#     }
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.lambda_basic_execution,
#     aws_cloudwatch_log_group.task_processor
#   ]

#   tags = {
#     Name = "${var.project_name}-task-processor-${var.environment}"
#   }
# }

# ====================================================================
# SQS QUEUES
# ====================================================================

# Main Task Queue
resource "aws_sqs_queue" "task_queue" {
  name = "${var.project_name}-task-queue-${var.environment}"

  # Message Configuration
  visibility_timeout_seconds = 300
  message_retention_seconds  = 1209600  # 14 days
  max_message_size          = 262144   # 256 KB

  # Dead Letter Queue Configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.task_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${var.project_name}-task-queue-${var.environment}"
  }
}

# Dead Letter Queue
resource "aws_sqs_queue" "task_dlq" {
  name = "${var.project_name}-task-dlq-${var.environment}"

  # Extended retention for failed messages
  message_retention_seconds = 1209600  # 14 days

  tags = {
    Name = "${var.project_name}-task-dlq-${var.environment}"
  }
}

# SQS Event Source Mapping for Task Processor
# Commented out due to Lambda function dependencies
# resource "aws_lambda_event_source_mapping" "task_processor" {
#   event_source_arn = aws_sqs_queue.task_queue.arn
#   function_name    = aws_lambda_function.task_processor.arn
#   batch_size       = 10
# }

# EventBridge Rule for Data Poller (runs every 15 minutes)
resource "aws_cloudwatch_event_rule" "data_poller" {
  name                = "${var.project_name}-data-poller-schedule-${var.environment}"
  description         = "Trigger data poller every 15 minutes"
  schedule_expression = "rate(15 minutes)"

  tags = {
    Name = "${var.project_name}-data-poller-schedule-${var.environment}"
  }
}

# EventBridge Target for Data Poller
# Commented out due to Lambda function dependencies
# resource "aws_cloudwatch_event_target" "data_poller" {
#   rule      = aws_cloudwatch_event_rule.data_poller.name
#   target_id = "DataPollerTarget"
#   arn       = aws_lambda_function.data_poller.arn
# }

# Lambda Permission for EventBridge
# Commented out due to Lambda function dependencies
# resource "aws_lambda_permission" "allow_eventbridge" {
#   statement_id  = "AllowExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.data_poller.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.data_poller.arn
# }

# ====================================================================
# S3 AND CLOUDFRONT
# ====================================================================

# S3 Bucket for Frontend Static Assets
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}-${random_id.db_suffix.hex}"

  tags = {
    Name = "${var.project_name}-frontend-${var.environment}"
  }
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Policy for CloudFront
resource "aws_s3_bucket_policy" "frontend" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.main[0].iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "main" {
  count   = var.enable_cloudfront ? 1 : 0
  comment = "OAI for ${var.project_name} ${var.environment}"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  count = var.enable_cloudfront ? 1 : 0
  
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main[0].cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # API cache behavior removed when ALB disabled
  # All requests now go to S3 static content only
  
  # ALB origin removed for cost optimization
  # When ALB is disabled, CloudFront only serves static content from S3
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project_name}-cloudfront-${var.environment}"
  }
}
