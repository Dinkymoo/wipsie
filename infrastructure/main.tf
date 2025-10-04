# Wipsie Infrastructure - Main Configuration
# This file defines the core infrastructure for the Wipsie learning application

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Random resources for unique naming
resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "random_id" "redis_suffix" {
  byte_length = 4
}
