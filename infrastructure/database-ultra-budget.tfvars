# Ultra Budget Database Configuration
# This configuration minimizes database costs to nearly zero

# ====================================================================
# OPTION 1: NO DATABASE (Use SQLite in containers)
# ====================================================================
enable_database = false
enable_local_database = true

# ====================================================================
# OPTION 2: CONTAINERIZED POSTGRESQL (Fargate Spot pricing)
# ====================================================================
# enable_database = false
# enable_database_container = true
# enable_database_persistence = false  # No persistence = no EFS cost

# ====================================================================
# OPTION 3: MINIMAL RDS (if you need managed database)
# ====================================================================
# enable_database = true
# database_mode = "ultra-budget"
# database_backup_retention = 0        # No backups = cost savings
# database_performance_insights = false
# database_monitoring_interval = 0
# enable_database_multi_az = false

# ====================================================================
# COST COMPARISON (Monthly)
# ====================================================================
# SQLite in containers:     $0 (just Fargate Spot when running)
# Containerized PostgreSQL: ~$2-5 (Fargate Spot + EFS if persistent)
# Ultra-budget RDS:         ~$12-15 (t3.micro + minimal features)
# Standard RDS:              ~$25-35 (with backups and monitoring)
