# Wipsie Technical Specification

## API Documentation

### FastAPI Endpoints

#### SQS Management Endpoints

**List Available Queues**
```http
GET /sqs/queues
Accept: application/json
```

Response:
```json
{
  "available_queues": ["default", "data_polling", "task_processing", "notifications"],
  "region": "us-east-1"
}
```

**Send Message to Queue**
```http
POST /sqs/send
Content-Type: application/json
```

Request Body:
```json
{
  "queue_name": "default",
  "message": {
    "task_type": "user_action",
    "message": "Process user data",
    "priority": "high",
    "data": {
      "user_id": "12345",
      "action": "profile_update"
    }
  },
  "attributes": {
    "priority": "high",
    "source": "web_app"
  }
}
```

Response:
```json
{
  "message_id": "abc123-def456-ghi789",
  "queue": "default",
  "status": "sent",
  "timestamp": "2025-10-04T14:06:02.648981"
}
```

**Receive Messages from Queue**
```http
GET /sqs/receive/{queue_name}?max_messages=5
Accept: application/json
```

Response:
```json
{
  "queue": "default",
  "message_count": 2,
  "messages": [
    {
      "message_id": "abc123-def456-ghi789",
      "body": {
        "task_type": "user_action",
        "message": "Process user data",
        "timestamp": "2025-10-04T14:06:02.648981"
      },
      "attributes": {
        "priority": {"StringValue": "high", "DataType": "String"}
      },
      "receipt_handle": "receipt-handle-for-deletion"
    }
  ]
}
```

**Delete Processed Message**
```http
DELETE /sqs/message/{queue_name}?receipt_handle={receipt_handle}
```

Response:
```json
{
  "status": "deleted",
  "queue": "default"
}
```

**Send Test Message**
```http
POST /sqs/test-message
Accept: application/json
```

Response:
```json
{
  "status": "success",
  "test_message": {
    "type": "test",
    "message": "Hello from FastAPI!",
    "source": "api_test",
    "data": {
      "test_id": "api-test-001",
      "description": "Testing SQS integration via FastAPI"
    }
  },
  "result": {
    "message_id": "test-message-id",
    "queue": "default",
    "status": "sent"
  }
}
```

## Message Schemas

### Standard Message Format

```typescript
interface StandardMessage {
  id: string;                    // UUID4 generated
  timestamp: string;             // ISO 8601 format
  source: 'api' | 'lambda' | 'manual' | 'scheduler';
  task_type: string;             // Task category
  message: string;               // Human-readable description
  queue: string;                 // Target queue name
  data: {                        // Task-specific payload
    [key: string]: any;
  };
  priority?: 'low' | 'medium' | 'high';
  retry_count?: number;          // For error handling
  correlation_id?: string;       // For request tracing
}
```

### Task-Specific Schemas

**Data Polling Task**
```typescript
interface DataPollingMessage extends StandardMessage {
  task_type: 'data_polling';
  data: {
    source_url: string;
    poll_interval: number;       // seconds
    last_poll_time?: string;
    filters?: {
      [key: string]: any;
    };
  };
}
```

**Background Processing Task**
```typescript
interface ProcessingMessage extends StandardMessage {
  task_type: 'processing';
  data: {
    operation: 'analysis' | 'transformation' | 'aggregation';
    input_data: any;
    output_format: string;
    processing_options: {
      [key: string]: any;
    };
  };
}
```

**Notification Task**
```typescript
interface NotificationMessage extends StandardMessage {
  task_type: 'notification';
  data: {
    recipient: string;
    notification_type: 'email' | 'sms' | 'push' | 'webhook';
    subject?: string;
    body: string;
    template_id?: string;
    metadata: {
      [key: string]: any;
    };
  };
}
```

## Configuration Management

### Environment Variables

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# SQS Configuration
SQS_QUEUE_PREFIX=wipsie-
SQS_ACCOUNT_ID=554510949034

# Database Configuration
DATABASE_URL=postgresql://user:pass@localhost/wipsie
DATABASE_POOL_SIZE=10
DATABASE_MAX_OVERFLOW=20

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_RELOAD=true
CORS_ORIGINS=["http://localhost:4200"]

# Celery Configuration
CELERY_BROKER_URL=sqs://
CELERY_RESULT_BACKEND=rpc://
CELERY_TASK_SERIALIZER=json
CELERY_ACCEPT_CONTENT=["json"]

# Logging Configuration
LOG_LEVEL=INFO
LOG_FORMAT=json
LOG_FILE=/var/log/wipsie/app.log

# Security Configuration
SECRET_KEY=your-secret-key-here
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
```

### Settings Class Structure

```python
# backend/core/config.py
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # AWS Settings
    AWS_REGION: str = "us-east-1"
    AWS_ACCESS_KEY_ID: str
    AWS_SECRET_ACCESS_KEY: str
    
    # SQS Settings
    SQS_QUEUE_PREFIX: str = "wipsie-"
    SQS_ACCOUNT_ID: str = "554510949034"
    
    # Database Settings
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 20
    
    # API Settings
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000
    API_RELOAD: bool = False
    CORS_ORIGINS: List[str] = ["http://localhost:4200"]
    
    @property
    def CELERY_BROKER_URL(self) -> str:
        return f"sqs://{self.AWS_ACCESS_KEY_ID}:{self.AWS_SECRET_ACCESS_KEY}@"
    
    @property
    def SQS_QUEUE_URLS(self) -> dict:
        base_url = f"https://sqs.{self.AWS_REGION}.amazonaws.com/{self.SQS_ACCOUNT_ID}"
        return {
            'default': f"{base_url}/{self.SQS_QUEUE_PREFIX}default",
            'data_polling': f"{base_url}/{self.SQS_QUEUE_PREFIX}data-polling",
            'task_processing': f"{base_url}/{self.SQS_QUEUE_PREFIX}task-processing",
            'notifications': f"{base_url}/{self.SQS_QUEUE_PREFIX}notifications"
        }
    
    class Config:
        env_file = ".env"
        case_sensitive = True
