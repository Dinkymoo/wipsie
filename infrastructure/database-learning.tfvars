# Learning Database Configuration
# Balanced approach for learning with some cost optimization

# ====================================================================
# STANDARD LEARNING SETUP
# ====================================================================
enable_database = true
database_mode = "learning"

# Cost optimizations for learning
database_backup_retention = 1              # Minimal backups
database_performance_insights = false      # Disable expensive monitoring
database_monitoring_interval = 0           # No enhanced monitoring
enable_database_multi_az = false          # Single AZ for cost savings
database_deletion_protection = false       # Easy to recreate for learning
database_skip_final_snapshot = true        # Skip snapshot on destroy

# Alternative cheaper options (uncomment to try)
# enable_database = false
# enable_database_container = true
# enable_database_persistence = true       # Keep data between container restarts

# ====================================================================
# COST COMPARISON FOR LEARNING
# ====================================================================
# This config:              ~$12-15/month (RDS t3.micro with minimal features)
# Containerized with EFS:   ~$3-7/month (Fargate Spot + minimal EFS)
# Containerized no persist: ~$1-3/month (Fargate Spot only, data lost on restart)
