"""FuelIQ — Auth Router"""
import uuid
from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import CurrentUser
from app.core.database import get_write_session, get_read_session
from app.schemas.schemas import APIResponse, UserSyncRequest, UserResponse, FCMTokenUpdateRequest
from app.repositories.user_repository import UserRepository

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/sync-user",
    response_model=APIResponse[UserResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Sync Firebase user to FuelIQ DB",
    description="Called after first login. Creates user if not exists, updates profile if exists.",
)
async def sync_user(
    body: UserSyncRequest,
    request: Request,
    db: AsyncSession = Depends(get_write_session),
) -> APIResponse[UserResponse]:
    repo = UserRepository(db)
    
    user = await repo.get_by_firebase_uid(body.firebase_uid)
    
    if not user:
        # First time login — create user
        # Note: We temporarily store firebase_uid in the clerk_id column to avoid schema changes
        user = await repo.create({
            "clerk_id": body.firebase_uid,
            "email": body.email.lower(),
            "display_name": body.display_name,
            "avatar_url": body.avatar_url,
        })
        message = "Account created successfully"
    else:
        # Subsequent login — update profile from Firebase
        update_data = {}
        if body.display_name and body.display_name != user.display_name:
            update_data["display_name"] = body.display_name
        if body.avatar_url and body.avatar_url != user.avatar_url:
            update_data["avatar_url"] = body.avatar_url
        if update_data:
            user = await repo.update(user, update_data)
        message = "User synced successfully"

    return APIResponse(data=UserResponse.model_validate(user), message=message)


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Invalidate user cache on logout",
)
async def logout(current_user: CurrentUser) -> None:
    from app.core.cache import RedisClient, CacheService
    redis = RedisClient.get_client()
    cache = CacheService(redis)
    # The current_user.clerk_id actually holds the firebase_uid right now
    await cache.invalidate_user(current_user.clerk_id)


@router.put(
    "/fcm-token",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Update FCM device token",
)
async def update_fcm_token(
    body: FCMTokenUpdateRequest,
    current_user: CurrentUser,
    db: AsyncSession = Depends(get_write_session),
) -> None:
    repo = UserRepository(db)
    await repo.update_fcm_token(current_user.id, body.fcm_token)
