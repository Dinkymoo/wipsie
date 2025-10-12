# 🗄️ Database Cost Optimization Guide

## Overview
Your Wipsie learning environment now supports **flexible database configurations** to optimize costs based on your learning phase and budget.

## 🎯 Quick Cost Comparison

| Mode | Monthly Cost | Database Type | Best For |
|------|-------------|---------------|----------|
| **Ultra-Budget** | **$0** | SQLite in containers | Testing, quick experiments |
| **Containerized** | **$1-5** | PostgreSQL on Fargate Spot | Active learning, can pause |
| **Learning RDS** | **$12-15** | Managed PostgreSQL (minimal) | Consistent learning, always-on |
| **Development** | **$25-35** | Full RDS features | Serious development |

## 🚀 Quick Start

### Switch Database Modes
```bash
# Interactive menu
./scripts/database-cost-optimizer.sh

# Or use Terraform directly
cd infrastructure

# Ultra-Budget (SQLite)
terraform apply -var-file="database-ultra-budget.tfvars" -auto-approve

# Learning RDS
terraform apply -var-file="database-learning.tfvars" -auto-approve
```

### Check Current Status
```bash
cd infrastructure
terraform show | grep -E "(db_instance|ecs_service.*database)"
```

## 💡 Mode Details

### 1. Ultra-Budget Mode ($0/month)
- **Database**: SQLite files in application containers
- **Persistence**: Data lost when containers restart
- **Use Case**: Quick testing, trying features
- **Switch Command**: Choose option 1 in the optimizer script

**Pros**: No database costs, instant startup
**Cons**: Data not persistent between deployments

### 2. Containerized Mode ($1-5/month)
- **Database**: PostgreSQL running in Fargate Spot containers
- **Persistence**: Optional EFS file system
- **Use Case**: Active learning that you can pause
- **Features**:
  - Scales to zero when not in use
  - 70% cheaper than always-on RDS
  - Can enable/disable persistence

**Configuration Options**:
```bash
# Without persistence (data lost on restart)
terraform apply -var="enable_database_container=true" -var="enable_database_persistence=false"

# With EFS persistence (data survives restarts)
terraform apply -var="enable_database_container=true" -var="enable_database_persistence=true"
```

### 3. Learning RDS Mode ($12-15/month)
- **Database**: AWS RDS PostgreSQL t3.micro
- **Features**: Minimal backups, basic monitoring
- **Use Case**: Consistent learning environment
- **Configuration**: Pre-configured in `database-learning.tfvars`

### 4. Development Mode ($25-35/month)
- **Database**: AWS RDS with full features
- **Features**: Enhanced monitoring, performance insights, automated backups
- **Use Case**: Serious development work

## 🔧 Manual Configuration

### Key Variables
```hcl
# In terraform.tfvars or as -var flags
enable_database = true/false              # Enable RDS
database_mode = "ultra-budget|learning|development"
enable_database_container = true/false    # Enable containerized DB
enable_database_persistence = true/false  # Enable EFS for containers
database_backup_retention = 0-35         # Days to keep backups
```

### Environment Variables for Application
The application automatically detects the database type:

```bash
# Will be set automatically based on your configuration
DATABASE_URL=postgresql://...  # For RDS or containerized
DATABASE_URL=sqlite:///app.db  # For ultra-budget mode
```

## 📊 Cost Optimization Strategies

### For Maximum Savings
1. **Start with Ultra-Budget** for initial learning
2. **Upgrade to Containerized** when you need real PostgreSQL
3. **Use Learning RDS** only when you need always-on database
4. **Scale up to Development** only for serious projects

### For Learning Phases
- **Week 1-2**: Ultra-Budget (learning basics)
- **Week 3-4**: Containerized (real database features)
- **Month 2+**: Learning RDS (consistent environment)
- **Project phase**: Development (full features)

## 🔄 Switching Between Modes

### Safe Switching (with backup)
```bash
# 1. Backup current data (if using RDS)
aws rds create-db-snapshot --db-instance-identifier your-db --db-snapshot-identifier backup-$(date +%Y%m%d)

# 2. Export application data
./scripts/export-data.sh  # If you created this

# 3. Switch modes
./scripts/database-cost-optimizer.sh

# 4. Import data if needed
./scripts/import-data.sh  # If you created this
```

### Quick Switching (data loss acceptable)
```bash
./scripts/database-cost-optimizer.sh
# Choose your new mode and confirm
```

## 🎓 Learning Recommendations

### Week 1: Start Ultra-Budget
```bash
cd infrastructure
terraform apply -var-file="database-ultra-budget.tfvars" -auto-approve
```
- Learn FastAPI basics
- Understand container concepts
- No database costs while learning

### Week 2-3: Upgrade to Containerized
```bash
./scripts/database-cost-optimizer.sh
# Choose option 2, enable persistence
```
- Learn real PostgreSQL features
- Practice database migrations
- Still very low cost ($1-5/month)

### Month 2+: Consider Learning RDS
```bash
terraform apply -var-file="database-learning.tfvars" -auto-approve
```
- Always-available database
- Learn RDS management
- Consistent environment

## 🚨 Important Notes

### Data Persistence
- **Ultra-Budget**: Data lost on container restart
- **Containerized**: Data persists if EFS enabled
- **RDS**: Data always persists with backups

### Switching Costs
- **To Higher Tier**: No data loss (usually)
- **To Lower Tier**: May lose data (backup first!)
- **Between RDS modes**: Usually safe
- **RDS to Container**: Requires data migration

### Network Access
All database modes are accessible from:
- Backend containers (always)
- Lambda functions (if configured)
- Local development (with proper security groups)

## 🔍 Troubleshooting

### Check Current Configuration
```bash
cd infrastructure
terraform output
```

### Database Connection Issues
```bash
# Check if database service is running
aws ecs list-services --cluster wipsie-cluster
aws rds describe-db-instances
```

### Cost Monitoring
```bash
# Use the dashboard
open http://localhost:3000/dashboard

# Or check AWS CLI
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

---

**💰 Remember**: Start small, scale up as you learn. You can always upgrade your database tier, but downgrades may require data migration planning!