```

## Error Handling Patterns

### API Error Responses

```python
# Standard error response format
{
  "error": {
    "code": "QUEUE_NOT_FOUND",
    "message": "The specified queue does not exist",
    "details": {
      "queue_name": "invalid-queue",
      "available_queues": ["default", "data_polling", "task_processing", "notifications"]
    },
    "timestamp": "2025-10-04T14:06:02.648981",
    "request_id": "req-abc123-def456"
  }
}
```

### Celery Task Error Handling

```python
from celery.exceptions import Retry

@app.task(bind=True, autoretry_for=(Exception,), retry_kwargs={'max_retries': 3})
def process_task(self, task_data):
    try:
        # Task processing logic
        result = perform_task(task_data)
        return result
    except TemporaryError as e:
        # Retry with exponential backoff
        raise self.retry(countdown=60 * (2 ** self.request.retries), exc=e)
    except PermanentError as e:
        # Don't retry, log and fail
        logger.error(f"Permanent task failure: {e}")
        raise e
```

## Testing Strategies

### Unit Testing

```python
# tests/test_sqs_service.py
import pytest
from unittest.mock import Mock, patch
from backend.services.sqs_service import SQSService

class TestSQSService:
    @pytest.fixture
    def sqs_service(self):
        return SQSService()
    
    @patch('boto3.client')
    def test_send_message_success(self, mock_boto3, sqs_service):
        # Mock SQS client
        mock_sqs = Mock()
        mock_boto3.return_value = mock_sqs
        mock_sqs.send_message.return_value = {
            'MessageId': 'test-message-id'
        }
        
        # Test message sending
        result = sqs_service.send_message(
            'default',
            {'test': 'message'}
        )
        
        assert result['message_id'] == 'test-message-id'
        assert result['status'] == 'sent'
```

### Integration Testing

```python
# tests/test_api_integration.py
import pytest
from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)

def test_send_message_endpoint():
    response = client.post("/sqs/send", json={
        "queue_name": "default",
        "message": {"test": "data"}
    })
    
    assert response.status_code == 200
    data = response.json()
    assert 'message_id' in data
    assert data['status'] == 'sent'

def test_list_queues_endpoint():
    response = client.get("/sqs/queues")
    
    assert response.status_code == 200
    data = response.json()
    assert 'available_queues' in data
    assert len(data['available_queues']) == 4
```

### Load Testing

```python
# tests/load_test.py
import asyncio
import aiohttp
import time

async def send_message(session, message_id):
    async with session.post(
        'http://localhost:8000/sqs/send',
        json={
            "queue_name": "default",
            "message": {"test_id": message_id}
        }
    ) as response:
        return await response.json()

async def load_test(concurrent_requests=100):
    async with aiohttp.ClientSession() as session:
        start_time = time.time()
        
        tasks = [
            send_message(session, i) 
            for i in range(concurrent_requests)
        ]
        
        results = await asyncio.gather(*tasks)
        
        end_time = time.time()
        duration = end_time - start_time
        
        print(f"Sent {len(results)} messages in {duration:.2f} seconds")
        print(f"Rate: {len(results)/duration:.2f} messages/second")

if __name__ == "__main__":
    asyncio.run(load_test())
```

## Deployment Configurations

### Docker Compose (Development)

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/wipsie
      - AWS_REGION=us-east-1
    depends_on:
      - db
    volumes:
      - .:/app
    command: uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload

  worker:
    build: .
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/wipsie
      - AWS_REGION=us-east-1
    depends_on:
      - db
    volumes:
      - .:/app
    command: celery -A celery_worker worker --loglevel=info

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=wipsie
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Kubernetes Deployment

```yaml
# k8s/api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wipsie-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: wipsie-api
  template:
    metadata:
      labels:
        app: wipsie-api
    spec:
      containers:
      - name: api
        image: wipsie/api:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: wipsie-secrets
              key: database-url
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: access-key-id
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

## Performance Benchmarks

### Expected Performance Metrics

- **API Response Time**: < 100ms for P95
- **Message Throughput**: 1000+ messages/second
- **Worker Processing**: 50+ tasks/second per worker
- **Database Queries**: < 50ms for P95
- **Queue Latency**: < 5 seconds end-to-end

### Monitoring Setup

```python
# monitoring/metrics.py
from prometheus_client import Counter, Histogram, Gauge
import time

# Metrics definitions
REQUEST_COUNT = Counter('api_requests_total', 'Total API requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('api_request_duration_seconds', 'Request duration')
QUEUE_SIZE = Gauge('sqs_queue_size', 'Current queue size', ['queue_name'])
TASK_DURATION = Histogram('task_processing_duration_seconds', 'Task processing time')

# Usage in FastAPI
@app.middleware("http")
async def metrics_middleware(request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path
    ).inc()
    
    REQUEST_DURATION.observe(time.time() - start_time)
    
    return response
```

This technical specification provides comprehensive documentation for developers working with the Wipsie architecture, covering API contracts, message schemas, configuration patterns, testing strategies, and deployment configurations.
