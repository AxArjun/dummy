"""FuelIQ — Analytics Router"""
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import CurrentUser
from app.core.cache import CacheService, get_redis
from app.core.database import get_read_session
from app.modules.analytics.analytics_service import AnalyticsService
from app.repositories.vehicle_repository import VehicleRepository
from app.schemas.schemas import APIResponse, VehicleAnalyticsSummary

router = APIRouter(prefix="/vehicles/{vehicle_id}/analytics", tags=["analytics"])


@router.get("", response_model=APIResponse[VehicleAnalyticsSummary])
async def get_vehicle_analytics(
    vehicle_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    months: int = Query(default=12, ge=1, le=60),
    db: AsyncSession = Depends(get_read_session),
    redis: Redis = Depends(get_redis),
) -> APIResponse[VehicleAnalyticsSummary]:
    from fastapi import HTTPException
    
    # Verify ownership
    repo = VehicleRepository(db)
    vehicle = await repo.get_user_vehicle(vehicle_id, current_user.id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    service = AnalyticsService(db, CacheService(redis))
    analytics = await service.get_vehicle_analytics(
        vehicle_id=vehicle_id,
        user_id=current_user.id,
        months=months,
    )
    return APIResponse(data=analytics)
