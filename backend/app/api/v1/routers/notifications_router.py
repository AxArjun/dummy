"""FuelIQ — Notifications Router"""
import uuid
from typing import Annotated
from fastapi import APIRouter, Depends, Path, Query, status
from sqlalchemy import select, and_, update
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, UTC
from app.core.auth import CurrentUser
from app.core.database import get_write_session, get_read_session
from app.models.models import Notification
from app.schemas.schemas import APIResponse, NotificationResponse, PaginatedResponse

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=APIResponse[PaginatedResponse[NotificationResponse]])
async def list_notifications(
    current_user: CurrentUser,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    unread_only: bool = False,
    db: AsyncSession = Depends(get_read_session),
) -> APIResponse[PaginatedResponse[NotificationResponse]]:
    from sqlalchemy import func, desc
    
    conditions = [Notification.user_id == current_user.id]
    if unread_only:
        conditions.append(Notification.is_read == False)

    count_result = await db.execute(
        select(func.count()).select_from(Notification).where(and_(*conditions))
    )
    total = count_result.scalar() or 0

    result = await db.execute(
        select(Notification)
        .where(and_(*conditions))
        .order_by(desc(Notification.created_at))
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    items = result.scalars().all()
    data = [NotificationResponse.model_validate(n) for n in items]
    return APIResponse(data=PaginatedResponse.from_list(data, total, page, page_size))


@router.post("/mark-all-read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_all_read(
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> None:
    await db.execute(
        update(Notification)
        .where(and_(
            Notification.user_id == current_user.id,
            Notification.is_read == False,
        ))
        .values(is_read=True, read_at=datetime.now(UTC))
    )


@router.patch("/{notification_id}/read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_read(
    notification_id: Annotated[uuid.UUID, Path()],
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> None:
    from fastapi import HTTPException
    result = await db.execute(
        select(Notification).where(
            and_(Notification.id == notification_id, Notification.user_id == current_user.id)
        )
    )
    notification = result.scalar_one_or_none()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    notification.is_read = True
    notification.read_at = datetime.now(UTC)
