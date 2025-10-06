# Wipsie Developer Onboarding Guide

## Quick Start

### Prerequisites
- Python 3.11+ installed
- Node.js 18+ (for Angular frontend)
- AWS Account with SQS access
- PostgreSQL (local or Docker)
- Git configured

### 1-Minute Setup

```bash
# Clone and enter project
git clone <repository-url>
cd wipsie

# Set up Python environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your AWS credentials

# Test the setup
python simple_sqs_test.py
```

## Project Structure

```
wipsie/
├── backend/                 # FastAPI application
│   ├── api/                # API endpoints
│   │   └── endpoints/      # Route handlers
│   ├── core/               # Core configuration
│   │   ├── config.py       # Settings management
│   │   └── celery_app.py   # Celery configuration
│   ├── services/           # Business logic
│   │   └── sqs_service.py  # SQS abstraction
│   ├── models/             # Database models
│   ├── schemas/            # Pydantic schemas
│   └── main.py             # FastAPI app entry point
├── frontend/               # Angular application
│   └── wipsie-app/         # Angular project
├── aws-lambda/             # Lambda functions
│   └── functions/          # Individual Lambda handlers
├── docs/                   # Documentation
├── scripts/                # Utility scripts
├── tests/                  # Test suite
└── alembic/                # Database migrations
```

## Development Workflow

### Daily Development

1. **Start the API server**:
   ```bash
   python -m uvicorn backend.main:app --reload --port 8000
   ```

2. **Start the Celery worker** (optional):
   ```bash
   celery -A celery_worker worker --loglevel=info
   ```

3. **Test SQS integration**:
   ```bash
   # Send a test message
   python simple_sqs_test.py
   
   # Process messages manually
   python process_messages.py
   ```

4. **Check API endpoints**:
   ```bash
   curl http://localhost:8000/sqs/queues
   curl -X POST http://localhost:8000/sqs/test-message
   ```

### Code Style and Standards

#### Python Code Style
- **Formatter**: Black with 79-character line limit
- **Linter**: flake8 for code quality
- **Type Hints**: Required for all functions
- **Docstrings**: Google style for all public functions

```python
def send_message_to_queue(
    queue_name: str, 
    message_data: Dict[str, Any],
    priority: str = "medium"
) -> Dict[str, str]:
    """Send a message to the specified SQS queue.
    
    Args:
        queue_name: Name of the target queue
        message_data: Message payload as dictionary
        priority: Message priority level (low, medium, high)
        
    Returns:
        Dictionary containing message_id and status
        
    Raises:
        ValueError: If queue_name is invalid
        AWSError: If SQS operation fails
    """
```

#### Import Organization
```python
# Standard library imports
import json
import logging
from datetime import datetime
from typing import Dict, List, Optional

# Third-party imports
import boto3
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Local imports
from backend.core.config import settings
from backend.services.sqs_service import sqs_service
```

### Testing Guidelines

#### Test Structure
```bash
tests/
├── unit/                   # Unit tests
│   ├── test_sqs_service.py
│   └── test_api_endpoints.py
├── integration/            # Integration tests
│   ├── test_full_workflow.py
│   └── test_aws_integration.py
├── load/                   # Load testing
│   └── test_performance.py
└── conftest.py             # Pytest configuration
```

#### Writing Tests
```python
# tests/unit/test_sqs_service.py
import pytest
from unittest.mock import Mock, patch
from backend.services.sqs_service import SQSService

class TestSQSService:
    @pytest.fixture
    def sqs_service(self):
        return SQSService()
    
    def test_send_message_success(self, sqs_service):
        with patch('boto3.client') as mock_boto3:
            mock_sqs = Mock()
            mock_boto3.return_value = mock_sqs
            mock_sqs.send_message.return_value = {'MessageId': 'test-id'}
            
            result = sqs_service.send_message('default', {'test': 'data'})
            
            assert result['message_id'] == 'test-id'
            assert result['status'] == 'sent'
```

#### Running Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=backend --cov-report=html

# Run specific test file
pytest tests/unit/test_sqs_service.py

