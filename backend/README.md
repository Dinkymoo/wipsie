# 🔧 Wipsie Backend

FastAPI-based backend application with comprehensive database utilities and AWS integration.

## 📁 Directory Structure

```
backend/
├── __init__.py
├── main.py                 # FastAPI application entry point
│
├── 🔧 Core Components
│   ├── core/               # Core application modules
│   │   ├── config.py       # Application settings and configuration
│   │   ├── celery_app.py   # Celery task queue configuration
│   │   └── db_functions/   # 🆕 Advanced SQLAlchemy utilities
│   │       ├── __init__.py # Core imports and exports
│   │       ├── session.py  # Database session management
│   │       ├── queries.py  # Repository pattern & query utils
│   │       ├── utils.py    # Database admin utilities
│   │       └── README.md   # Database functions documentation
│   │
├── 🗄️ Data Layer
│   ├── models/             # SQLAlchemy data models
│   ├── schemas/            # Pydantic request/response schemas
│   ├── db/                 # Database connection setup
│   └── alembic/            # Database migrations
│
├── 🚀 Business Logic
│   ├── services/           # Business logic services
│   │   ├── user_service.py
│   │   ├── task_service.py
│   │   ├── data_point_service.py
│   │   └── lambda_service.py
│   │
├── ⚙️ Background Processing
│   ├── workers/            # Celery worker modules
│   │   ├── celery_app.py
│   │   ├── task_workers.py
│   │   └── data_workers.py
│   │
├── 🌐 API Layer
│   └── api/                # API routes and endpoints
│       ├── routes.py
│       └── endpoints/
│
├── 🛠️ Utilities
│   ├── utils/              # Utility functions
│   └── tests/              # Test modules
```

## 🚀 Quick Start

### Development Setup

```bash
# Activate virtual environment
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run database migrations
alembic upgrade head

# Start development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Using the New Database Functions

```python
# Import the database utilities
from backend.core.db_functions import (
    get_db_session,
    BaseRepository,
    filter_by_fields,
    search_by_text
)
from backend.models import User

# Example service using the utilities
class UserService:
    def get_users(self, filters: dict = None, search: str = None):
        with get_db_session() as db:
            query = db.query(User)
            
            if filters:
                query = filter_by_fields(query, User, filters)
            
            if search:
                query = search_by_text(query, User, ["username", "email"], search)
            
            return query.all()
```

## 🏗️ Architecture Highlights

### 🆕 Database Functions Module

The new `core/db_functions/` module provides:

- **Session Management**: Automatic session handling with context managers
- **Repository Pattern**: Generic CRUD operations for any model
- **Query Utilities**: Advanced filtering, searching, and ordering
- **Admin Tools**: Database maintenance and monitoring utilities

### Configuration Management

- **Environment-based**: Uses Pydantic Settings for configuration
- **Type Safety**: All config values are typed and validated
- **AWS Integration**: Built-in AWS service configuration
- **Development/Production**: Environment-specific settings

### Background Processing

- **Celery Integration**: Distributed task processing
- **AWS SQS**: Message queue for reliable task delivery
- **Modular Workers**: Separate worker modules for different task types
- **Error Handling**: Comprehensive error recovery and logging

## 🔗 Key Integrations

### Database (PostgreSQL)
- **SQLAlchemy ORM**: Object-relational mapping
- **Alembic Migrations**: Database schema versioning
- **Connection Pooling**: Efficient database connections
- **Query Optimization**: Advanced query building utilities

### AWS Services
- **SQS**: Message queuing for background tasks
- **SES**: Email notifications and communications
- **Lambda**: Serverless functions for data processing
- **IAM**: Secure access management

### FastAPI Features
- **Automatic Documentation**: OpenAPI/Swagger integration
- **Type Validation**: Pydantic model validation
- **Dependency Injection**: Clean dependency management
- **Async Support**: High-performance async endpoints

## 📊 API Endpoints

### Health Check
- `GET /health` - Application health status

### Users
- `GET /api/v1/users/` - List users with filtering and search
- `POST /api/v1/users/` - Create new user
- `GET /api/v1/users/{id}` - Get user by ID
- `PUT /api/v1/users/{id}` - Update user
- `DELETE /api/v1/users/{id}` - Delete user

### Tasks
- `GET /api/v1/tasks/` - List tasks with filtering
- `POST /api/v1/tasks/` - Create new task
- `GET /api/v1/tasks/{id}` - Get task details
- `PUT /api/v1/tasks/{id}` - Update task status

### Data Points
- `GET /api/v1/data-points/` - List data points
- `POST /api/v1/data-points/` - Create data point
- `GET /api/v1/data-points/{id}` - Get data point

## 🧪 Testing

```bash
# Run all tests
python -m pytest

# Run with coverage
python -m pytest --cov=backend

# Run specific test file
python -m pytest tests/test_db_functions.py

# Run tests with output
python -m pytest -v -s
```

### Testing Database Functions

```python
# Example test
def test_base_repository():
    with get_db_session() as db:
        user_repo = BaseRepository(User, db)
        
        # Test CRUD operations
        user = user_repo.create({"username": "test", "email": "test@example.com"})
        assert user.username == "test"
        
        retrieved = user_repo.get(user.id)
        assert retrieved.email == "test@example.com"
```

## 🚀 Deployment

### Docker Development

```bash
# Build image
docker build -t wipsie-backend .

# Run container
docker run -p 8000:8000 wipsie-backend
```

### Production Deployment

```bash
# Use the orchestration script
./run_dev.sh start

# Or use Docker Compose directly
docker-compose up -d
```

## 🔧 Development Tools

### Code Quality

```bash
# Format code
black backend/
isort backend/

# Type checking
mypy backend/

# Linting
flake8 backend/

# Security scan
safety check
bandit -r backend/
```

### Database Management

```bash
# Create migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head

# Rollback migration
alembic downgrade -1

# Check current version
alembic current
```

### Celery Management

```bash
# Start worker
celery -A backend.workers.celery_app worker --loglevel=info

# Monitor tasks
celery -A backend.workers.celery_app flower

# Purge tasks
celery -A backend.workers.celery_app purge
```

## 📚 Documentation

- **[Database Functions](core/db_functions/README.md)** - Comprehensive database utilities guide
- **[API Documentation](http://localhost:8000/docs)** - Interactive API documentation
- **[Configuration Guide](core/config.py)** - Application configuration reference

## 🤝 Contributing

1. Follow the existing code structure
2. Use the `db_functions` utilities for database operations
3. Add type hints to all functions
4. Write tests for new functionality
5. Update documentation as needed

---

**Backend built with FastAPI, SQLAlchemy, and modern Python practices! 🚀**
