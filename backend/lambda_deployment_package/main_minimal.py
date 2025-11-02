from fastapi import (
    FastAPI,
)

# Create FastAPI app with minimal configuration
app = FastAPI(
    title="Wipsie API Test",
    version="1.0.0"
)


@app.get("/")
async def root():
    return {"message": "Wipsie API is running"}


@app.get("/health")
async def health():
    return {"status": "healthy"}
