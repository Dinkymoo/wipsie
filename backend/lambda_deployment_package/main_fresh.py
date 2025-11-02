from fastapi import (
    FastAPI,
)

from backend.api.endpoints import (
    database,
)

# Create FastAPI app with minimal configuration
app = FastAPI(
    title="Wipsie API",
    version="1.0.0"
)


@app.get("/")
async def root():
    return {"message": "Wipsie API is running"}


@app.get("/health")
async def health():
    return {"status": "healthy"}

# Include the database router
app.include_router(database.router)
