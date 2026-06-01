"""
FuelIQ — Fuel Service
Core business logic for fuel logging with efficiency calculation.
"""
import uuid
from decimal import Decimal, ROUND_HALF_UP
from datetime import datetime, UTC

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.models import FuelLog, Vehicle
from app.repositories.fuel_repository import FuelRepository
from app.repositories.vehicle_repository import VehicleRepository
from app.schemas.schemas import FuelLogCreateRequest, FuelLogResponse
from app.core.cache import CacheService

logger = structlog.get_logger(__name__)


class FuelEfficiencyCalculator:
    """
    Encapsulates fuel efficiency calculation logic.
    Supports L/100km, km/L, and MPG.
    """

    @staticmethod
    def calculate_lper100km(
        distance_km: Decimal, volume_liters: Decimal
    ) -> Decimal | None:
        """L/100km (lower = better). Most common in India/Europe."""
        if distance_km <= 0 or volume_liters <= 0:
            return None
        result = (volume_liters / distance_km) * 100
        return result.quantize(Decimal("0.001"), rounding=ROUND_HALF_UP)

    @staticmethod
    def calculate_kmperliter(
        distance_km: Decimal, volume_liters: Decimal
    ) -> Decimal | None:
        """km/L (higher = better). Common in India."""
        if distance_km <= 0 or volume_liters <= 0:
            return None
        result = distance_km / volume_liters
        return result.quantize(Decimal("0.001"), rounding=ROUND_HALF_UP)

    @staticmethod
    def calculate_mpg(distance_km: Decimal, volume_liters: Decimal) -> Decimal | None:
        """Miles per gallon (US). Conversion for US users."""
        if distance_km <= 0 or volume_liters <= 0:
            return None
        miles = distance_km * Decimal("0.621371")
        gallons = volume_liters * Decimal("0.264172")
        return (miles / gallons).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


class FuelService:
    """
    Core fuel logging service.
    Orchestrates: validation → efficiency calculation → persistence → cache invalidation.
    """

    MAX_VEHICLES_PER_USER = 10  # MVP limit

    def __init__(
        self,
        session: AsyncSession,
        cache: CacheService,
    ):
        self._fuel_repo = FuelRepository(session)
        self._vehicle_repo = VehicleRepository(session)
        self._cache = cache
        self._calculator = FuelEfficiencyCalculator()

    async def create_fuel_log(
        self,
        vehicle_id: uuid.UUID,
        user_id: uuid.UUID,
        data: FuelLogCreateRequest,
        *,
        ip_address: str | None = None,
    ) -> FuelLog:
        """
        Create a fuel log entry with automatic efficiency calculation.
        
        Algorithm:
        1. Validate vehicle ownership
        2. Validate odometer progression
        3. If full tank: fetch previous full-tank log, calculate efficiency
        4. Persist log
        5. Update vehicle current odometer
        6. Invalidate relevant caches
        7. Return enriched log
        """
        # 1. Validate vehicle ownership
        vehicle = await self._vehicle_repo.get_user_vehicle(vehicle_id, user_id)
        if not vehicle:
            from fastapi import HTTPException, status
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found",
            )

        if vehicle.is_archived:
            from fastapi import HTTPException, status
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot log fuel for an archived vehicle",
            )

        # 2. Validate odometer progression
        if data.odometer_reading <= vehicle.current_odometer and vehicle.current_odometer > 0:
            from fastapi import HTTPException, status
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Odometer reading {data.odometer_reading} must be greater than "
                       f"current odometer {vehicle.current_odometer}",
            )

        # 3. Calculate efficiency (only for full tank fills)
        efficiency_lper100km = None
        efficiency_kmperliter = None
        distance_since_last = None

        if data.is_full_tank:
            prev_log = await self._fuel_repo.get_previous_full_tank_log(
                vehicle_id, data.odometer_reading
            )
            if prev_log:
                distance = data.odometer_reading - prev_log.odometer_reading
                if distance > 0:
                    distance_since_last = distance
                    # Use the volume from the PREVIOUS log (that's the fuel consumed
                    # to travel from prev_log to current odometer)
                    # Standard method: volume at current fill / distance since last full fill
                    efficiency_lper100km = self._calculator.calculate_lper100km(
                        distance, prev_log.volume_liters
                    )
                    efficiency_kmperliter = self._calculator.calculate_kmperliter(
                        distance, prev_log.volume_liters
                    )

        # 4. Persist
        log_data = {
            "vehicle_id": vehicle_id,
            "user_id": user_id,
            "odometer_reading": data.odometer_reading,
            "volume_liters": data.volume_liters,
            "price_per_liter": data.price_per_liter,
            "is_full_tank": data.is_full_tank,
            "station_name": data.station_name,
            "fuel_brand": data.fuel_brand,
            "notes": data.notes,
            "filled_at": data.filled_at or datetime.now(UTC),
            "receipt_url": data.receipt_url,
            "logged_via": data.logged_via,
            "ocr_confidence": data.ocr_confidence,
            "efficiency_lper100km": efficiency_lper100km,
            "efficiency_kmperliter": efficiency_kmperliter,
            "distance_since_last": distance_since_last,
        }

        fuel_log = await self._fuel_repo.create(
            log_data, user_id=user_id, ip_address=ip_address
        )

        # 5. Update vehicle odometer
        await self._vehicle_repo.update_odometer(vehicle_id, float(data.odometer_reading))

        # 6. Invalidate caches
        await self._cache.invalidate_vehicle_stats(str(vehicle_id))
        await self._cache.invalidate_vehicle_analytics(str(vehicle_id))

        logger.info(
            "fuel_log_created",
            fuel_log_id=str(fuel_log.id),
            vehicle_id=str(vehicle_id),
            efficiency=str(efficiency_lper100km),
            is_full_tank=data.is_full_tank,
        )

        return fuel_log

    async def get_logs(
        self,
        vehicle_id: uuid.UUID,
        user_id: uuid.UUID,
        *,
        page: int = 1,
        page_size: int = 20,
        start_date: datetime | None = None,
        end_date: datetime | None = None,
    ) -> tuple[list[FuelLog], int]:
        # Verify ownership
        vehicle = await self._vehicle_repo.get_user_vehicle(vehicle_id, user_id)
        if not vehicle:
            from fastapi import HTTPException, status
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vehicle not found")

        offset = (page - 1) * page_size
        logs, total = await self._fuel_repo.get_vehicle_logs(
            vehicle_id,
            offset=offset,
            limit=page_size,
            start_date=start_date,
            end_date=end_date,
        )
        return list(logs), total

    async def delete_log(
        self, log_id: uuid.UUID, vehicle_id: uuid.UUID, user_id: uuid.UUID
    ) -> None:
        from fastapi import HTTPException, status
        
        log = await self._fuel_repo.get_by_id(log_id)
        if not log or log.vehicle_id != vehicle_id or log.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Fuel log not found",
            )

        await self._fuel_repo.soft_delete(log, user_id=user_id)
        await self._cache.invalidate_vehicle_stats(str(vehicle_id))
        await self._cache.invalidate_vehicle_analytics(str(vehicle_id))
