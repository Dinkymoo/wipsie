# Aurora Serverless Only Configuration - Maximum Cost Optimization
# Estimated cost: $15-20/month (replaces RDS entirely)

# Enable Aurora Serverless v2 with Query Editor
enable_aurora = true
aurora_serverless_v2 = true
aurora_min_capacity = 0.5
aurora_max_capacity = 2.0

# Disable regular RDS to save costs (Aurora replaces it)
enable_database = false

# Ultra cost optimization
database_backup_retention = 1
database_performance_insights = false
database_monitoring_interval = 0

# Environment
environment = "learning"

# Database settings
db_name = "wipsie"
db_username = "postgres"
# db_password will use existing value
