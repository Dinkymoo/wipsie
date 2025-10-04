from fastapi import (
    APIRouter,
)

router = APIRouter(prefix="/sqs", tags=["sqs"])


@router.get("/status")
async def sqs_status():
    return {"status": "SQS service ready"}
