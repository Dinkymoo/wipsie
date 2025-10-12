# Aurora Learning Configuration - AWS Query Editor Enabled
# Estimated cost: $20-25/month (keeps both RDS and Aurora for comparison)

# Enable Aurora with Query Editor support
enable_aurora = true
aurora_serverless_v2 = true
aurora_min_capacity = 0.5
aurora_max_capacity = 1.0

# Keep existing RDS for cost/feature comparison
enable_database = true
database_mode = "learning"

# Cost optimization settings
database_backup_retention = 1
database_performance_insights = false
database_monitoring_interval = 0

# Environment settings
environment = "learning"

# Database credentials (same as RDS for easy comparison)
db_name = "wipsie"
db_username = "postgres"
# db_password will use existing value from terraform.tfvars
