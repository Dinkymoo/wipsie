# 🌟 Aurora PostgreSQL Setup Guide for AWS Query Editor

## 🎯 Overview
To use AWS Query Editor, you need **Aurora Serverless** or **Aurora PostgreSQL** with **Data API enabled**. This guide helps you switch from regular RDS to Aurora PostgreSQL.

## 💰 Cost Comparison

| Database Type | Monthly Cost | Query Editor | Best For |
|---------------|--------------|--------------|----------|
| **Current RDS PostgreSQL** | $12-15 | ❌ Not supported | Basic learning |
| **Aurora Serverless v2** | $15-25 | ✅ Supported | Variable workload |
| **Aurora PostgreSQL** | $20-35 | ✅ Supported | Production-like |

## 🚀 Quick Setup Options

### Option 1: Add Aurora Alongside Current RDS (Recommended)
Keep your current RDS for cost comparison and add Aurora for Query Editor.

### Option 2: Replace RDS with Aurora
Switch completely to Aurora (more expensive but full AWS Query Editor support).

## 📋 Prerequisites

1. Your current Wipsie infrastructure deployed
2. Terraform knowledge
3. AWS CLI configured
4. Backup of current database (optional)

## 🔧 Implementation

### Step 1: Add Aurora Variables

Add to your `infrastructure/variables.tf`:

```hcl
# Aurora PostgreSQL Configuration
variable "enable_aurora" {
  description = "Enable Aurora PostgreSQL cluster"
  type        = bool
  default     = false
}

variable "aurora_instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.t3.medium"
  
  validation {
    condition = can(regex("^db\\.(t3|r5|r6g)\\.(medium|large|xlarge)$", var.aurora_instance_class))
    error_message = "Aurora instance class must be t3.medium or larger."
  }
}

variable "aurora_serverless_v2" {
  description = "Use Aurora Serverless v2 (enables scaling to zero)"
  type        = bool
  default     = false
}

variable "aurora_min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity units"
  type        = number
  default     = 0.5
}

variable "aurora_max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity units"
  type        = number
  default     = 1
}
```

### Step 2: Create Aurora Configuration

Create `infrastructure/aurora.tf`:

```hcl
# Aurora PostgreSQL Cluster
resource "aws_rds_cluster" "aurora_postgres" {
  count = var.enable_aurora ? 1 : 0

  cluster_identifier     = "${local.name_prefix}-aurora"
  engine                = "aurora-postgresql"
  engine_mode           = var.aurora_serverless_v2 ? "provisioned" : "provisioned"
  engine_version        = "13.7"
  database_name         = var.db_name
  master_username       = var.db_username
  master_password       = var.db_password
  
  # Enable Data API for Query Editor
  enable_http_endpoint = true
  
  # Backup configuration
  backup_retention_period = var.database_backup_retention
  preferred_backup_window = "03:00-04:00"
  
  # Maintenance
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  
  # Security
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  # Encryption
  storage_encrypted = true
  kms_key_id       = aws_kms_key.rds.arn
  
  # Serverless v2 scaling (if enabled)
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
  
  tags = local.common_tags
}

# Aurora Cluster Instances
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
  monitoring_role_arn         = var.database_monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  
  tags = local.common_tags
}

# Aurora Serverless v2 Instance (if using serverless)
resource "aws_rds_cluster_instance" "aurora_serverless_instance" {
  count = var.enable_aurora && var.aurora_serverless_v2 ? 1 : 0

  identifier           = "${local.name_prefix}-aurora-serverless"
  cluster_identifier   = aws_rds_cluster.aurora_postgres[0].id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora_postgres[0].engine
  engine_version       = aws_rds_cluster.aurora_postgres[0].engine_version
  
  publicly_accessible = false
  
  tags = local.common_tags
}

# KMS Key for Aurora encryption
resource "aws_kms_key" "aurora" {
  count = var.enable_aurora ? 1 : 0
  
  description             = "KMS key for Aurora PostgreSQL encryption"
  deletion_window_in_days = 7
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aurora-kms"
  })
}

resource "aws_kms_alias" "aurora" {
  count = var.enable_aurora ? 1 : 0
  
  name          = "alias/${local.name_prefix}-aurora"
  target_key_id = aws_kms_key.aurora[0].key_id
}

# Outputs
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
  description = "Aurora cluster identifier"
  value       = var.enable_aurora ? aws_rds_cluster.aurora_postgres[0].cluster_identifier : null
}

output "aurora_database_name" {
  description = "Aurora database name"
  value       = var.enable_aurora ? aws_rds_cluster.aurora_postgres[0].database_name : null
}
```

### Step 3: Create Aurora Configuration Files

Create `infrastructure/aurora-learning.tfvars`:

