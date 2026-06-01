"""FuelIQ — Users Router"""
import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import CurrentUser
from app.core.database import get_write_session, get_read_session
from app.schemas.schemas import APIResponse, UserResponse, UserUpdateRequest
from app.repositories.user_repository import UserRepository

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=APIResponse[UserResponse])
async def get_profile(current_user: CurrentUser) -> APIResponse[UserResponse]:
    return APIResponse(data=UserResponse.model_validate(current_user))


@router.patch("/me", response_model=APIResponse[UserResponse])
async def update_profile(
    body: UserUpdateRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> APIResponse[UserResponse]:
    repo = UserRepository(db)
    update_data = {}
    
    if body.display_name is not None:
        update_data["display_name"] = body.display_name
    
    if body.preferences:
        update_data["distance_unit"] = body.preferences.distance_unit
        update_data["volume_unit"] = body.preferences.volume_unit
        update_data["currency"] = body.preferences.currency
        update_data["timezone"] = body.preferences.timezone

    if update_data:
        user = await repo.update(current_user, update_data, user_id=current_user.id)
        # Invalidate cache
        from app.core.cache import RedisClient, CacheService
        await CacheService(RedisClient.get_client()).invalidate_user(current_user.clerk_id)
    else:
        user = current_user

    return APIResponse(data=UserResponse.model_validate(user))
