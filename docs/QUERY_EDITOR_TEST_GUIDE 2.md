# 🧪 Query Editor Test Guide for wipsie-learning-aurora

## 🎯 Step-by-Step Testing

### 1. Select Your Cluster
In the Query Editor that just opened:
- **Database**: Select `wipsie-learning-aurora` from dropdown
- **Database name**: Enter `postgres` (to start)
- **Authentication**: Use database credentials
- **Username**: `postgres` 
- **Password**: `WipsieAurora2024!` (after reset)

### 2. Test Basic Connection
Run this simple query first:
```sql
SELECT version();
```
Expected result: PostgreSQL version information

### 3. Create the wipsie Database
```sql
CREATE DATABASE wipsie;
```

### 4. Switch to wipsie Database
- Change **Database name** from `postgres` to `wipsie`
- Click **Connect to database**

### 5. Create Application Tables
```sql
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
```

### 6. Create Indexes for Performance
```sql
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_data_points_task_id ON data_points(task_id);
CREATE INDEX idx_data_points_timestamp ON data_points(timestamp);
```

### 7. Insert Sample Data
```sql
-- Sample user
INSERT INTO users (username, email, password_hash) 
VALUES ('demo_user', 'demo@wipsie.com', '$2b$12$sample_hash_here');

-- Sample task
INSERT INTO tasks (user_id, title, description, status, priority) 
VALUES (1, 'Test Query Editor', 'Verify Aurora PostgreSQL with Query Editor works', 'in_progress', 1);

-- Sample data point
INSERT INTO data_points (task_id, data_type, value_json, metadata) 
VALUES (1, 'test_result', '{"success": true, "response_time": 150}', '{"source": "query_editor_test"}');
```

### 8. Test Complex Query
```sql
-- Join all tables to verify relationships
SELECT 
    u.username,
    u.email,
    t.title as task_title,
    t.status,
    t.priority,
    dp.data_type,
    dp.value_json,
    dp.timestamp
FROM users u
JOIN tasks t ON u.id = t.user_id
LEFT JOIN data_points dp ON t.id = dp.task_id
ORDER BY t.created_at DESC;
```

### 9. Test JSON Queries (PostgreSQL Feature)
```sql
-- Query JSON data
SELECT 
    task_id,
    data_type,
    value_json->>'success' as success,
    value_json->>'response_time' as response_time,
    metadata->>'source' as source
FROM data_points 
WHERE value_json->>'success' = 'true';
```

### 10. Verify Table Structure
```sql
-- List all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Check users table structure
\d users;

-- Count records in each table
SELECT 'users' as table_name, count(*) as record_count FROM users
UNION ALL
SELECT 'tasks' as table_name, count(*) as record_count FROM tasks  
UNION ALL
SELECT 'data_points' as table_name, count(*) as record_count FROM data_points;
```

## ✅ Expected Results

After running all tests, you should have:
- ✅ **Database**: `wipsie` created and connected
- ✅ **Tables**: users, tasks, data_points with proper relationships
- ✅ **Indexes**: Performance indexes created
- ✅ **Data**: Sample records inserted and queryable
- ✅ **JSON**: PostgreSQL JSONB functionality working
- ✅ **Joins**: Complex queries across multiple tables

## 🎉 Success Indicators

If everything works, you should see:
1. **Connection successful** to wipsie-learning-aurora
2. **Tables created** without errors  
3. **Data inserted** and retrievable
4. **JSON queries** returning expected results
5. **Query Editor interface** functioning smoothly

## 🚨 Troubleshooting

If you encounter issues:
- **Connection fails**: Password reset to `WipsieAurora2024!` - try this
- **Database not found**: Create `wipsie` database first
- **Permission denied**: Verify Data API is enabled
- **Timeout**: Check Aurora cluster status in RDS console

---

## 🔗 Quick Links
- **Query Editor**: https://console.aws.amazon.com/rds/home?region=us-east-1#query-editor:
- **RDS Console**: https://console.aws.amazon.com/rds/home?region=us-east-1#databases:

Ready to test! 🚀
