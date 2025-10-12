import os

from fastapi import (
    FastAPI,
)
from fastapi.middleware.cors import (
    CORSMiddleware,
)
from fastapi.responses import (
    JSONResponse,
)

from backend.api.endpoints import (
    database,
    sqs,
)

app = FastAPI(
    title="Wipsie Full Stack API",
    description=(
        "A comprehensive full-stack application with FastAPI, "
        "Angular, PostgreSQL, and AWS Lambda - Learning Environment"
    ),
    version="1.0.0",
)

# Get CORS origins from environment (for different deployment modes)
cors_origins = os.getenv("CORS_ORIGINS", "http://localhost:4200").split(",")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint for ECS


@app.get("/health")
async def health_check():
    """Health check endpoint for load balancers and container orchestration"""
    return JSONResponse(
        status_code=200,
        content={
            "status": "healthy",
            "service": "wipsie-backend",
            "environment": os.getenv("ENVIRONMENT", "development"),
            "version": "1.0.0"
        }
    )


@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Wipsie Learning API",
        "environment": os.getenv("ENVIRONMENT", "development"),
        "docs": "/docs",
        "health": "/health"
    }

# Include routers
app.include_router(database.router)
app.include_router(sqs.router)
