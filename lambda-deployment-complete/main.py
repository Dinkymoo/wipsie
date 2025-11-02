import json
import os

# Global variable to store any import errors
IMPORT_ERROR = None

try:
    from fastapi import FastAPI
    from fastapi.middleware.cors import CORSMiddleware
    from mangum import Mangum
    
    # Create FastAPI app
    app = FastAPI(
        title="Wipsie Backend API",
        description="Learning management system backend",
        version="1.0.0"
    )
    
    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    @app.get("/health")
    async def health_check():
        return {
            "status": "healthy", 
            "message": "Wipsie Backend API is running with FastAPI",
            "environment": "lambda",
            "database_configured": bool(os.getenv("DATABASE_URL"))
        }
    
    @app.get("/")
    async def root():
        return {"message": "Welcome to Wipsie Backend API", "status": "working"}
    
    @app.get("/data-points")
    async def get_data_points():
        return {
            "message": "Data points endpoint", 
            "data": [],
            "note": "FastAPI functionality working"
        }
    
    # Lambda handler with FastAPI
    lambda_handler = Mangum(app)
    
except Exception as import_error:
    # Store the error for use in fallback handler
    IMPORT_ERROR = import_error
    
    # Fallback handler if FastAPI imports fail
    def lambda_handler(event, context):
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': f'FastAPI setup error: {str(IMPORT_ERROR)}',
                'message': 'Lambda running but FastAPI failed to initialize',
                'fallback': True,
                'event_received': True
            })
        }
