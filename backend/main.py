from fastapi import (
    FastAPI,
)
from fastapi.middleware.cors import (
    CORSMiddleware,
)

from backend.api.endpoints import (
    sqs,
)

app = FastAPI(
    title="Wipsie Full Stack API",
    description=(
        "A comprehensive full-stack application with FastAPI, "
        "Angular, PostgreSQL, and AWS Lambda"
    ),
    version="1.0.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4200"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(sqs.router)


@app.get("/")
async def root():
    return {"message": "Welcome to Wipsie Full Stack API! 🚀"}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "message": "API is running smoothly!"}
