# Environment-specific variables for production

aws_region   = "us-east-1"
environment  = "production"
project_name = "wipsie"

# Networking
vpc_cidr           = "10.0.0.0/16"
enable_nat_gateway = true # Full redundancy for production

# Database
rds_instance_class = "db.t3.small"

# ECS
ecs_task_cpu    = 512
ecs_task_memory = 1024
