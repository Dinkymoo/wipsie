# Environment-specific variables for staging

aws_region   = "us-east-1"
environment  = "staging"
project_name = "wipsie"

# Networking
vpc_cidr           = "10.0.0.0/16"
enable_nat_gateway = false # Cost optimization for staging

# Database
rds_instance_class = "db.t3.micro"

# ECS
ecs_task_cpu    = 256
ecs_task_memory = 512
