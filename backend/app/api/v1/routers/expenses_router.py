"""FuelIQ — Expenses Router"""
import uuid
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.auth import CurrentUser
from app.core.database import get_write_session, get_read_session
from app.repositories.base_repository import BaseRepository
from app.repositories.vehicle_repository import VehicleRepository
from app.models.models import Expense
from app.schemas.schemas import APIResponse, ExpenseCreateRequest, ExpenseResponse, PaginatedResponse

router = APIRouter(prefix="/vehicles/{vehicle_id}/expenses", tags=["expenses"])


@router.post("", response_model=APIResponse[ExpenseResponse], status_code=status.HTTP_201_CREATED)
async def create_expense(
    vehicle_id: Annotated[uuid.UUID, Path()],
    body: ExpenseCreateRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> APIResponse[ExpenseResponse]:
    vrep = VehicleRepository(db)
    vehicle = await vrep.get_user_vehicle(vehicle_id, current_user.id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    repo = BaseRepository(Expense, db)
    expense = await repo.create({
        "vehicle_id": vehicle_id,
        "user_id": current_user.id,
        **body.model_dump(),
    }, user_id=current_user.id)
    
    return APIResponse(data=ExpenseResponse.model_validate(expense), message="Expense recorded")


@router.get("", response_model=APIResponse[PaginatedResponse[ExpenseResponse]])
async def list_expenses(
    vehicle_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_read_session),
) -> APIResponse[PaginatedResponse[ExpenseResponse]]:
    vrep = VehicleRepository(db)
    vehicle = await vrep.get_user_vehicle(vehicle_id, current_user.id)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    repo = BaseRepository(Expense, db)
    items, total = await repo.get_all(
        offset=(page - 1) * page_size,
        limit=page_size,
        vehicle_id=vehicle_id,
        user_id=current_user.id,
    )
    
    data = [ExpenseResponse.model_validate(e) for e in items]
    return APIResponse(data=PaginatedResponse.from_list(data, total, page, page_size))


@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_expense(
    vehicle_id: Annotated[uuid.UUID, Path()],
    expense_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> None:
    repo = BaseRepository(Expense, db)
    expense = await repo.get_by_id(expense_id)
    if not expense or expense.vehicle_id != vehicle_id or expense.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Expense not found")
    await repo.soft_delete(expense, user_id=current_user.id)
