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

from api.endpoints import (
    database,
)

app = FastAPI(
    title="Wipsie Full Stack API",
    description="A comprehensive full-stack application",
    version="1.0.0",
)

# Simple CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "wipsie-backend"}


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Wipsie Learning API",
        "docs": "/docs",
        "health": "/health"
    }

# Include database router only
app.include_router(database.router)
