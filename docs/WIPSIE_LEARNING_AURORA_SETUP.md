# 🎯 wipsie-learning-aurora Database Setup Guide

## ✅ Quick Start with Query Editor

### 1. Access AWS Query Editor
🔗 **Open**: https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:

### 2. Select Your Cluster
- Choose: `wipsie-learning-aurora` 
- Database: `wipsie` (or create it)
- Authentication: Use Data API with database credentials

### 3. Create Database Schema
Run these SQL commands in Query Editor:

```sql
-- Create database (if not exists)
CREATE DATABASE wipsie;

-- Connect to wipsie database, then create tables:

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tasks table  
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    priority INTEGER DEFAULT 1,
    due_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Data points table
CREATE TABLE data_points (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
    data_type VARCHAR(50) NOT NULL,
    value_json JSONB,
    metadata JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_data_points_task_id ON data_points(task_id);
CREATE INDEX idx_data_points_timestamp ON data_points(timestamp);
```

### 4. Insert Sample Data
```sql
-- Sample user
INSERT INTO users (username, email, password_hash) 
VALUES ('demo_user', 'demo@example.com', 'hashed_password_here');

-- Sample task
INSERT INTO tasks (user_id, title, description, status, priority) 
VALUES (1, 'Setup Database', 'Configure Aurora PostgreSQL with Query Editor', 'completed', 1);

-- Sample data point
INSERT INTO data_points (task_id, data_type, value_json, metadata) 
VALUES (1, 'completion', '{"percentage": 100}', '{"source": "manual"}');
```

### 5. Test Queries
```sql
-- View all data
SELECT u.username, t.title, t.status, dp.data_type, dp.value_json
FROM users u
JOIN tasks t ON u.id = t.user_id
LEFT JOIN data_points dp ON t.id = dp.task_id
ORDER BY t.created_at DESC;

-- Count tasks by status
SELECT status, COUNT(*) as count
FROM tasks
GROUP BY status;
```

## 🛠️ Alternative: Alembic Deployment

If you prefer using Alembic migrations:

### 1. Get Cluster Endpoint
From AWS Console → RDS → Databases → wipsie-learning-aurora → Connectivity
Copy the endpoint URL (looks like: `wipsie-learning-aurora.cluster-xxxxx.us-east-1.rds.amazonaws.com`)

### 2. Set Environment Variables
```bash
export DB_PASSWORD="ChangeMe123!"  # or your actual password
export AURORA_ENDPOINT="your-cluster-endpoint-here"
export DATABASE_URL="postgresql+psycopg://postgres:${DB_PASSWORD}@${AURORA_ENDPOINT}:5432/wipsie"
```

### 3. Run Alembic
```bash
# Create database first (using psql)
PGPASSWORD="$DB_PASSWORD" psql -h "$AURORA_ENDPOINT" -U postgres -d postgres -c "CREATE DATABASE wipsie;"

# Run migrations
alembic upgrade head
```

## 📊 Connection Details

- **Cluster**: wipsie-learning-aurora  
- **Engine**: Aurora PostgreSQL 13.21
- **Serverless**: v2 (0.5-2.0 ACUs)
- **Data API**: ✅ Enabled (for Query Editor)
- **Database**: wipsie
- **Username**: postgres
- **Password**: ChangeMe123! (if using default)

## 🎯 Query Editor Benefits

✅ **No local setup required** - runs in browser
✅ **No VPN/security groups** - uses Data API
✅ **Visual interface** - easy query building
✅ **Result export** - download query results
✅ **Query history** - saved for later use

## 🔗 Quick Links

- **Query Editor**: https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:
- **Database Console**: https://console.aws.amazon.com/rds/home?region=us-east-1#databases:
- **Cluster Details**: https://console.aws.amazon.com/rds/home?region=us-east-1#database:id=wipsie-learning-aurora

## 💰 Cost Info

- **Estimated**: $15-30/month
- **Serverless**: Scales down when not in use
- **Monitoring**: Basic (cost optimized)

---

## ✨ Ready to Use!

Your `wipsie-learning-aurora` cluster is ready for Query Editor access. Choose either:
1. **Query Editor** (recommended) - browser-based SQL interface
2. **Alembic** - automated schema deployment

Both will give you a fully functional PostgreSQL database! 🚀
