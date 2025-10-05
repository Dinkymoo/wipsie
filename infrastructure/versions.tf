# ====================================================================
# TERRAFORM VERSION CONSTRAINTS AND PROVIDER CONFIGURATION
# ====================================================================
# This file specifies the minimum Terraform version and provider versions
# to ensure consistent behavior across different environments and team members.

terraform {
  required_version = ">= 1.0"

  # Provider version constraints
  # We use ~> (pessimistic constraint) to allow patch-level updates
  # but prevent breaking changes from minor version upgrades
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # AWS Provider 5.x includes:
      # - Enhanced security features
      # - Improved error handling  
      # - Support for latest AWS services
      # - Breaking changes from 4.x require careful migration
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
      # Random provider for generating unique suffixes
      # Used for database names, S3 buckets, etc.
      # Version 3.1+ includes improved entropy and stability
    }
  }

  # Backend configuration for remote state storage
  # Uncomment and configure when setting up remote state
  # 
  # backend "s3" {
  #   bucket         = "wipsie-terraform-state"
  #   key            = "environments/${var.environment}/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-locks"
  #   
  #   # Optional: Enable versioning for state history
  #   versioning     = true
  # }

  # Experimental features (if needed)
  # experiments = []
}

# ====================================================================
# PROVIDER FEATURE FLAGS AND CONFIGURATION
# ====================================================================

# These provider-specific configurations can be added as needed:

# AWS Provider additional configuration
# provider "aws" {
#   # Default tags applied to all resources
#   default_tags {
#     tags = {
#       Project     = var.project_name
#       Environment = var.environment
#       ManagedBy   = "Terraform"
#       Repository  = "wipsie"
#     }
#   }
#   
#   # Assume role configuration for cross-account access
#   # assume_role {
#   #   role_arn = "arn:aws:iam::ACCOUNT_ID:role/TerraformRole"
#   # }
#   
#   # Ignore specific resource tags if managed externally
#   # ignore_tags {
#   #   keys = ["CreatedBy", "LastModified"]
#   # }
# }
