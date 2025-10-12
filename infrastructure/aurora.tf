# Aurora PostgreSQL Configuration for AWS Query Editor
# This enables the AWS RDS Query Editor functionality

# Aurora PostgreSQL Cluster
resource "aws_rds_cluster" "aurora_postgres" {
  count = var.enable_aurora ? 1 : 0

  cluster_identifier     = "${local.name_prefix}-aurora"
  engine                = "aurora-postgresql"
  engine_mode           = "provisioned"
  engine_version        = "13.21"
  database_name         = var.db_name
  master_username       = var.db_username
  master_password       = var.db_password
  
  # 🎯 CRITICAL: Enable Data API for Query Editor
  enable_http_endpoint = true
  
  # Backup configuration
  backup_retention_period = var.database_backup_retention
  preferred_backup_window = "03:00-04:00"
  
  # Maintenance
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  
  # Security
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  # Encryption (optional for learning environment)
  storage_encrypted = var.environment == "production"
  
  # Serverless v2 scaling (cost optimization)
  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.aurora_serverless_v2 ? [1] : []
    content {
      max_capacity = var.aurora_max_capacity
      min_capacity = var.aurora_min_capacity
    }
  }
  
  # Skip final snapshot for learning environment
  skip_final_snapshot = var.environment != "production"
  final_snapshot_identifier = var.environment == "production" ? "${local.name_prefix}-aurora-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null
  
  # Deletion protection for production
  deletion_protection = var.environment == "production"
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aurora-cluster"
    Purpose = "QueryEditor"
  })
}

# Aurora Cluster Instances (regular Aurora)
resource "aws_rds_cluster_instance" "aurora_instances" {
  count = var.enable_aurora && !var.aurora_serverless_v2 ? 1 : 0

  identifier           = "${local.name_prefix}-aurora-${count.index}"
  cluster_identifier   = aws_rds_cluster.aurora_postgres[0].id
  instance_class       = var.aurora_instance_class
  engine               = aws_rds_cluster.aurora_postgres[0].engine
  engine_version       = aws_rds_cluster.aurora_postgres[0].engine_version
  
  publicly_accessible = false
  
  performance_insights_enabled = var.database_performance_insights
  monitoring_interval         = var.database_monitoring_interval
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aurora-instance-${count.index}"
  })
}

# Aurora Serverless v2 Instance (recommended for cost optimization)
resource "aws_rds_cluster_instance" "aurora_serverless_instance" {
  count = var.enable_aurora && var.aurora_serverless_v2 ? 1 : 0

  identifier           = "${local.name_prefix}-aurora-serverless"
  cluster_identifier   = aws_rds_cluster.aurora_postgres[0].id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora_postgres[0].engine
  engine_version       = aws_rds_cluster.aurora_postgres[0].engine_version
  
  publicly_accessible = false
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aurora-serverless"
    CostOptimized = "true"
  })
}

# Outputs for Aurora
output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint"
  value       = var.enable_aurora ? aws_rds_cluster.aurora_postgres[0].endpoint : null
  sensitive   = true
}

output "aurora_cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = var.enable_aurora ? aws_rds_cluster.aurora_postgres[0].reader_endpoint : null
  sensitive   = true
}

output "aurora_cluster_identifier" {
  description = "Aurora cluster identifier for Query Editor"
  value       = var.enable_aurora ? aws_rds_cluster.aurora_postgres[0].cluster_identifier : null
}

output "aurora_database_name" {
  description = "Aurora database name"
  value       = var.enable_aurora ? aws_rds_cluster.aurora_postgres[0].database_name : null
}

output "aurora_query_editor_url" {
  description = "Direct URL to AWS Query Editor"
  value       = var.enable_aurora ? "https://console.aws.amazon.com/rds/home?region=${var.aws_region}#query-editor:" : null
}

output "aurora_data_api_enabled" {
  description = "Whether Data API is enabled for Query Editor"
  value       = var.enable_aurora ? aws_rds_cluster.aurora_postgres[0].enable_http_endpoint : false
}
