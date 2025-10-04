"""
Common database query utilities and helpers.
"""

import logging
from typing import Any, Dict, Generic, List, Optional, Type, TypeVar

from sqlalchemy import asc, desc, or_
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Query, Session

logger = logging.getLogger(__name__)

# Type variable for model classes
ModelType = TypeVar("ModelType")


class BaseRepository(Generic[ModelType]):
    """
    Base repository class with common CRUD operations.
    """

    def __init__(self, model: Type[ModelType], db: Session):
        self.model = model
        self.db = db

    def get(self, id: int) -> Optional[ModelType]:
        """Get a single record by ID."""
        try:
            return (self.db.query(self.model)
                    .filter(self.model.id == id).first())
        except SQLAlchemyError as e:
            logger.error(
                f"Error getting {self.model.__name__} with id {id}: {e}"
            )
            return None

    def get_all(self, skip: int = 0, limit: int = 100) -> List[ModelType]:
        """Get all records with pagination."""
        try:
            return self.db.query(self.model).offset(skip).limit(limit).all()
        except SQLAlchemyError as e:
            logger.error(f"Error getting all {self.model.__name__}: {e}")
            return []

    def create(self, obj_data: Dict[str, Any]) -> Optional[ModelType]:
        """Create a new record."""
        try:
            db_obj = self.model(**obj_data)
            self.db.add(db_obj)
            self.db.commit()
            self.db.refresh(db_obj)
            return db_obj
        except SQLAlchemyError as e:
            logger.error(f"Error creating {self.model.__name__}: {e}")
            self.db.rollback()
            return None

    def update(self, id: int, obj_data: Dict[str, Any]) -> Optional[ModelType]:
        """Update an existing record."""
        try:
            db_obj = self.get(id)
            if db_obj:
                for field, value in obj_data.items():
                    setattr(db_obj, field, value)
                self.db.commit()
                self.db.refresh(db_obj)
                return db_obj
            return None
        except SQLAlchemyError as e:
            logger.error(
                f"Error updating {self.model.__name__} with id {id}: {e}"
            )
            self.db.rollback()
            return None

    def delete(self, id: int) -> bool:
        """Delete a record by ID."""
        try:
            db_obj = self.get(id)
            if db_obj:
                self.db.delete(db_obj)
                self.db.commit()
                return True
            return False
        except SQLAlchemyError as e:
            logger.error(
                f"Error deleting {self.model.__name__} with id {id}: {e}"
            )
            self.db.rollback()
            return False

    def count(self) -> int:
        """Count total records."""
        try:
            return self.db.query(self.model).count()
        except SQLAlchemyError as e:
            logger.error(f"Error counting {self.model.__name__}: {e}")
            return 0


def filter_by_fields(query: Query, model: Type[ModelType],
                     filters: Dict[str, Any]) -> Query:
    """
    Apply filters to a query based on field values.

    Args:
        query: SQLAlchemy query object
        model: Model class
        filters: Dictionary of field names and values to filter by

    Returns:
        Filtered query object
    """
    for field, value in filters.items():
        if hasattr(model, field) and value is not None:
            query = query.filter(getattr(model, field) == value)
    return query


def search_by_text(query: Query, model: Type[ModelType],
                   search_fields: List[str], search_term: str) -> Query:
    """
    Add text search conditions to a query.

    Args:
        query: SQLAlchemy query object
        model: Model class
        search_fields: List of field names to search in
        search_term: Text to search for

    Returns:
        Query with search conditions applied
    """
    if not search_term:
        return query

    search_conditions = []
    for field in search_fields:
        if hasattr(model, field):
            field_attr = getattr(model, field)
            search_conditions.append(field_attr.ilike(f"%{search_term}%"))

    if search_conditions:
        query = query.filter(or_(*search_conditions))

    return query


def order_by_field(query: Query, model: Type[ModelType],
                   order_by: str, desc_order: bool = False) -> Query:
    """
    Add ordering to a query.

    Args:
        query: SQLAlchemy query object
        model: Model class
        order_by: Field name to order by
        desc_order: Whether to use descending order

    Returns:
        Ordered query object
    """
    if hasattr(model, order_by):
        field_attr = getattr(model, order_by)
        if desc_order:
            query = query.order_by(desc(field_attr))
        else:
            query = query.order_by(asc(field_attr))

    return query
