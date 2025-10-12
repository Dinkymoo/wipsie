# Ultra-Budget Learning Configuration
# This configuration minimizes AWS costs to ~$5-10/month for learning

# Disable expensive services
enable_nat_gateway = false    # Save $45/month - use public subnets only
enable_rds = false           # Save $13/month - use SQLite or Docker PostgreSQL
enable_redis = false         # Save $12/month - use in-memory caching
enable_alb = false           # Save $16/month - access ECS directly
enable_cloudfront = false    # Save $1-5/month - serve from S3 directly

# Core settings remain the same
environment = "staging"
project_name = "wipsie"

# Use fewer subnets for cost optimization (still maintains redundancy)
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]
