# ====================================================================
# WIPSIE INFRASTRUCTURE VARIABLES
# ====================================================================
# This file defines all input variables for the Wipsie learning application
# infrastructure. Variables are organized by functional area for clarity.

# ====================================================================
# CORE CONFIGURATION
# ====================================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in format like 'us-east-1' or 'us-east-1'."
  }
}

variable "environment" {
  description = "Environment name (learning, staging, production)"
  type        = string
  default     = "learning"

  validation {
    condition     = contains(["learning", "staging", "production"], var.environment)
    error_message = "Environment must be either 'learning', 'staging' or 'production'."
  }
}

variable "project_name" {
  description = "Name of the project - used for resource naming and tagging"
  type        = string
  default     = "wipsie"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

# ====================================================================
# NETWORKING CONFIGURATION
# ====================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC - provides IP address range for the entire network"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (~$45/month). For learning: disable and use public subnets only to save $45/month"
  type        = bool
  default     = false  # Changed to false for maximum cost savings
}

# ====================================================================
# SUBNET CONFIGURATION
# ====================================================================

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  validation {
    condition     = length(var.database_subnet_cidrs) >= 2
    error_message = "At least 2 database subnets are required for RDS Multi-AZ."
  }
}

# ====================================================================
# DATABASE CONFIGURATION
# ====================================================================

variable "rds_instance_class" {
  description = "RDS instance class - determines CPU, memory, and network performance"
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.rds_instance_class))
    error_message = "RDS instance class must be in format like 'db.t3.micro' or 'db.r5.large'."
  }
}

# ====================================================================
# DATABASE CREDENTIALS
# ====================================================================

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "wipsie"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"

  validation {
    condition     = length(var.db_username) >= 1 && length(var.db_username) <= 63
    error_message = "Database username must be between 1 and 63 characters."
  }
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

variable "redis_auth_token" {
  description = "Redis authentication token"
  type        = string
  sensitive   = true
  default     = "ChangeMe123RedisToken!"

  validation {
    condition     = length(var.redis_auth_token) >= 16
    error_message = "Redis auth token must be at least 16 characters long."
  }
}

# ====================================================================
# COMPUTE CONFIGURATION
# ====================================================================

variable "ecs_task_cpu" {
  description = "CPU units for ECS tasks (256 = 0.25 vCPU, 512 = 0.5 vCPU, etc.)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.ecs_task_cpu)
    error_message = "ECS task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "ecs_task_memory" {
  description = "Memory for ECS tasks"
  type        = number
  default     = 512
}

# ====================================================================
# COST OPTIMIZATION VARIABLES (for learning environment)
# ====================================================================

variable "enable_rds" {
  description = "Enable RDS PostgreSQL database (~$13/month). For learning, you can use SQLite or containerized PostgreSQL"
  type        = bool
  default     = true
}

variable "enable_redis" {
  description = "Enable ElastiCache Redis (~$12/month). For learning, you can use in-memory caching or containerized Redis"
  type        = bool
  default     = true
}

variable "enable_alb" {
  description = "Enable Application Load Balancer (~$16/month). For learning, you can use simple EC2 instance or direct ECS access"
  type        = bool
  default     = true
}

variable "enable_cloudfront" {
  description = "Enable CloudFront CDN (~$1-5/month). For learning, you can serve directly from S3"
  type        = bool
  default     = true
}

# ====================================================================
# FARGATE SERVICE CONFIGURATION
# ====================================================================

variable "enable_fargate_service" {
  description = "Enable Fargate service for backend application (learning purposes)"
  type        = bool
  default     = false
}

variable "fargate_cpu" {
  description = "Fargate CPU units (256, 512, 1024, 2048, 4096) - 256 cheapest for learning"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.fargate_cpu)
    error_message = "Fargate CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "fargate_memory" {
  description = "Fargate memory in MB - must be compatible with CPU selection"
  type        = number
  default     = 512

  validation {
    condition     = var.fargate_memory >= 512 && var.fargate_memory <= 30720
    error_message = "Fargate memory must be between 512 MB and 30720 MB."
  }
}

variable "fargate_desired_count" {
  description = "Number of Fargate tasks to run (start with 1 for learning)"
  type        = number
  default     = 1

  validation {
    condition     = var.fargate_desired_count >= 0 && var.fargate_desired_count <= 10
    error_message = "Desired count must be between 0 and 10 for learning environment."
  }
}

