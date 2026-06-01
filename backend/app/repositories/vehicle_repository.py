"""
FuelIQ — Vehicle Repository
"""
import uuid
from typing import Sequence
from sqlalchemy import select, and_, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.models import Vehicle
from app.repositories.base_repository import BaseRepository


class VehicleRepository(BaseRepository[Vehicle]):
    def __init__(self, session: AsyncSession):
        super().__init__(Vehicle, session)

    async def get_user_vehicles(
        self, user_id: uuid.UUID, *, include_archived: bool = False
    ) -> Sequence[Vehicle]:
        conditions = [
            Vehicle.user_id == user_id,
            Vehicle.deleted_at.is_(None),
        ]
        if not include_archived:
            conditions.append(Vehicle.is_archived == False)

        stmt = (
            select(Vehicle)
            .where(and_(*conditions))
            .order_by(Vehicle.is_primary.desc(), Vehicle.created_at.asc())
        )
        result = await self._session.execute(stmt)
        return result.scalars().all()

    async def get_user_vehicle(
        self, vehicle_id: uuid.UUID, user_id: uuid.UUID
    ) -> Vehicle | None:
        """Get a vehicle, ensuring it belongs to the requesting user."""
        stmt = select(Vehicle).where(
            and_(
                Vehicle.id == vehicle_id,
                Vehicle.user_id == user_id,
                Vehicle.deleted_at.is_(None),
            )
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def count_user_vehicles(self, user_id: uuid.UUID) -> int:
        stmt = select(func.count()).select_from(Vehicle).where(
            and_(
                Vehicle.user_id == user_id,
                Vehicle.is_archived == False,
                Vehicle.deleted_at.is_(None),
            )
        )
        result = await self._session.execute(stmt)
        return result.scalar() or 0

    async def clear_primary_flag(self, user_id: uuid.UUID) -> None:
        """Clear is_primary from all user vehicles before setting new primary."""
        result = await self._session.execute(
            select(Vehicle).where(
                and_(Vehicle.user_id == user_id, Vehicle.is_primary == True)
            )
        )
        for vehicle in result.scalars().all():
            vehicle.is_primary = False
        await self._session.flush()

    async def update_odometer(
        self, vehicle_id: uuid.UUID, odometer: float
    ) -> None:
        result = await self._session.execute(
            select(Vehicle).where(Vehicle.id == vehicle_id)
        )
        vehicle = result.scalar_one_or_none()
        if vehicle and float(odometer) > float(vehicle.current_odometer):
            vehicle.current_odometer = odometer
            await self._session.flush()
