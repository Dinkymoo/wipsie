from typing import (
    List,
)

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)
from sqlalchemy.orm import (
    Session,
)

from db.database import (
    get_db,
)
from schemas.schemas import (
    DataPoint,
    DataPointCreate,
)
from services.data_point_service import (
    DataPointService,
)

router = APIRouter()


@router.post(
    "/", response_model=DataPoint, status_code=status.HTTP_201_CREATED
)
async def create_data_point(
    data_point: DataPointCreate, db: Session = Depends(get_db)
):
    """Create a new data point."""
    try:
        return DataPointService.create_data_point(db, data_point)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error creating data point: {str(e)}",
        )


@router.get("/", response_model=List[DataPoint])
async def get_data_points(
    skip: int = 0, limit: int = 100, db: Session = Depends(get_db)
):
    """Retrieve all data points with pagination."""
    try:
        return DataPointService.get_data_points(db, skip=skip, limit=limit)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving data points: {str(e)}",
        )


@router.get("/{data_point_id}", response_model=DataPoint)
async def get_data_point(data_point_id: int, db: Session = Depends(get_db)):
    """Retrieve a specific data point by ID."""
    try:
        data_point = DataPointService.get_data_point(db, data_point_id)
        if not data_point:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Data point not found",
            )
        return data_point
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving data point: {str(e)}",
        )


@router.delete("/{data_point_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_data_point(data_point_id: int, db: Session = Depends(get_db)):
    """Delete a data point."""
    try:
        success = DataPointService.delete_data_point(db, data_point_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Data point not found",
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting data point: {str(e)}",
        )


@router.get("/source/{source}", response_model=List[DataPoint])
async def get_data_points_by_source(
    source: str, db: Session = Depends(get_db)
):
    """Retrieve all data points for a specific source."""
    try:
        return DataPointService.get_data_points_by_source(db, source)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving data points by source: {str(e)}",
        )
