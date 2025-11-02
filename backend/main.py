from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import datetime

app = FastAPI(
    title="Wipsie Full Stack API",
    description="A comprehensive full-stack application with FastAPI, Angular, PostgreSQL, and AWS Lambda integration",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4200"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models for API documentation
class DataPoint(BaseModel):
    id: Optional[int] = None
    value: float
    timestamp: datetime.datetime
    source: str
    metadata: Optional[dict] = None

class LambdaFunction(BaseModel):
    name: str
    status: str
    last_execution: Optional[datetime.datetime] = None
    execution_count: int = 0

class TaskRequest(BaseModel):
    task_type: str
    data: dict
    priority: int = 1

@app.get("/")
async def root():
    """Welcome endpoint with API information"""
    return {
        "message": "Welcome to Wipsie Full Stack API! 🚀",
        "version": "1.0.0",
        "description": "FastAPI backend with AWS Lambda integration",
        "endpoints": {
            "docs": "/docs",
            "health": "/health",
            "data": "/data-points",
            "lambda": "/lambda/functions",
            "tasks": "/tasks"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy", 
        "message": "API is running smoothly!",
        "timestamp": datetime.datetime.now(),
        "services": {
            "api": "operational",
            "database": "connected",
            "lambda": "available"
        }
    }

@app.get("/data-points", response_model=List[DataPoint])
async def get_data_points():
    """Get sample data points"""
    return [
        DataPoint(
            id=1,
            value=23.5,
            timestamp=datetime.datetime.now(),
            source="sensor_1",
            metadata={"location": "office"}
        ),
        DataPoint(
            id=2,
            value=18.2,
            timestamp=datetime.datetime.now(),
            source="sensor_2",
            metadata={"location": "warehouse"}
        )
    ]

@app.post("/data-points", response_model=DataPoint)
async def create_data_point(data_point: DataPoint):
    """Create a new data point"""
    data_point.id = 123  # Simulate database ID assignment
    data_point.timestamp = datetime.datetime.now()
    return data_point

@app.get("/lambda/functions", response_model=List[LambdaFunction])
async def get_lambda_functions():
    """Get AWS Lambda function status"""
    return [
        LambdaFunction(
            name="data_poller",
            status="active",
            last_execution=datetime.datetime.now(),
            execution_count=42
        ),
        LambdaFunction(
            name="task_processor",
            status="active",
            last_execution=datetime.datetime.now(),
            execution_count=128
        )
    ]

@app.post("/lambda/invoke/{function_name}")
async def invoke_lambda_function(function_name: str, payload: Optional[dict] = None):
    """Invoke a Lambda function"""
    return {
        "function_name": function_name,
        "status": "invoked",
        "execution_id": f"exec_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}",
        "payload": payload or {},
        "timestamp": datetime.datetime.now()
    }

@app.post("/tasks", response_model=dict)
async def create_task(task: TaskRequest):
    """Create a new background task"""
    return {
        "task_id": f"task_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}",
        "status": "queued",
        "task_type": task.task_type,
        "priority": task.priority,
        "created_at": datetime.datetime.now()
    }

@app.get("/tasks/{task_id}")
async def get_task_status(task_id: str):
    """Get task execution status"""
    return {
        "task_id": task_id,
        "status": "completed",
        "progress": 100,
        "result": {"message": "Task completed successfully"},
        "completed_at": datetime.datetime.now()
    }
