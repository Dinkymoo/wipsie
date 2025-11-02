# 🚀 Aurora Database Deployment with Alembic

## 📋 Overview

This guide shows you how to deploy your database schema to Aurora PostgreSQL using Alembic migrations as part of your deployment pipeline.

## 🏗️ What's Been Set Up

### ✅ Alembic Configuration
- **Migration**: `564a2e17e876_initial_migration.py` creates:
  - `users` table (with authentication fields)
  - `tasks` table (for task management)
  - `data_points` table (for data storage)
- **Environment Support**: Configured to use `DATABASE_URL` environment variable
- **Aurora Ready**: Works with both local development and Aurora deployment

### ✅ Deployment Scripts
- `scripts/deploy-aurora-db.sh` - Main deployment script
- `scripts/setup-aurora-quick.sh` - Quick setup with auto-discovery
- `.github/workflows/deploy-database.yml` - GitHub Actions automation

## 🚀 Manual Deployment (Quick Start)

### Step 1: Get Your Aurora Password
From your terraform outputs or AWS Secrets Manager:
```bash
# If using terraform
cd infrastructure
terraform output -json | jq -r '.secrets_manager_arn.value'

# Then get the password from AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id <secret-arn> --query SecretString --output text
```

### Step 2: Deploy Database Schema
```bash
# Set your Aurora password
export DB_PASSWORD="your-aurora-password-here"

# Run the quick setup (auto-discovers Aurora endpoint)
./scripts/setup-aurora-quick.sh
```

## 🔧 Manual Deployment (Step by Step)

### Step 1: Get Aurora Endpoint
```bash
# Find your Aurora cluster
aws rds describe-db-clusters --query 'DBClusters[*].[DBClusterIdentifier,Endpoint,Status]' --output table

# Get the specific endpoint
AURORA_ENDPOINT=$(aws rds describe-db-clusters \
  --query 'DBClusters[?contains(DBClusterIdentifier, `wipsie-learning`)].Endpoint' \
  --output text)

echo "Aurora Endpoint: $AURORA_ENDPOINT"
```

### Step 2: Set Environment Variables
```bash
export AURORA_ENDPOINT="your-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com"
export DB_PASSWORD="your-aurora-password"
```

### Step 3: Deploy Schema
```bash
./scripts/deploy-aurora-db.sh
```

## 🤖 Automated Deployment (GitHub Actions)

### Step 1: Configure GitHub Secrets
In your GitHub repository settings, add these secrets:
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key  
- `AURORA_DB_PASSWORD` - Your Aurora database password

### Step 2: Trigger Deployment
The workflow automatically runs when:
- You push changes to `backend/alembic/versions/`
- You push changes to `backend/models/`
- You manually trigger it from GitHub Actions tab

### Step 3: Manual Trigger
1. Go to **Actions** tab in GitHub
2. Select **Deploy Database to Aurora**
3. Click **Run workflow**
4. Choose environment (learning/staging/production)

## 📊 What Gets Created

Your Aurora database will have these tables:

### `users` Table
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR UNIQUE NOT NULL,
    username VARCHAR UNIQUE NOT NULL,
    hashed_password VARCHAR NOT NULL,
    is_active BOOLEAN DEFAULT true,
    is_superuser BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE
);
```

### `tasks` Table  
```sql
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR NOT NULL,
    description TEXT,
    status VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE
);
```

### `data_points` Table
```sql
CREATE TABLE data_points (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    source VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

## 🔍 Verification

After deployment, verify in AWS Query Editor:
```sql
-- List all tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check migration version
SELECT version_num FROM alembic_version;

-- Test data insertion
INSERT INTO users (email, username, hashed_password) 
VALUES ('test@example.com', 'testuser', 'hashed_password_here');

SELECT * FROM users;
```

## 🔄 Adding New Migrations

When you modify your models:

### Step 1: Create Migration
```bash
# Auto-generate migration from model changes
alembic revision --autogenerate -m "Add new feature"
```

### Step 2: Review & Edit
Check the generated migration file in `backend/alembic/versions/`

### Step 3: Deploy
```bash
# Local testing
DATABASE_URL="postgresql+psycopg://postgres:password@localhost:5432/wipsie_db" alembic upgrade head

# Aurora deployment
./scripts/setup-aurora-quick.sh
```

## 🆘 Troubleshooting

### Connection Issues
```bash
# Test Aurora connection
python -c "
import psycopg
conn = psycopg.connect('postgresql+psycopg://postgres:PASSWORD@ENDPOINT:5432/wipsie')
print('✅ Connection successful!')
conn.close()
"
```

### Database Doesn't Exist
The scripts automatically create the `wipsie` database, but you can create it manually:
```sql
-- Connect to postgres database first
CREATE DATABASE wipsie;
```

### Migration Issues
```bash
# Check current migration version
alembic current

# See migration history
alembic history

# Downgrade if needed
alembic downgrade -1
```

## 🎯 Next Steps

1. **Deploy your schema**: Run `./scripts/setup-aurora-quick.sh`
2. **Test in Query Editor**: Verify tables exist
3. **Connect your app**: Update your FastAPI app with Aurora endpoint
4. **Set up CI/CD**: Configure GitHub Actions for automatic deployments

Your database deployment pipeline is ready! 🚀
