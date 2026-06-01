"""FuelIQ — Vehicles Router"""
import uuid
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, UploadFile, File, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import CurrentUser
from app.core.database import get_write_session, get_read_session
from app.repositories.vehicle_repository import VehicleRepository
from app.schemas.schemas import (
    APIResponse, VehicleCreateRequest, VehicleResponse, VehicleUpdateRequest
)

router = APIRouter(prefix="/vehicles", tags=["vehicles"])

MAX_VEHICLES_PER_USER = 10


@router.get("", response_model=APIResponse[list[VehicleResponse]])
async def list_vehicles(
    current_user: CurrentUser,
    include_archived: bool = False,
    db: AsyncSession = Depends(get_read_session),
) -> APIResponse[list[VehicleResponse]]:
    repo = VehicleRepository(db)
    vehicles = await repo.get_user_vehicles(current_user.id, include_archived=include_archived)
    return APIResponse(data=[VehicleResponse.model_validate(v) for v in vehicles])


@router.post("", response_model=APIResponse[VehicleResponse], status_code=status.HTTP_201_CREATED)
async def create_vehicle(
    body: VehicleCreateRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> APIResponse[VehicleResponse]:
    repo = VehicleRepository(db)
    
    count = await repo.count_user_vehicles(current_user.id)
    if count >= MAX_VEHICLES_PER_USER:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Maximum {MAX_VEHICLES_PER_USER} vehicles per account reached",
        )
    
    if body.is_primary:
        await repo.clear_primary_flag(current_user.id)
    elif count == 0:
        # First vehicle is always primary
        body = body.model_copy(update={"is_primary": True})

    vehicle = await repo.create(
        {
            "user_id": current_user.id,
            "make": body.make,
            "model": body.model,
            "year": body.year,
            "fuel_type": body.fuel_type,
            "vehicle_type": body.vehicle_type,
            "license_plate": body.license_plate,
            "vin": body.vin,
            "color": body.color,
            "tank_capacity_liters": body.tank_capacity_liters,
            "initial_odometer": body.initial_odometer,
            "current_odometer": body.initial_odometer,
            "is_primary": body.is_primary,
        },
        user_id=current_user.id,
    )
    return APIResponse(data=VehicleResponse.model_validate(vehicle), message="Vehicle added to garage")


@router.get("/{vehicle_id}", response_model=APIResponse[VehicleResponse])
async def get_vehicle(
    vehicle_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_read_session),
) -> APIResponse[VehicleResponse]:
    repo = VehicleRepository(db)
    vehicle = await repo.get_user_vehicle(vehicle_id, current_user.id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return APIResponse(data=VehicleResponse.model_validate(vehicle))


@router.patch("/{vehicle_id}", response_model=APIResponse[VehicleResponse])
async def update_vehicle(
    vehicle_id: Annotated[uuid.UUID, Path()],
    body: VehicleUpdateRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> APIResponse[VehicleResponse]:
    repo = VehicleRepository(db)
    vehicle = await repo.get_user_vehicle(vehicle_id, current_user.id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    update_data = body.model_dump(exclude_none=True)
    
    if update_data.get("is_primary"):
        await repo.clear_primary_flag(current_user.id)

    updated = await repo.update(vehicle, update_data, user_id=current_user.id)
    return APIResponse(data=VehicleResponse.model_validate(updated))


@router.post("/{vehicle_id}/archive", status_code=status.HTTP_204_NO_CONTENT)
async def archive_vehicle(
    vehicle_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> None:
    repo = VehicleRepository(db)
    vehicle = await repo.get_user_vehicle(vehicle_id, current_user.id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    
    await repo.update(vehicle, {
        "is_archived": True,
        "archived_at": datetime.utcnow(),
        "is_primary": False,
    }, user_id=current_user.id)


@router.delete("/{vehicle_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_vehicle(
    vehicle_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> None:
    repo = VehicleRepository(db)
    vehicle = await repo.get_user_vehicle(vehicle_id, current_user.id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    await repo.soft_delete(vehicle, user_id=current_user.id)
