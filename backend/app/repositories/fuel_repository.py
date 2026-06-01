"""
FuelIQ — Fuel Log Repository
Critical path: efficiency calculation, history queries, analytics feeds.
"""
import uuid
from decimal import Decimal
from typing import Sequence
from datetime import datetime

from sqlalchemy import select, and_, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.models import FuelLog
from app.repositories.base_repository import BaseRepository


class FuelRepository(BaseRepository[FuelLog]):
    def __init__(self, session: AsyncSession):
        super().__init__(FuelLog, session)

    async def get_vehicle_logs(
        self,
        vehicle_id: uuid.UUID,
        *,
        offset: int = 0,
        limit: int = 20,
        start_date: datetime | None = None,
        end_date: datetime | None = None,
    ) -> tuple[Sequence[FuelLog], int]:
        conditions = [
            FuelLog.vehicle_id == vehicle_id,
            FuelLog.deleted_at.is_(None),
        ]
        if start_date:
            conditions.append(FuelLog.filled_at >= start_date)
        if end_date:
            conditions.append(FuelLog.filled_at <= end_date)

        count_result = await self._session.execute(
            select(func.count())
            .select_from(FuelLog)
            .where(and_(*conditions))
        )
        total = count_result.scalar() or 0

        stmt = (
            select(FuelLog)
            .where(and_(*conditions))
            .order_by(desc(FuelLog.filled_at))
            .offset(offset)
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return result.scalars().all(), total

    async def get_previous_full_tank_log(
        self, vehicle_id: uuid.UUID, before_odometer: Decimal
    ) -> FuelLog | None:
        """
        Fetch the most recent full-tank fill before the given odometer reading.
        Used for fuel efficiency calculation.
        """
        stmt = (
            select(FuelLog)
            .where(
                and_(
                    FuelLog.vehicle_id == vehicle_id,
                    FuelLog.is_full_tank == True,
                    FuelLog.odometer_reading < before_odometer,
                    FuelLog.deleted_at.is_(None),
                )
            )
            .order_by(desc(FuelLog.odometer_reading))
            .limit(1)
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_monthly_stats(
        self, vehicle_id: uuid.UUID, months: int = 12
    ) -> list[dict]:
        """
        Monthly aggregation: cost, volume, avg efficiency, fill count.
        Used for analytics charts.
        """
        stmt = """
            SELECT
                DATE_TRUNC('month', filled_at) AS month,
                SUM(total_cost) AS total_cost,
                SUM(volume_liters) AS total_liters,
                AVG(efficiency_lper100km) FILTER (WHERE efficiency_lper100km IS NOT NULL) AS avg_efficiency,
                COUNT(*) AS fill_count
            FROM fuel_logs
            WHERE vehicle_id = :vehicle_id
              AND filled_at >= NOW() - INTERVAL ':months months'
              AND deleted_at IS NULL
            GROUP BY DATE_TRUNC('month', filled_at)
            ORDER BY month ASC
        """
        from sqlalchemy import text
        result = await self._session.execute(
            text(stmt.replace(":months", str(months))),
            {"vehicle_id": vehicle_id},
        )
        return [dict(row._mapping) for row in result]

    async def get_efficiency_trend(
        self, vehicle_id: uuid.UUID, limit: int = 10
    ) -> Sequence[FuelLog]:
        """Last N full-tank fills with efficiency data for trend chart."""
        stmt = (
            select(FuelLog)
            .where(
                and_(
                    FuelLog.vehicle_id == vehicle_id,
                    FuelLog.is_full_tank == True,
                    FuelLog.efficiency_lper100km.is_not(None),
                    FuelLog.deleted_at.is_(None),
                )
            )
            .order_by(desc(FuelLog.filled_at))
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        return result.scalars().all()
