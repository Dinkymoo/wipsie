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
  description = "Environment name (staging, production)"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either 'staging' or 'production'."
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
  description = "Enable NAT Gateway for private subnets (required for Lambda and private resources)"
  type        = bool
  default     = true
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
