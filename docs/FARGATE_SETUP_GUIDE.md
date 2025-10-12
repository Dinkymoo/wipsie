# Fargate Service Configuration for Cost-Optimized Learning

## Enable Fargate Service in Your Infrastructure

Add this to your `main.tf` or create a separate `fargate-service.tf`:

```hcl
# Fargate Task Definition
resource "aws_ecs_task_definition" "backend" {
  count = var.enable_fargate_service ? 1 : 0
  
  family                   = "${var.project_name}-backend-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = var.fargate_cpu
  memory                  = var.fargate_memory
  execution_role_arn      = aws_iam_role.ecs_task_execution.arn
  task_role_arn          = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${var.backend_image}:${var.backend_image_tag}"
      
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
          value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
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

# Fargate Service (Cost-Optimized)
resource "aws_ecs_service" "backend" {
  count = var.enable_fargate_service ? 1 : 0
  
  name            = "${var.project_name}-backend-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend[0].arn
  
  # Cost optimization: Start with minimal capacity
  desired_count = var.fargate_desired_count
  
  # Use Spot for maximum savings
  capacity_provider_strategy {
    capacity_provider = var.fargate_use_spot ? "FARGATE_SPOT" : "FARGATE"
    weight           = 100
    base            = var.fargate_desired_count
  }
  
  network_configuration {
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
  
  # Deployment configuration
  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 50
  }
  
  # Auto-scaling friendly
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name = "${var.project_name}-backend-service-${var.environment}"
  }
}

# Auto Scaling for Fargate (Optional)
resource "aws_appautoscaling_target" "ecs_target" {
  count = var.enable_fargate_service && var.enable_fargate_autoscaling ? 1 : 0
  
  max_capacity       = var.fargate_max_capacity
  min_capacity       = var.fargate_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scale based on CPU utilization
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
```

## Variables to Add

Add these to your `variables.tf`:

```hcl
# Fargate Configuration
variable "enable_fargate_service" {
  description = "Enable Fargate service for backend application"
  type        = bool
  default     = false
}

variable "fargate_cpu" {
  description = "Fargate CPU units (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256  # Cheapest option for learning
}

variable "fargate_memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 512  # Minimum for 256 CPU
}

variable "fargate_desired_count" {
  description = "Number of Fargate tasks to run"
  type        = number
  default     = 1  # Start small for learning
}

variable "fargate_use_spot" {
  description = "Use Fargate Spot for cost savings (up to 70% cheaper)"
  type        = bool
  default     = true  # Enable spot for learning
}

variable "fargate_min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type        = number
  default     = 0  # Scale to zero when not in use
}

variable "fargate_max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
  default     = 3
}

variable "enable_fargate_autoscaling" {
  description = "Enable auto-scaling for Fargate service"
  type        = bool
  default     = false  # Keep simple for learning
}

variable "backend_image" {
  description = "Docker image for backend application"
  type        = string
  default     = "nginx"  # Placeholder - replace with your image
}

variable "backend_image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}
```

## Cost-Optimized Fargate Configuration

For maximum learning cost savings:

```hcl
# In terraform.tfvars
enable_fargate_service = true
fargate_cpu           = 256      # Smallest CPU allocation
fargate_memory        = 512      # Minimum memory for 256 CPU
fargate_desired_count = 1        # Single task
fargate_use_spot      = true     # 70% cost savings
fargate_min_capacity  = 0        # Scale to zero when not learning
fargate_max_capacity  = 2        # Limit scaling for cost control
enable_fargate_autoscaling = true # Auto-scale based on usage
```

## Usage Commands

```bash
# Enable Fargate service for learning
terraform apply -var="enable_fargate_service=true"

# Scale up for testing
aws ecs update-service \
  --cluster wipsie-cluster-staging \
  --service wipsie-backend-staging \
  --desired-count 2

# Scale to zero when not learning (save money!)
aws ecs update-service \
  --cluster wipsie-cluster-staging \
  --service wipsie-backend-staging \
  --desired-count 0

# Check service status
aws ecs describe-services \
  --cluster wipsie-cluster-staging \
  --services wipsie-backend-staging
```

## Cost Benefits Summary

- **Pay per second**: Only pay when learning/testing
- **Spot pricing**: Up to 70% savings with Fargate Spot
- **Scale to zero**: No costs when not in use
- **No infrastructure management**: Focus on learning, not server maintenance
- **Perfect for learning**: Start/stop as needed without ongoing costs
```