variable "fargate_use_spot" {
  description = "Use Fargate Spot for cost savings (up to 70% cheaper) - perfect for learning"
  type        = bool
  default     = true
}

variable "fargate_min_capacity" {
  description = "Minimum number of tasks for auto-scaling (0 = scale to zero when not learning)"
  type        = number
  default     = 0

  validation {
    condition     = var.fargate_min_capacity >= 0 && var.fargate_min_capacity <= 10
    error_message = "Min capacity must be between 0 and 10."
  }
}

variable "fargate_max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
  default     = 3

  validation {
    condition     = var.fargate_max_capacity >= 1 && var.fargate_max_capacity <= 10
    error_message = "Max capacity must be between 1 and 10 for learning environment."
  }
}

variable "enable_fargate_autoscaling" {
  description = "Enable auto-scaling for Fargate service (useful for learning load testing)"
  type        = bool
  default     = false
}

variable "backend_image_tag" {
  description = "Docker image tag for backend application"
  type        = string
  default     = "latest"
}

# ====================================================================
# DATABASE COST OPTIMIZATION
# ====================================================================

variable "enable_database" {
  description = "Enable RDS database (WARNING: Disabling will destroy all data!)"
  type        = bool
  default     = true
}

variable "database_mode" {
  description = "Database deployment mode: ultra-budget, learning, development, production"
  type        = string
  default     = "learning"

  validation {
    condition     = contains(["ultra-budget", "learning", "development", "production"], var.database_mode)
    error_message = "Database mode must be one of: ultra-budget, learning, development, production."
  }
}

variable "enable_database_multi_az" {
  description = "Enable Multi-AZ for high availability (costs 2x more)"
  type        = bool
  default     = false
}

variable "database_backup_retention" {
  description = "Database backup retention in days (0 = no backups, saves cost)"
  type        = number
  default     = 1

  validation {
    condition     = var.database_backup_retention >= 0 && var.database_backup_retention <= 35
    error_message = "Backup retention must be between 0 and 35 days."
  }
}

variable "database_skip_final_snapshot" {
  description = "Skip final snapshot when destroying database (useful for learning)"
  type        = bool
  default     = true
}

variable "database_deletion_protection" {
  description = "Enable deletion protection (disable for learning environments)"
  type        = bool
  default     = false
}

variable "database_performance_insights" {
  description = "Enable Performance Insights (additional cost)"
  type        = bool
  default     = false
}

variable "database_monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 = disabled, saves cost)"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.database_monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

# ====================================================================
# ALTERNATIVE DATABASE OPTIONS FOR LEARNING
# ====================================================================

variable "enable_local_database" {
  description = "Use local SQLite database in containers instead of RDS (no cost)"
  type        = bool
  default     = false
}

variable "enable_database_container" {
  description = "Run PostgreSQL in a container instead of RDS (Fargate cost only)"
  type        = bool
  default     = false
}

# ====================================================================
# AURORA POSTGRESQL CONFIGURATION (for AWS Query Editor)
# ====================================================================

variable "enable_aurora" {
  description = "Enable Aurora PostgreSQL cluster (required for AWS Query Editor)"
  type        = bool
  default     = false
}

variable "aurora_instance_class" {
  description = "Aurora instance class (minimum db.t3.medium)"
  type        = string
  default     = "db.t3.medium"
  
  validation {
    condition = can(regex("^db\\.(t3|r5|r6g)\\.(medium|large|xlarge|2xlarge)$", var.aurora_instance_class))
    error_message = "Aurora instance class must be db.t3.medium or larger for proper performance."
  }
}

variable "aurora_serverless_v2" {
  description = "Use Aurora Serverless v2 (enables auto-scaling and cost optimization)"
  type        = bool
  default     = true
}

variable "aurora_min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity units (0.5 = ~$13/month minimum)"
  type        = number
  default     = 0.5
  
  validation {
    condition = var.aurora_min_capacity >= 0.5 && var.aurora_min_capacity <= 128
    error_message = "Aurora min capacity must be between 0.5 and 128 ACUs."
  }
}

variable "aurora_max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity units"
  type        = number
  default     = 2.0
  
  validation {
    condition = var.aurora_max_capacity >= 0.5 && var.aurora_max_capacity <= 128
    error_message = "Aurora max capacity must be between 0.5 and 128 ACUs."
  }
}
