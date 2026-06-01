"""
FuelIQ — Fuel Router (v1)
RESTful fuel log endpoints with full authorization.
"""
import uuid
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query, Request, status
from fastapi.responses import JSONResponse
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import CurrentUser
from app.core.cache import CacheService, get_redis
from app.core.database import get_write_session, get_read_session
from app.modules.fuel.fuel_service import FuelService
from app.schemas.schemas import (
    APIResponse,
    FuelLogCreateRequest,
    FuelLogResponse,
    FuelLogUpdateRequest,
    PaginatedResponse,
)

router = APIRouter(prefix="/vehicles/{vehicle_id}/fuel-logs", tags=["fuel"])


def get_fuel_service(
    db: AsyncSession = Depends(get_write_session),
    redis: Redis = Depends(get_redis),
) -> FuelService:
    return FuelService(session=db, cache=CacheService(redis))


@router.post(
    "",
    response_model=APIResponse[FuelLogResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Log a fuel fill",
    description="""
    Create a new fuel log entry for a vehicle.
    
    - Validates vehicle ownership
    - Validates odometer progression  
    - Automatically calculates fuel efficiency (L/100km and km/L) for full-tank fills
    - Updates vehicle's current odometer
    - Invalidates analytics cache
    """,
)
async def create_fuel_log(
    vehicle_id: Annotated[uuid.UUID, Path(description="Vehicle UUID")],
    body: FuelLogCreateRequest,
    request: Request,
    current_user: CurrentUser,
    service: FuelService = Depends(get_fuel_service),
) -> APIResponse[FuelLogResponse]:
    ip = request.headers.get("X-Forwarded-For", request.client.host if request.client else None)
    
    fuel_log = await service.create_fuel_log(
        vehicle_id=vehicle_id,
        user_id=current_user.id,
        data=body,
        ip_address=ip,
    )

    response = FuelLogResponse.model_validate(fuel_log)

    # Contextual success message based on efficiency
    message = "Fuel logged successfully"
    if fuel_log.efficiency_kmperliter:
        message = f"Fuel logged — {fuel_log.efficiency_kmperliter:.1f} km/L this fill"

    return APIResponse(data=response, message=message)


@router.get(
    "",
    response_model=APIResponse[PaginatedResponse[FuelLogResponse]],
    summary="List fuel logs for a vehicle",
)
async def list_fuel_logs(
    vehicle_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    start_date: datetime | None = Query(default=None),
    end_date: datetime | None = Query(default=None),
    db: AsyncSession = Depends(get_read_session),
    redis: Redis = Depends(get_redis),
) -> APIResponse[PaginatedResponse[FuelLogResponse]]:
    service = FuelService(session=db, cache=CacheService(redis))
    
    logs, total = await service.get_logs(
        vehicle_id=vehicle_id,
        user_id=current_user.id,
        page=page,
        page_size=page_size,
        start_date=start_date,
        end_date=end_date,
    )

    items = [FuelLogResponse.model_validate(log) for log in logs]
    paginated = PaginatedResponse.from_list(items, total, page, page_size)

    return APIResponse(data=paginated)


@router.get(
    "/{log_id}",
    response_model=APIResponse[FuelLogResponse],
    summary="Get a specific fuel log",
)
async def get_fuel_log(
    vehicle_id: Annotated[uuid.UUID, Path()],
    log_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_read_session),
) -> APIResponse[FuelLogResponse]:
    from app.repositories.fuel_repository import FuelRepository
    from fastapi import HTTPException

    repo = FuelRepository(db)
    log = await repo.get_by_id(log_id)

    if not log or log.vehicle_id != vehicle_id or log.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Fuel log not found")

    return APIResponse(data=FuelLogResponse.model_validate(log))


@router.patch(
    "/{log_id}",
    response_model=APIResponse[FuelLogResponse],
    summary="Update a fuel log",
)
async def update_fuel_log(
    vehicle_id: Annotated[uuid.UUID, Path()],
    log_id: Annotated[uuid.UUID, Path()],
    body: FuelLogUpdateRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
    redis: Redis = Depends(get_redis),
) -> APIResponse[FuelLogResponse]:
    from app.repositories.fuel_repository import FuelRepository
    from fastapi import HTTPException

    repo = FuelRepository(db)
    log = await repo.get_by_id(log_id)

    if not log or log.vehicle_id != vehicle_id or log.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Fuel log not found")

    update_data = body.model_dump(exclude_none=True)
    updated_log = await repo.update(log, update_data, user_id=current_user.id)

    cache = CacheService(redis)
    await cache.invalidate_vehicle_stats(str(vehicle_id))
    await cache.invalidate_vehicle_analytics(str(vehicle_id))

    return APIResponse(data=FuelLogResponse.model_validate(updated_log))


@router.delete(
    "/{log_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a fuel log (soft delete)",
)
async def delete_fuel_log(
    vehicle_id: Annotated[uuid.UUID, Path()],
    log_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
    redis: Redis = Depends(get_redis),
) -> None:
    service = FuelService(session=db, cache=CacheService(redis))
    await service.delete_log(
        log_id=log_id,
        vehicle_id=vehicle_id,
        user_id=current_user.id,
    )