# Run tests with verbose output
pytest -v
```

## Common Development Tasks

### Adding a New API Endpoint

1. **Create the endpoint**:
   ```python
   # backend/api/endpoints/new_feature.py
   from fastapi import APIRouter
   
   router = APIRouter(prefix="/new-feature", tags=["New Feature"])
   
   @router.get("/")
   async def get_feature():
       return {"message": "New feature endpoint"}
   ```

2. **Add to main app**:
   ```python
   # backend/main.py
   from backend.api.endpoints import new_feature
   
   app.include_router(new_feature.router)
   ```

3. **Write tests**:
   ```python
   # tests/unit/test_new_feature.py
   def test_new_feature_endpoint():
       response = client.get("/new-feature/")
       assert response.status_code == 200
   ```

### Adding a New Celery Task

1. **Define the task**:
   ```python
   # celery_worker.py
   @app.task(bind=True)
   def new_processing_task(self, task_data):
       logger.info(f"Processing new task: {self.request.id}")
       try:
           # Task logic here
           result = process_data(task_data)
           return result
       except Exception as e:
           logger.error(f"Task failed: {e}")
           raise self.retry(countdown=60, max_retries=3)
   ```

2. **Add to task routing**:
   ```python
   # celery_worker.py in app.conf.update
   task_routes={
       'worker.new_processing_task': {'queue': 'wipsie-task-processing'},
   }
   ```

3. **Test the task**:
   ```python
   # tests/unit/test_celery_tasks.py
   def test_new_processing_task():
       result = new_processing_task.delay({'test': 'data'})
       assert result.status == 'SUCCESS'
   ```

### Adding a New Queue

1. **Create the queue** (via AWS Console or script):
   ```python
   # scripts/create_queue.py
   import boto3
   
   sqs = boto3.client('sqs', region_name='us-east-1')
   queue_url = sqs.create_queue(
       QueueName='wipsie-new-queue',
       Attributes={
           'VisibilityTimeoutSeconds': '300',
           'MessageRetentionPeriod': '1209600'  # 14 days
       }
   )
   ```

2. **Update configuration**:
   ```python
   # backend/services/sqs_service.py
   self.queue_urls = {
       # existing queues...
       'new_queue': f"{base_url}/wipsie-new-queue"
   }
   ```

3. **Add worker routing**:
   ```python
   # celery_worker.py
   'worker.new_queue_task': {'queue': 'wipsie-new-queue'}
   ```

## Debugging and Troubleshooting

### Common Issues

#### 1. AWS Credentials Not Found
```bash
Error: Unable to locate credentials
```
**Solution**: Check `.env` file has correct AWS credentials:
```bash
AWS_ACCESS_KEY_ID=your-key-here
AWS_SECRET_ACCESS_KEY=your-secret-here
AWS_REGION=us-east-1
```

#### 2. Celery Worker Won't Start
```bash
Error: kombu.exceptions.OperationalError
```
**Solution**: Test Celery configuration:
```bash
python test_celery.py
```

#### 3. SQS Permission Denied
```bash
Error: An error occurred (AccessDenied)
```
**Solution**: Verify IAM permissions and queue URLs in AWS Console.

#### 4. FastAPI Import Errors
```bash
ModuleNotFoundError: No module named 'backend'
```
**Solution**: Ensure you're in the project root and Python path is correct:
```bash
export PYTHONPATH="${PYTHONPATH}:/workspaces/wipsie"
```

### Debugging Tools

#### API Debugging
```bash
# Test API with curl
curl -v http://localhost:8000/health

# Test with httpie (more readable)
http GET localhost:8000/sqs/queues

# View FastAPI docs
open http://localhost:8000/docs
```

#### SQS Debugging
```bash
# Check queue status
python -c "
from backend.services.sqs_service import sqs_service
print(sqs_service.queue_urls)
"

# Send test message
python simple_sqs_test.py

# Check messages manually
python process_messages.py
```

#### Celery Debugging
```bash
# Check Celery status
celery -A celery_worker inspect stats

# List active tasks
celery -A celery_worker inspect active

# Monitor tasks in real-time
celery -A celery_worker events
```

### Logging and Monitoring

#### Enable Debug Logging
```python
# backend/main.py
import logging
logging.basicConfig(level=logging.DEBUG)
```

#### Monitor Queue Metrics
```python
# scripts/monitor_queues.py
import boto3

def get_queue_metrics():
    sqs = boto3.client('sqs', region_name='us-east-1')
    queues = [
        'wipsie-default',
        'wipsie-data-polling', 
        'wipsie-task-processing',
        'wipsie-notifications'
    ]
    
    for queue_name in queues:
        queue_url = f"https://sqs.us-east-1.amazonaws.com/554510949034/{queue_name}"
        attrs = sqs.get_queue_attributes(
            QueueUrl=queue_url,
            AttributeNames=['ApproximateNumberOfMessages']
        )
        count = attrs['Attributes']['ApproximateNumberOfMessages']
        print(f"{queue_name}: {count} messages")

if __name__ == "__main__":
    get_queue_metrics()
```

## Git Workflow

### Branch Strategy
- `main` - Production-ready code
- `develop` - Integration branch
- `feature/*` - Feature development
- `bugfix/*` - Bug fixes
- `hotfix/*` - Emergency fixes

### Commit Message Format
```
type(scope): short description

Detailed explanation of the change, including:
- What was changed
- Why it was changed
- Any breaking changes

Closes #123
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Pull Request Process
1. Create feature branch from `develop`
2. Make changes with tests
3. Run full test suite
4. Create PR with description
5. Code review and approval
6. Merge to `develop`

## Resources and References

### Documentation
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Celery Documentation](https://docs.celeryproject.org/)
- [AWS SQS Documentation](https://docs.aws.amazon.com/sqs/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)

### Useful Commands
```bash
# Format code
black backend/ --line-length 79

# Lint code
flake8 backend/

# Type checking
mypy backend/

# Security scan
bandit -r backend/

# Update dependencies
pip-compile requirements.in
pip-sync requirements.txt

# Database migrations
alembic revision --autogenerate -m "Description"
alembic upgrade head

# Export current environment
pip freeze > requirements.txt
```

### VS Code Extensions
- Python
- Python Docstring Generator
- GitLens
- REST Client
- AWS Toolkit
- Thunder Client (API testing)

This onboarding guide should get new developers up and running quickly with the Wipsie architecture!
