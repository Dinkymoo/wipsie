from typing import List, Optional

from sqlalchemy.orm import Session

from backend.models.models import DataPoint
from backend.schemas.schemas import DataPointCreate


class DataPointService:
    @staticmethod
    def get_data_points(
        db: Session, skip: int = 0, limit: int = 100
    ) -> List[DataPoint]:
        """Get all data points with pagination"""
        return db.query(DataPoint).offset(skip).limit(limit).all()

    @staticmethod
    def get_data_point(db: Session, data_point_id: int) -> Optional[DataPoint]:
        """Get a specific data point by ID"""
        return (
            db.query(DataPoint).filter(DataPoint.id == data_point_id).first()
        )

    @staticmethod
    def create_data_point(
        db: Session, data_point: DataPointCreate
    ) -> DataPoint:
        """Create a new data point"""
        db_data_point = DataPoint(**data_point.dict())
        db.add(db_data_point)
        db.commit()
        db.refresh(db_data_point)
        return db_data_point

    @staticmethod
    def get_data_points_by_source(db: Session, source: str) -> List[DataPoint]:
        """Get data points filtered by source"""
        return db.query(DataPoint).filter(DataPoint.source == source).all()

    @staticmethod
    def delete_data_point(db: Session, data_point_id: int) -> bool:
        """Delete a data point"""
        db_data_point = (
            db.query(DataPoint).filter(DataPoint.id == data_point_id).first()
        )
        if not db_data_point:
            return False

        db.delete(db_data_point)
        db.commit()
        return True
