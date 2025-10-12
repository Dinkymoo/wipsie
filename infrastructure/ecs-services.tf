# Fargate Services for Learning Environment
# This file creates ECS Fargate services for the backend application

# ====================================================================
# IAM ROLES FOR ECS TASKS (Required for Fargate)
# ====================================================================

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-${var.environment}"

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

  tags = {
    Name = "${var.project_name}-ecs-task-execution-${var.environment}"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (for application runtime)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-${var.environment}"

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

  tags = {
    Name = "${var.project_name}-ecs-task-${var.environment}"
  }
}

# Policy for ECS tasks to access AWS services
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.project_name}-ecs-task-policy-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # SQS permissions
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
          # S3 permissions
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      }
    ]
  })
}

# ====================================================================
# ECR REPOSITORY FOR BACKEND IMAGES
# ====================================================================

resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-backend-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-backend-ecr-${var.environment}"
  }
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ====================================================================
# FARGATE TASK DEFINITION
# ====================================================================

resource "aws_ecs_task_definition" "backend" {
  count = var.enable_fargate_service ? 1 : 0
  
  family                   = "${var.project_name}-backend-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = var.fargate_cpu
  memory                  = var.fargate_memory
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn          = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${aws_ecr_repository.backend.repository_url}:${var.backend_image_tag}"
      
      essential = true
      
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "DATABASE_URL"
          value = "postgresql://${var.db_username}:${var.db_password}@${local.aurora_endpoint}/${var.db_name}"
        },
        {
          name  = "CORS_ORIGINS"
          value = var.enable_cloudfront ? "https://${aws_cloudfront_distribution.main[0].domain_name}" : "*"
        },
        {
          name  = "SQS_QUEUE_URL"
          value = aws_sqs_queue.task_queue.url
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
      
      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-backend-task-${var.environment}"
  }
}

# ====================================================================
# FARGATE SERVICE
# ====================================================================

resource "aws_ecs_service" "backend" {
  count = var.enable_fargate_service ? 1 : 0
  
  name            = "${var.project_name}-backend-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend[0].arn
  
  desired_count = var.fargate_desired_count
  
  # Use Fargate Spot for cost savings during learning
  capacity_provider_strategy {
    capacity_provider = var.fargate_use_spot ? "FARGATE_SPOT" : "FARGATE"
    weight           = 100
    base            = var.fargate_desired_count
  }
  
  network_configuration {
    # Use public subnets when NAT Gateway is disabled for cost optimization
    subnets          = var.enable_nat_gateway ? aws_subnet.private[*].id : aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = var.enable_nat_gateway ? false : true
  }
  
  # Connect to ALB if enabled
  dynamic "load_balancer" {
    for_each = var.enable_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.ecs[0].arn
      container_name   = "backend"
      container_port   = 8000
    }
  }
  
  # Enable service discovery for easy communication
  dynamic "service_registries" {
    for_each = var.enable_fargate_service ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.backend[0].arn
    }
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  tags = {
    Name = "${var.project_name}-backend-service-${var.environment}"
  }
}

# ====================================================================
# SERVICE DISCOVERY
# ====================================================================

resource "aws_service_discovery_private_dns_namespace" "main" {
  count = var.enable_fargate_service ? 1 : 0
  
  name        = "${var.project_name}.local"
  description = "Private DNS namespace for Wipsie services"
  vpc         = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-dns-namespace-${var.environment}"
  }
}

resource "aws_service_discovery_service" "backend" {
  count = var.enable_fargate_service ? 1 : 0
  
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name = "${var.project_name}-backend-discovery-${var.environment}"
  }
}

# ====================================================================
# AUTO SCALING (Optional)
# ====================================================================

