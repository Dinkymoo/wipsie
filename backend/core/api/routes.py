from fastapi import (
    APIRouter,
)

from api.endpoints import (
    data_points,
    lambda_functions,
    tasks,
    users,
)

api_router = APIRouter()

api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
api_router.include_router(
    data_points.router, prefix="/data-points", tags=["data-points"]
)
api_router.include_router(
    lambda_functions.router, prefix="/lambda", tags=["lambda-functions"]
)
