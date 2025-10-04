import json

from fastapi import (
    APIRouter,
    HTTPException,
)

from backend.schemas.schemas import (
    MessageResponse,
)
from backend.services.lambda_service import (
    LambdaService,
)

router = APIRouter()


@router.post("/invoke/{function_name}", response_model=MessageResponse)
async def invoke_lambda_function(function_name: str, payload: dict = None):
    """Invoke an AWS Lambda function"""
    try:
        response = await LambdaService.invoke_function(
            function_name, payload or {}
        )
        return MessageResponse(
            message=f"Lambda function {function_name} invoked successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/functions", response_model=list)
async def list_lambda_functions():
    """List all available Lambda functions"""
    try:
        functions = await LambdaService.list_functions()
        return functions
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/deploy/{function_name}", response_model=MessageResponse)
async def deploy_lambda_function(function_name: str):
    """Deploy a Lambda function"""
    try:
        result = await LambdaService.deploy_function(function_name)
        return MessageResponse(
            message=f"Lambda function {function_name} deployed successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