resource "aws_appautoscaling_target" "ecs_target" {
  count = var.enable_fargate_service && var.enable_fargate_autoscaling ? 1 : 0
  
  max_capacity       = var.fargate_max_capacity
  min_capacity       = var.fargate_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  count = var.enable_fargate_service && var.enable_fargate_autoscaling ? 1 : 0
  
  name               = "${var.project_name}-fargate-cpu-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  count = var.enable_fargate_service && var.enable_fargate_autoscaling ? 1 : 0
  
  name               = "${var.project_name}-fargate-memory-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}

# ====================================================================
# ALTERNATIVE: CONTAINERIZED DATABASE FOR MAXIMUM COST SAVINGS
# ====================================================================

# ECS Task Definition for PostgreSQL Container
resource "aws_ecs_task_definition" "database_container" {
  count = var.enable_database_container ? 1 : 0
  
  family                   = "${var.project_name}-database-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn          = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "postgres"
      image = "postgres:15-alpine"
      
      essential = true
      
      portMappings = [
        {
          containerPort = 5432
          hostPort      = 5432
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "POSTGRES_DB"
          value = var.db_name
        },
        {
          name  = "POSTGRES_USER"
          value = var.db_username
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = var.db_password
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.database_container[0].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "database"
        }
      }
      
      healthCheck = {
        command = ["CMD-SHELL", "pg_isready -U ${var.db_username} -d ${var.db_name}"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 60
      }
      
      # Mount EFS for persistent storage (optional)
      mountPoints = var.enable_database_persistence ? [
        {
          sourceVolume  = "postgres-data"
          containerPath = "/var/lib/postgresql/data"
          readOnly      = false
        }
      ] : []
    }
  ])

  # EFS volume for persistence (optional)
  dynamic "volume" {
    for_each = var.enable_database_persistence ? [1] : []
    content {
      name = "postgres-data"
      efs_volume_configuration {
        file_system_id = aws_efs_file_system.database[0].id
        root_directory = "/"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-database-task-${var.environment}"
    Type = "containerized-database"
  }
}

# ECS Service for PostgreSQL Container
resource "aws_ecs_service" "database_container" {
  count = var.enable_database_container ? 1 : 0
  
  name            = "${var.project_name}-database-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.database_container[0].arn
  
  desired_count = 1
  
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"  # Maximum cost savings
    weight           = 100
    base            = 1
  }
  
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.database_container[0].id]
    assign_public_ip = false
  }
  
  # Service discovery for easy connection
  service_registries {
    registry_arn = aws_service_discovery_service.database_container[0].arn
  }

  tags = {
    Name = "${var.project_name}-database-service-${var.environment}"
    Type = "containerized-database"
    CostOptimized = "true"
  }
}

# CloudWatch Log Group for Database Container
resource "aws_cloudwatch_log_group" "database_container" {
  count = var.enable_database_container ? 1 : 0
  
  name              = "/ecs/${var.project_name}-database-${var.environment}"
  retention_in_days = 3  # Short retention for learning

  tags = {
    Name = "${var.project_name}-database-logs-${var.environment}"
  }
}

# Security Group for Database Container
resource "aws_security_group" "database_container" {
  count = var.enable_database_container ? 1 : 0
  
  name_prefix = "${var.project_name}-db-container-${var.environment}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from backend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-container-sg-${var.environment}"
  }
}

# Service Discovery for Database Container
resource "aws_service_discovery_service" "database_container" {
  count = var.enable_database_container ? 1 : 0
  
  name = "database"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name = "${var.project_name}-database-discovery-${var.environment}"
  }
}

# EFS File System for Database Persistence (Optional)
resource "aws_efs_file_system" "database" {
  count = var.enable_database_container && var.enable_database_persistence ? 1 : 0
  
  creation_token = "${var.project_name}-database-${var.environment}"
  
  performance_mode = "generalPurpose"
  throughput_mode  = "provisioned"
  provisioned_throughput_in_mibps = 1  # Minimum for cost optimization

  tags = {
    Name = "${var.project_name}-database-efs-${var.environment}"
    Purpose = "database-persistence"
  }
}

# EFS Mount Targets
resource "aws_efs_mount_target" "database" {
  count = var.enable_database_container && var.enable_database_persistence ? length(aws_subnet.private) : 0
  
  file_system_id  = aws_efs_file_system.database[0].id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs[0].id]
}

# Security Group for EFS
resource "aws_security_group" "efs" {
  count = var.enable_database_container && var.enable_database_persistence ? 1 : 0
  
  name_prefix = "${var.project_name}-efs-${var.environment}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "NFS from ECS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = {
    Name = "${var.project_name}-efs-sg-${var.environment}"
  }
}

# Local values for database connections
locals {
  # Simple database endpoint for Aurora
  aurora_endpoint = var.enable_aurora ? aws_rds_cluster.aurora_postgres[0].endpoint : "localhost:5432"
  rds_endpoint = var.enable_database ? aws_db_instance.main[0].endpoint : "localhost:5432"
}

# Additional variables for containerized database
variable "enable_database_persistence" {
  description = "Enable EFS persistence for containerized database (additional cost)"
  type        = bool
  default     = false
}
