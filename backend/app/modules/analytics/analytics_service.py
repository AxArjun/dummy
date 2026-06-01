"""
FuelIQ — Analytics Service
Mileage, cost, efficiency, and trend calculations.
"""
import uuid
from decimal import Decimal, ROUND_HALF_UP
from datetime import datetime, date, timedelta, UTC
from typing import Any

import structlog
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.cache import CacheService
from app.repositories.fuel_repository import FuelRepository
from app.schemas.schemas import (
    VehicleAnalyticsSummary,
    MonthlyFuelStat,
    EfficiencyTrendPoint,
    ExpenseBreakdown,
)
from app.models.models import ExpenseCategory

logger = structlog.get_logger(__name__)


class AnalyticsService:
    """
    Analytics engine for vehicle intelligence.
    
    Design: Compute heavy queries against read replica.
    Cache results aggressively (1 hour TTL).
    Invalidate on mutations (fuel log, expense, service).
    """

    def __init__(self, session: AsyncSession, cache: CacheService):
        self._session = session
        self._cache = cache
        self._fuel_repo = FuelRepository(session)

    async def get_vehicle_analytics(
        self,
        vehicle_id: uuid.UUID,
        user_id: uuid.UUID,
        *,
        months: int = 12,
    ) -> VehicleAnalyticsSummary:
        """
        Full analytics summary for a vehicle.
        Cached for 1 hour, invalidated on any mutation.
        """
        cache_key = f"analytics:{vehicle_id}:summary:{months}"
        cached = await self._cache.get(cache_key)
        
        if cached:
            import json
            data = json.loads(cached)
            return VehicleAnalyticsSummary(**data)

        # Compute from DB
        summary = await self._compute_analytics(vehicle_id, user_id, months=months)

        # Cache
        import json
        await self._cache.set(
            cache_key,
            json.dumps(summary.model_dump(mode="json")),
            ttl=3600,
        )

        return summary

    async def _compute_analytics(
        self,
        vehicle_id: uuid.UUID,
        user_id: uuid.UUID,
        *,
        months: int,
    ) -> VehicleAnalyticsSummary:
        """Execute analytics queries against the database."""

        # 1. Vehicle summary totals
        totals = await self._get_vehicle_totals(vehicle_id, months=months)

        # 2. Monthly fuel stats
        monthly_stats = await self._get_monthly_fuel_stats(vehicle_id, months=months)

        # 3. Efficiency trend (last 10 full-tank fills)
        efficiency_trend = await self._get_efficiency_trend(vehicle_id)

        # 4. Expense breakdown (all time)
        expense_breakdown = await self._get_expense_breakdown(vehicle_id, months=months)

        # 5. Derived metrics
        total_distance = totals.get("total_distance_km", Decimal("0"))
        total_fuel_cost = totals.get("total_fuel_cost", Decimal("0"))
        total_expense = totals.get("total_expense_cost", Decimal("0"))
        total_service = totals.get("total_service_cost", Decimal("0"))
        total_cost = total_fuel_cost + total_expense + total_service

        cost_per_km = None
        if total_distance and total_distance > 0 and total_cost > 0:
            cost_per_km = (total_cost / total_distance).quantize(
                Decimal("0.01"), rounding=ROUND_HALF_UP
            )

        return VehicleAnalyticsSummary(
            vehicle_id=vehicle_id,
            total_distance_km=total_distance,
            total_fuel_cost=total_fuel_cost,
            total_other_expenses=total_expense,
            total_service_cost=total_service,
            total_cost_of_ownership=total_cost,
            avg_efficiency_lper100km=totals.get("avg_efficiency"),
            cost_per_km=cost_per_km,
            total_fills=int(totals.get("total_fills", 0)),
            monthly_stats=monthly_stats,
            efficiency_trend=efficiency_trend,
            expense_breakdown=expense_breakdown,
        )

    async def _get_vehicle_totals(
        self, vehicle_id: uuid.UUID, *, months: int
    ) -> dict[str, Any]:
        stmt = text("""
            WITH fuel_totals AS (
                SELECT
                    COUNT(*) AS fill_count,
                    COALESCE(SUM(total_cost), 0) AS fuel_cost,
                    AVG(efficiency_lper100km) FILTER (WHERE efficiency_lper100km IS NOT NULL) AS avg_efficiency
                FROM fuel_logs
                WHERE vehicle_id = :vid
                  AND deleted_at IS NULL
            ),
            expense_totals AS (
                SELECT COALESCE(SUM(amount), 0) AS expense_cost
                FROM expenses
                WHERE vehicle_id = :vid
                  AND deleted_at IS NULL
                  AND category != 'fuel'
            ),
            service_totals AS (
                SELECT COALESCE(SUM(cost), 0) AS service_cost
                FROM service_records
                WHERE vehicle_id = :vid
                  AND deleted_at IS NULL
            ),
            vehicle_data AS (
                SELECT current_odometer - initial_odometer AS total_distance
                FROM vehicles
                WHERE id = :vid
            )
            SELECT
                f.fill_count AS total_fills,
                f.fuel_cost AS total_fuel_cost,
                f.avg_efficiency,
                e.expense_cost AS total_expense_cost,
                s.service_cost AS total_service_cost,
                v.total_distance AS total_distance_km
            FROM fuel_totals f, expense_totals e, service_totals s, vehicle_data v
        """)

        result = await self._session.execute(stmt, {"vid": vehicle_id})
        row = result.mappings().one_or_none()
        return dict(row) if row else {}

    async def _get_monthly_fuel_stats(
        self, vehicle_id: uuid.UUID, *, months: int
    ) -> list[MonthlyFuelStat]:
        stmt = text("""
            SELECT
                DATE_TRUNC('month', filled_at) AS month,
                COALESCE(SUM(total_cost), 0) AS total_cost,
                COALESCE(SUM(volume_liters), 0) AS total_liters,
                AVG(efficiency_lper100km) FILTER (WHERE efficiency_lper100km IS NOT NULL) AS avg_efficiency_lper100km,
                COUNT(*) AS fill_count
            FROM fuel_logs
            WHERE vehicle_id = :vid
              AND filled_at >= NOW() - (:months || ' months')::INTERVAL
              AND deleted_at IS NULL
            GROUP BY DATE_TRUNC('month', filled_at)
            ORDER BY month ASC
        """)

        result = await self._session.execute(stmt, {"vid": vehicle_id, "months": months})
        rows = result.mappings().all()

        return [
            MonthlyFuelStat(
                month=row["month"],
                total_cost=row["total_cost"] or Decimal("0"),
                total_liters=row["total_liters"] or Decimal("0"),
                avg_efficiency_lper100km=row["avg_efficiency_lper100km"],
                fill_count=row["fill_count"],
            )
            for row in rows
        ]

    async def _get_efficiency_trend(
        self, vehicle_id: uuid.UUID
    ) -> list[EfficiencyTrendPoint]:
        logs = await self._fuel_repo.get_efficiency_trend(vehicle_id, limit=20)
        return [
            EfficiencyTrendPoint(
                filled_at=log.filled_at,
                efficiency_lper100km=log.efficiency_lper100km,
                efficiency_kmperliter=log.efficiency_kmperliter,
                odometer_reading=log.odometer_reading,
            )
            for log in reversed(logs)  # Chronological order for chart
            if log.efficiency_lper100km and log.efficiency_kmperliter
        ]

    async def _get_expense_breakdown(
        self, vehicle_id: uuid.UUID, *, months: int
    ) -> list[ExpenseBreakdown]:
        stmt = text("""
            SELECT
                category,
                COALESCE(SUM(amount), 0) AS total_amount,
                COUNT(*) AS transaction_count
            FROM expenses
            WHERE vehicle_id = :vid
              AND expense_date >= CURRENT_DATE - (:months || ' months')::INTERVAL
              AND deleted_at IS NULL
            GROUP BY category
            ORDER BY total_amount DESC
        """)

        result = await self._session.execute(stmt, {"vid": vehicle_id, "months": months})
        rows = result.mappings().all()

        total = sum(row["total_amount"] for row in rows) or Decimal("1")

        return [
            ExpenseBreakdown(
                category=ExpenseCategory(row["category"]),
                total_amount=row["total_amount"],
                transaction_count=row["transaction_count"],
                percentage=round(float(row["total_amount"] / total) * 100, 1),
            )
            for row in rows
        ]
