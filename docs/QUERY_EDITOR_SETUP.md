# AWS Query Editor Setup Guide for Wipsie

## 🎯 Choose Your Query Editor Based on Database Mode

### ⚠️ Important: AWS RDS Query Editor Limitation
**AWS RDS Query Editor only works with Aurora Serverless databases.** Your current RDS PostgreSQL instance is NOT compatible with AWS Query Editor.

### Current Database Mode Check
```bash
# Check your current database setup
./scripts/database-cost-optimizer.sh
# Or
cd infrastructure && terraform show | grep -E "(db_instance|ecs_service.*database)"
```

## 1. 🥇 pgAdmin (Recommended for RDS PostgreSQL)

**Best for:** All database modes - works with your current RDS setup

### Quick Setup (30 seconds):
```bash
# One-command setup
./scripts/setup-pgadmin.sh

# Or manual Docker command
docker run -d -p 8080:80 \
  -e PGADMIN_DEFAULT_EMAIL=admin@wipsie.com \
  -e PGADMIN_DEFAULT_PASSWORD=admin123 \
  --name pgadmin \
  dpage/pgadmin4
```

### Access Steps:
1. **Open pgAdmin**: http://localhost:8080
2. **Login**: admin@wipsie.com / admin123
3. **Add Server**: Right-click Servers → Register → Server
4. **Connection details**: Use your RDS endpoint from terraform output

### Features:
- ✅ Works with your current RDS PostgreSQL
- ✅ Full-featured database administration
- ✅ Query editor with syntax highlighting
- ✅ Visual table browser
- ✅ Import/export capabilities
- ✅ No additional AWS costs

## 2. ❌ AWS RDS Query Editor (NOT AVAILABLE)

**❌ Does NOT work with regular RDS PostgreSQL**
- AWS RDS Query Editor only supports Aurora Serverless with Data API enabled
- Your db.t3.micro PostgreSQL instance is not compatible
- Would require switching to Aurora Serverless (~$30-50/month more expensive)

## 2. 🥈 pgAdmin Container (For Containerized DB)

**Best for:** Containerized database mode ($1-5/month)

### Deploy pgAdmin alongside your database:
```bash
# Add to your ECS services
cd infrastructure
```

Add this to your `ecs-services.tf`:
```hcl
# pgAdmin Container Service
resource "aws_ecs_task_definition" "pgadmin" {
  count = var.enable_database_container ? 1 : 0
  
  family                   = "wipsie-pgadmin"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "pgadmin"
      image = "dpage/pgadmin4:latest"
      
      environment = [
        {
          name  = "PGADMIN_DEFAULT_EMAIL"
          value = "admin@wipsie.com"
        },
        {
          name  = "PGADMIN_DEFAULT_PASSWORD"
          value = "wipsie123"
        }
      ]
      
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "pgadmin"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "pgadmin" {
  count = var.enable_database_container ? 1 : 0
  
  name            = "pgadmin"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.pgadmin[0].arn
  desired_count   = 1
  
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight           = 100
  }
  
  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = true
  }
}
```

## 3. 🥉 Local Query Tools

**Best for:** Development and testing

### Option A: DBeaver (Free)
```bash
# Install via package manager
sudo apt-get update
sudo apt-get install dbeaver-ce

# Or download from: https://dbeaver.io/
```

### Option B: DataGrip (Paid)
```bash
# JetBrains DataGrip (30-day trial)
# Download from: https://www.jetbrains.com/datagrip/
```

### Option C: psql (Command line)
```bash
# Install PostgreSQL client
sudo apt-get install postgresql-client

# Connect to your database
psql -h YOUR_RDS_ENDPOINT -U postgres -d wipsie
```

## 4. 🎯 Cost-Optimized Recommendations

### Ultra-Budget Mode ($0/month - SQLite)
```bash
# Use SQLite browser or command line
sudo apt-get install sqlite3 sqlitebrowser

# Access your container's SQLite file
docker exec -it CONTAINER_ID sqlite3 /app/wipsie.db
```

### Containerized Mode ($1-5/month)
- **Primary:** pgAdmin container (deployed above)
- **Alternative:** Local tools connecting to container

### Learning RDS Mode ($12-15/month)
- **Primary:** AWS RDS Query Editor
- **Alternative:** Local tools

### Development Mode ($25-35/month)
- **Primary:** AWS RDS Query Editor
- **Secondary:** DataGrip or DBeaver for advanced features

## 🚀 Quick Setup Commands

### Check Current Setup
```bash
./scripts/cost-monitor.sh
```

### Deploy pgAdmin (if using containerized database)
```bash
cd infrastructure
terraform plan -var="enable_pgadmin=true"
terraform apply -var="enable_pgadmin=true"
```

### Get Connection Details
```bash
# For RDS
terraform output rds_endpoint

# For containerized database
aws ecs describe-services --cluster wipsie-cluster --services database-container
```

## 💡 Pro Tips

1. **Start with AWS RDS Query Editor** - It's free and works perfectly for learning
2. **Use pgAdmin container** if you need advanced database management
3. **Keep local tools** as backup for complex development work
4. **Remember security groups** - Ensure your IP can access the database

## 🔐 Security Configuration

### Allow Query Editor Access
```bash
# Update security group for RDS access
aws ec2 authorize-security-group-ingress \
  --group-id sg-your-rds-security-group \
  --protocol tcp \
  --port 5432 \
  --cidr YOUR_IP/32
```

## 📊 Cost Impact

| Tool | Additional Monthly Cost | Best For |
|------|------------------------|----------|
| AWS RDS Query Editor | $0 | Learning, basic queries |
| pgAdmin Container | ~$1-2 | Advanced management |
| Local Tools | $0 | Development, offline work |

Choose based on your current database mode and learning goals!
