"""FuelIQ — Services + Reminders Router"""
import uuid
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.auth import CurrentUser
from app.core.database import get_write_session, get_read_session
from app.repositories.base_repository import BaseRepository
from app.repositories.vehicle_repository import VehicleRepository
from app.models.models import ServiceRecord, Reminder
from app.schemas.schemas import (
    APIResponse, ServiceRecordCreateRequest, ServiceRecordResponse,
    ReminderCreateRequest, ReminderResponse, PaginatedResponse
)

router = APIRouter(tags=["services"])
srv_router = APIRouter(prefix="/vehicles/{vehicle_id}/service-records")
rem_router = APIRouter(prefix="/vehicles/{vehicle_id}/reminders")


# ─── Service Records ──────────────────────────────────────────────────────────

@srv_router.post("", response_model=APIResponse[ServiceRecordResponse], status_code=status.HTTP_201_CREATED)
async def create_service_record(
    vehicle_id: Annotated[uuid.UUID, Path()],
    body: ServiceRecordCreateRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> APIResponse[ServiceRecordResponse]:
    vrep = VehicleRepository(db)
    vehicle = await vrep.get_user_vehicle(vehicle_id, current_user.id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    
    repo = BaseRepository(ServiceRecord, db)
    record = await repo.create({
        "vehicle_id": vehicle_id,
        "user_id": current_user.id,
        **body.model_dump(),
    }, user_id=current_user.id)
    
    return APIResponse(data=ServiceRecordResponse.model_validate(record), message="Service logged")


@srv_router.get("", response_model=APIResponse[PaginatedResponse[ServiceRecordResponse]])
async def list_service_records(
    vehicle_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_read_session),
) -> APIResponse[PaginatedResponse[ServiceRecordResponse]]:
    vrep = VehicleRepository(db)
    if not await vrep.get_user_vehicle(vehicle_id, current_user.id):
        raise HTTPException(status_code=404, detail="Vehicle not found")
    
    repo = BaseRepository(ServiceRecord, db)
    items, total = await repo.get_all(
        offset=(page - 1) * page_size, limit=page_size,
        vehicle_id=vehicle_id, user_id=current_user.id,
    )
    data = [ServiceRecordResponse.model_validate(r) for r in items]
    return APIResponse(data=PaginatedResponse.from_list(data, total, page, page_size))


# ─── Reminders ────────────────────────────────────────────────────────────────

@rem_router.post("", response_model=APIResponse[ReminderResponse], status_code=status.HTTP_201_CREATED)
async def create_reminder(
    vehicle_id: Annotated[uuid.UUID, Path()],
    body: ReminderCreateRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> APIResponse[ReminderResponse]:
    vrep = VehicleRepository(db)
    if not await vrep.get_user_vehicle(vehicle_id, current_user.id):
        raise HTTPException(status_code=404, detail="Vehicle not found")
    
    repo = BaseRepository(Reminder, db)
    reminder = await repo.create({
        "vehicle_id": vehicle_id,
        "user_id": current_user.id,
        **body.model_dump(),
    }, user_id=current_user.id)
    
    return APIResponse(data=ReminderResponse.model_validate(reminder), message="Reminder set")


@rem_router.get("", response_model=APIResponse[list[ReminderResponse]])
async def list_reminders(
    vehicle_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_read_session),
) -> APIResponse[list[ReminderResponse]]:
    vrep = VehicleRepository(db)
    if not await vrep.get_user_vehicle(vehicle_id, current_user.id):
        raise HTTPException(status_code=404, detail="Vehicle not found")
    
    repo = BaseRepository(Reminder, db)
    items, _ = await repo.get_all(vehicle_id=vehicle_id, user_id=current_user.id, limit=100)
    return APIResponse(data=[ReminderResponse.model_validate(r) for r in items])


@rem_router.delete("/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_reminder(
    vehicle_id: Annotated[uuid.UUID, Path()],
    reminder_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> None:
    repo = BaseRepository(Reminder, db)
    reminder = await repo.get_by_id(reminder_id)
    if not reminder or reminder.vehicle_id != vehicle_id or reminder.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Reminder not found")
    await repo.soft_delete(reminder, user_id=current_user.id)


# Register both sub-routers on the main router
router.include_router(srv_router)
router.include_router(rem_router)