```hcl
# Aurora Learning Configuration
# Monthly cost: ~$20-25

# Basic settings
enable_aurora = true
aurora_serverless_v2 = true
aurora_min_capacity = 0.5
aurora_max_capacity = 1.0

# Keep existing RDS for comparison
enable_database = true

# Cost optimization
database_backup_retention = 1
database_performance_insights = false
database_monitoring_interval = 0

# Environment
environment = "learning"
```

Create `infrastructure/aurora-serverless.tfvars`:

```hcl
# Aurora Serverless v2 Configuration
# Monthly cost: ~$15-20 (scales to zero)

# Aurora Serverless v2
enable_aurora = true
aurora_serverless_v2 = true
aurora_min_capacity = 0.5
aurora_max_capacity = 2.0

# Disable regular RDS to save costs
enable_database = false

# Minimal settings for cost
database_backup_retention = 1
database_performance_insights = false
database_monitoring_interval = 0

# Environment
environment = "learning"
```

### Step 4: Deploy Aurora

Choose your deployment strategy:

#### Option A: Aurora + Existing RDS (for comparison)
```bash
cd infrastructure
terraform apply -var-file="aurora-learning.tfvars"
```

#### Option B: Aurora Serverless Only (cost-optimized)
```bash
cd infrastructure
terraform apply -var-file="aurora-serverless.tfvars"
```

### Step 5: Enable Data API (Required for Query Editor)

The Data API is enabled in the Terraform configuration, but verify:

```bash
# Check if Data API is enabled
aws rds describe-db-clusters \
  --db-cluster-identifier $(terraform output -raw aurora_cluster_identifier) \
  --query 'DBClusters[0].HttpEndpointEnabled'
```

If not enabled, enable it:

```bash
aws rds modify-db-cluster \
  --db-cluster-identifier $(terraform output -raw aurora_cluster_identifier) \
  --enable-http-endpoint \
  --apply-immediately
```

## 🎯 Access AWS Query Editor

Once Aurora is deployed:

1. **Open AWS Console**: https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:

2. **Select your Aurora cluster**: Should appear in the dropdown

3. **Connect with**:
   - **Database username**: postgres
   - **Password**: Your database password
   - **Database name**: wipsie

4. **Start querying**! 🎉

## 📊 Cost Optimization Strategies

### Ultra-Cost-Optimized Setup
```bash
# Use Aurora Serverless v2 with minimal capacity
terraform apply -var-file="aurora-serverless.tfvars" -var="aurora_min_capacity=0.5" -var="aurora_max_capacity=1"
```

### Learning Environment
```bash
# Keep both RDS and Aurora for comparison
terraform apply -var-file="aurora-learning.tfvars"
```

### Production-Ready
```bash
# Full Aurora with high availability
terraform apply -var="enable_aurora=true" -var="aurora_instance_class=db.r5.large"
```

## 🔄 Migration from RDS to Aurora

If you want to migrate your existing data:

### Step 1: Create a snapshot of your current RDS
```bash
aws rds create-db-snapshot \
  --db-instance-identifier $(terraform output -raw rds_identifier) \
  --db-snapshot-identifier wipsie-migration-$(date +%Y%m%d)
```

### Step 2: Restore Aurora from RDS snapshot
```bash
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier wipsie-aurora-migrated \
  --snapshot-identifier wipsie-migration-$(date +%Y%m%d) \
  --engine aurora-postgresql
```

## 🚨 Important Notes

### Query Editor Requirements
- ✅ Aurora PostgreSQL or Aurora Serverless
- ✅ Data API enabled (`enable_http_endpoint = true`)
- ✅ Cluster accessible from AWS console

### Cost Considerations
- **Aurora Serverless v2**: Scales to near-zero when idle
- **Regular Aurora**: Always running, more expensive
- **Data API**: No additional charges for Query Editor usage

### Performance
- Aurora is generally faster than RDS
- Serverless v2 has cold start delays
- Query Editor has some limitations vs direct connections

## 🎉 Quick Commands

### Deploy Aurora Serverless (Recommended)
```bash
cd infrastructure
terraform apply -var-file="aurora-serverless.tfvars" -auto-approve
```

### Check Aurora Status
```bash
aws rds describe-db-clusters --db-cluster-identifier $(terraform output -raw aurora_cluster_identifier)
```

### Access Query Editor
```bash
echo "Query Editor: https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:"
echo "Cluster: $(terraform output -raw aurora_cluster_identifier)"
```

## 💡 Recommendations

1. **Start with Aurora Serverless v2** - Best cost/feature balance
2. **Keep RDS initially** - Compare costs and features
3. **Use Query Editor for learning** - Great for SQL practice
4. **Monitor costs** - Aurora can be more expensive
5. **Consider pgAdmin as backup** - More features than Query Editor

Ready to enable AWS Query Editor with Aurora PostgreSQL! 🌟
