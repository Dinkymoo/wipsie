# Import your API router
from api.endpoints.database import (
    router as database_router,
)
from fastapi import (
    FastAPI,
)
from fastapi.middleware.cors import (
    CORSMiddleware,
)
from mangum import (
    Mangum,
)

# Create FastAPI app
app = FastAPI(
    title="Wipsie Backend API",
    description="Learning management system backend",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(database_router)

# Health check endpoint


@app.get("/health")
async def health_check():
    return {"status": "healthy", "message": "Wipsie Backend API is running"}


@app.get("/")
async def root():
    return {"message": "Welcome to Wipsie Backend API"}

# Lambda handler for AWS Lambda deployment
lambda_handler = Mangum(app)

# For local development
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
