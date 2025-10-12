# 🔍 Database Query Options for Wipsie

## 🎯 Current Status
- **Current Setup**: RDS PostgreSQL (limited user: wipsie-sqs-user)
- **Target**: Aurora PostgreSQL with AWS Query Editor access
- **Blocker**: Limited AWS permissions for Aurora deployment

## 🛠️ Available Query Tools (Current Setup)

### 1. 🐘 pgAdmin (Recommended)
```bash
# Install pgAdmin in container
apt update && apt install -y pgadmin4

# Or use pgAdmin web interface
docker run -p 5050:80 \
  -e PGADMIN_DEFAULT_EMAIL=admin@wipsie.com \
  -e PGADMIN_DEFAULT_PASSWORD=password \
  -d dpage/pgadmin4
```
Access: http://localhost:5050

### 2. 🦆 DBeaver (Universal Tool)
```bash
# Download DBeaver Community
wget https://dbeaver.io/files/dbeaver-ce-latest-linux.gtk.x86_64.tar.gz
tar -xzf dbeaver-ce-latest-linux.gtk.x86_64.tar.gz
./dbeaver/dbeaver
```

### 3. 🔧 psql (Command Line)
```bash
# Install PostgreSQL client
apt update && apt install -y postgresql-client

# Connect to database
psql -h YOUR_RDS_ENDPOINT -U YOUR_USERNAME -d YOUR_DATABASE
```

### 4. 🌐 Adminer (Web-based)
```bash
# Run Adminer in Docker
docker run -p 8080:8080 -d adminer

# Access: http://localhost:8080
# Server: your-rds-endpoint
# Username: your-db-username  
# Password: your-db-password
# Database: your-database-name
```

## 🌟 AWS Query Editor (Aurora Only)

### Requirements:
- ✅ Aurora PostgreSQL cluster (not regular RDS)
- ✅ Data API enabled on cluster
- ✅ AWS credentials with RDS permissions
- ❌ Current Issue: Limited AWS user permissions

### Cost-Optimized Aurora Options:
1. **Aurora Serverless v2**: ~$15-30/month, auto-scaling
2. **Aurora t3.medium**: ~$25-40/month, fixed capacity  
3. **Aurora Spot**: ~$10-20/month, interruptible

### Manual Aurora Setup (AWS Console):
1. Go to RDS Console → Create Database
2. Choose "Aurora (PostgreSQL Compatible)"
3. Select "Serverless v2" for cost optimization
4. Enable "Data API" in Connectivity section
5. Access Query Editor at: https://console.aws.amazon.com/rds/home#query-editor:

## 🔧 Next Steps

### Option A: Get Broader AWS Permissions
```bash
# Need AWS user with these policies:
# - AmazonRDSFullAccess
# - AmazonVPCFullAccess  
# - IAMFullAccess
# - CloudWatchFullAccess
```

### Option B: Use Alternative Query Tools
- **Immediate**: Use pgAdmin or DBeaver with current RDS
- **Web-based**: Use Adminer for browser access
- **Command-line**: Use psql for direct SQL access

### Option C: Manual Aurora Setup
- Create Aurora cluster manually in AWS Console
- Enable Data API for Query Editor access
- Use cost-optimized Serverless v2 configuration

## 📚 Connection Information
Once you have your database details, you'll need:
- **Host**: RDS/Aurora endpoint
- **Port**: 5432 (PostgreSQL default)
- **Database**: Your database name
- **Username**: Database username  
- **Password**: Database password
