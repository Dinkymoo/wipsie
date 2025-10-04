# 🗄️ Database Functions Module

Advanced SQLAlchemy utilities for the Wipsie backend application.

## 📁 Module Structure

```
db_functions/
├── __init__.py         # Core SQLAlchemy imports and exports
├── session.py          # Database session management
├── queries.py          # Repository pattern and query utilities
├── utils.py            # Database administration utilities
└── README.md           # This documentation
```

## 🚀 Quick Start

```python
from backend.core.db_functions import (
    get_db_session, 
    BaseRepository,
    filter_by_fields,
    search_by_text
)
from backend.models import User

# Using session context manager
with get_db_session() as db:
    user_repo = BaseRepository(User, db)
    user = user_repo.get(1)
```

## 📦 Core Components

### 🔧 Session Management (`session.py`)

**Context Manager for Database Sessions:**
```python
from backend.core.db_functions import get_db_session

with get_db_session() as db:
    # Database operations with automatic cleanup
    # Commits on success, rolls back on error
    pass
```

**FastAPI Dependency:**
```python
from fastapi import Depends
from backend.core.db_functions import get_db

@app.get("/users/")
async def read_users(db: Session = Depends(get_db)):
    return get_users(db)
```

### 🏗️ Repository Pattern (`queries.py`)

**Generic CRUD Repository:**
```python
from backend.core.db_functions import BaseRepository
from backend.models import User

# Initialize repository
user_repo = BaseRepository(User, db)

# CRUD operations
user = user_repo.get(1)                           # Get by ID
users = user_repo.get_all(skip=0, limit=10)      # Get with pagination
new_user = user_repo.create({"name": "John"})    # Create new record
updated = user_repo.update(1, {"name": "Jane"})  # Update existing
deleted = user_repo.delete(1)                    # Delete by ID
count = user_repo.count()                        # Count total records
```

**Query Utilities:**
```python
from backend.core.db_functions import filter_by_fields, search_by_text, order_by_field

# Apply filters
query = db.query(User)
filtered = filter_by_fields(query, User, {"is_active": True, "role": "admin"})

# Text search across multiple fields
searched = search_by_text(query, User, ["name", "email"], "john")

# Add ordering
ordered = order_by_field(query, User, "created_at", desc_order=True)
```

### 🛠️ Database Utilities (`utils.py`)

**Table Management:**
```python
from backend.core.db_functions import check_table_exists, get_table_columns

# Check if table exists
exists = check_table_exists(db, "users")

# Get table column information
columns = get_table_columns(db, "users")
```

**Raw SQL Execution:**
```python
from backend.core.db_functions import execute_raw_sql

# Execute raw SQL with parameters
result = execute_raw_sql(
    db, 
    "SELECT * FROM users WHERE created_at > :date",
    {"date": "2023-01-01"}
)
```

**PostgreSQL Specific:**
```python
from backend.core.db_functions import (
    get_database_version,
    vacuum_analyze_table,
    get_table_size
)

# Get database version
version = get_database_version(db)

# Maintenance operations
vacuum_analyze_table(db, "users")

# Get table size information
size_info = get_table_size(db, "users")
# Returns: {"total_size": "10 MB", "table_size": "8 MB", "index_size": "2 MB"}
```

## 🎯 Usage Examples

### Example 1: User Management Service

```python
from backend.core.db_functions import get_db_session, BaseRepository
from backend.models import User

class UserService:
    def __init__(self):
        pass
    
    def get_active_users(self, limit: int = 100):
        with get_db_session() as db:
            user_repo = BaseRepository(User, db)
            # Use the built-in filtering
            query = db.query(User)
            filtered = filter_by_fields(query, User, {"is_active": True})
            return filtered.limit(limit).all()
    
    def search_users(self, search_term: str):
        with get_db_session() as db:
            query = db.query(User)
            return search_by_text(
                query, User, 
                ["username", "email", "first_name", "last_name"], 
                search_term
            ).all()
```

### Example 2: Advanced Query Building

```python
from backend.core.db_functions import *

def get_filtered_tasks(status: str = None, search: str = None, 
                      order_by: str = "created_at", desc: bool = True):
    with get_db_session() as db:
        query = db.query(Task)
        
        # Apply filters if provided
        if status:
            query = filter_by_fields(query, Task, {"status": status})
        
        # Apply text search if provided
        if search:
            query = search_by_text(query, Task, ["title", "description"], search)
        
        # Apply ordering
        query = order_by_field(query, Task, order_by, desc)
        
        return query.all()
```

### Example 3: Database Maintenance

```python
from backend.core.db_functions import *

def maintenance_report():
    with get_db_session() as db:
        tables = ["users", "tasks", "data_points"]
        report = {}
        
        for table in tables:
            if check_table_exists(db, table):
                report[table] = {
                    "exists": True,
                    "size": get_table_size(db, table),
                    "columns": len(get_table_columns(db, table))
                }
                # Run maintenance
                vacuum_analyze_table(db, table)
            else:
                report[table] = {"exists": False}
        
        return report
```

## 🔒 Error Handling

All functions include comprehensive error handling:

- **SQLAlchemyError**: Database-specific errors are caught and logged
- **Automatic Rollback**: Sessions automatically rollback on errors
- **Logging**: All errors are logged with context
- **Graceful Degradation**: Functions return sensible defaults on error

## 🧪 Testing

```python
# Example test using the utilities
def test_user_repository():
    with get_db_session() as db:
        user_repo = BaseRepository(User, db)
        
        # Test create
        user_data = {"username": "test", "email": "test@example.com"}
        user = user_repo.create(user_data)
        assert user.username == "test"
        
        # Test get
        retrieved = user_repo.get(user.id)
        assert retrieved.email == "test@example.com"
        
        # Test update
        updated = user_repo.update(user.id, {"username": "updated"})
        assert updated.username == "updated"
        
        # Test delete
        deleted = user_repo.delete(user.id)
        assert deleted is True
```

## 📚 API Reference

### Core Exports

From `backend.core.db_functions`:

**SQLAlchemy Core:**
- `Session`, `sessionmaker`, `declarative_base`, `relationship`
- `create_engine`, `Column`, `Integer`, `String`, `DateTime`, `Boolean`, `ForeignKey`, `Text`
- `SQLAlchemyError`

**Session Management:**
- `get_db_session()` - Context manager for sessions
- `get_db()` - FastAPI dependency for sessions

**Repository Pattern:**
- `BaseRepository` - Generic CRUD repository class
- `filter_by_fields()` - Apply field-based filters
- `search_by_text()` - Text search across fields
- `order_by_field()` - Add ordering to queries

**Database Utilities:**
- `check_table_exists()` - Check if table exists
- `get_table_columns()` - Get table column info
- `execute_raw_sql()` - Execute raw SQL safely
- `get_database_version()` - Get DB version
- `vacuum_analyze_table()` - PostgreSQL maintenance
- `get_table_size()` - Get table size info

## 🔗 Integration

This module integrates seamlessly with:

- **FastAPI**: Use `get_db()` as a dependency
- **Alembic**: Works with existing migration system
- **Celery**: Use in background tasks with proper session management
- **Testing**: Easy to mock and test
- **Logging**: Comprehensive error logging throughout

---

**Built for production use with the Wipsie backend! 🚀**
