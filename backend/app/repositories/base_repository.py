"""
FuelIQ — Base Repository
Generic async repository with common CRUD operations and audit logging.
"""
import uuid
from datetime import datetime, UTC
from typing import Generic, TypeVar, Type, Any, Sequence

import structlog
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import Base
from app.models.models import AuditLog, AuditAction

logger = structlog.get_logger(__name__)

ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    """
    Generic repository providing standard CRUD operations.
    All mutations are logged to audit_logs.
    """

    def __init__(self, model: Type[ModelType], session: AsyncSession):
        self._model = model
        self._session = session

    async def get_by_id(self, id: uuid.UUID) -> ModelType | None:
        """Fetch a single record by primary key. Respects soft deletes."""
        stmt = select(self._model).where(
            and_(
                self._model.id == id,
                self._model.deleted_at.is_(None),
            )
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_all(
        self,
        *,
        offset: int = 0,
        limit: int = 20,
        **filters: Any,
    ) -> tuple[Sequence[ModelType], int]:
        """
        Paginated fetch with filters.
        Returns (items, total_count).
        """
        conditions = [self._model.deleted_at.is_(None)]
        for key, value in filters.items():
            if hasattr(self._model, key) and value is not None:
                conditions.append(getattr(self._model, key) == value)

        # Count query
        count_stmt = select(func.count()).select_from(self._model).where(and_(*conditions))
        count_result = await self._session.execute(count_stmt)
        total = count_result.scalar() or 0

        # Data query
        stmt = (
            select(self._model)
            .where(and_(*conditions))
            .offset(offset)
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        items = result.scalars().all()

        return items, total

    async def create(
        self,
        data: dict[str, Any],
        *,
        user_id: uuid.UUID | None = None,
        ip_address: str | None = None,
    ) -> ModelType:
        """Create a new record and log the audit event."""
        instance = self._model(**data)
        self._session.add(instance)
        await self._session.flush()  # Get the ID before commit

        # Audit
        await self._audit(
            action=AuditAction.INSERT,
            entity_id=getattr(instance, "id", None),
            new_values=data,
            user_id=user_id,
            ip_address=ip_address,
        )

        logger.info(
            "repository_create",
            model=self._model.__tablename__,
            id=str(getattr(instance, "id", None)),
        )
        return instance

    async def update(
        self,
        instance: ModelType,
        data: dict[str, Any],
        *,
        user_id: uuid.UUID | None = None,
        ip_address: str | None = None,
    ) -> ModelType:
        """Update a record and log the audit event."""
        old_values = {k: getattr(instance, k) for k in data.keys() if hasattr(instance, k)}

        for key, value in data.items():
            if hasattr(instance, key):
                setattr(instance, key, value)

        await self._session.flush()

        await self._audit(
            action=AuditAction.UPDATE,
            entity_id=getattr(instance, "id", None),
            old_values=old_values,
            new_values=data,
            user_id=user_id,
            ip_address=ip_address,
        )

        return instance

    async def soft_delete(
        self,
        instance: ModelType,
        *,
        user_id: uuid.UUID | None = None,
        ip_address: str | None = None,
    ) -> None:
        """Soft delete: set deleted_at timestamp."""
        if not hasattr(instance, "deleted_at"):
            raise ValueError(f"{self._model.__name__} does not support soft delete")

        instance.deleted_at = datetime.now(UTC)
        await self._session.flush()

        await self._audit(
            action=AuditAction.DELETE,
            entity_id=getattr(instance, "id", None),
            user_id=user_id,
            ip_address=ip_address,
        )

    async def _audit(
        self,
        action: AuditAction,
        entity_id: uuid.UUID | None,
        *,
        old_values: dict | None = None,
        new_values: dict | None = None,
        user_id: uuid.UUID | None = None,
        ip_address: str | None = None,
    ) -> None:
        """Write to audit_logs table."""

        def _serialize_val(obj):
            if isinstance(obj, datetime):
                return obj.isoformat()
            if isinstance(obj, uuid.UUID):
                return str(obj)
            from decimal import Decimal
            if isinstance(obj, Decimal):
                return float(obj)
            return obj

        def _serialize(d: dict | None) -> dict | None:
            if d is None:
                return None
            return {
                k: _serialize_val(v)
                for k, v in d.items()
            }

        log = AuditLog(
            user_id=user_id,
            action=action,
            entity_type=self._model.__tablename__,
            entity_id=entity_id,
            old_values=_serialize(old_values),
            new_values=_serialize(new_values),
            ip_address=ip_address,
        )
        self._session.add(log)
