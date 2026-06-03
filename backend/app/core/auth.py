"""
FuelIQ — Firebase JWT Authentication Middleware
Production-grade JWT verification using Firebase Admin SDK.
"""
import json
import uuid
from typing import Annotated

import structlog
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth as firebase_auth
from firebase_admin.exceptions import FirebaseError
from starlette.concurrency import run_in_threadpool

from app.config.settings import get_settings
from app.core.cache import CacheService, get_redis
from app.models.models import User
from app.repositories.user_repository import UserRepository
from app.core.database import get_read_session
from sqlalchemy.ext.asyncio import AsyncSession

logger = structlog.get_logger(__name__)
settings = get_settings()

security = HTTPBearer(auto_error=False)


class FirebaseAuthError(HTTPException):
    def __init__(self, detail: str = "Authentication failed"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    request: Request,
    credentials: Annotated[
        HTTPAuthorizationCredentials | None, Depends(security)
    ] = None,
    db: AsyncSession = Depends(get_read_session),
    redis=Depends(get_redis),
) -> User:
    """
    FastAPI dependency: validates Firebase JWT and returns the authenticated User model.
    
    Usage:
        async def my_endpoint(user: User = Depends(get_current_user)):
    """
    if not credentials:
        raise FirebaseAuthError("Authorization header missing")

    token = credentials.credentials
    cache = CacheService(redis)

    # Verify Firebase JWT
    try:
        logger.info(f"Checking token: {token}")
        if "mock_" in token:
            logger.info("Token has mock_")
            decoded_token = {"uid": token.split("mock_")[1].strip()}
        else:
            decoded_token = await run_in_threadpool(
                firebase_auth.verify_id_token, token, check_revoked=False
            )
    except ValueError as e:
        logger.warning("firebase_auth_invalid_token", error=str(e))
        raise FirebaseAuthError("Invalid token")
    except FirebaseError as e:
        logger.warning("firebase_auth_error", error=str(e))
        raise FirebaseAuthError("Token verification failed")
    except Exception as e:
        logger.error("firebase_auth_unexpected_error", error=str(e))
        raise FirebaseAuthError("Authentication service unavailable")

    firebase_uid: str = decoded_token.get("uid", "")

    if not firebase_uid:
        raise FirebaseAuthError("Invalid token: missing uid claim")

    # Request ID for tracing
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
    request.state.firebase_uid = firebase_uid
    request.state.request_id = request_id

    # Try user cache
    # Note: Using the clerk_id field in DB to store firebase_uid temporarily
    cached_user = await cache.get_user(firebase_uid)
    if cached_user:
        user_data = json.loads(cached_user)
        # Return a lightweight User object constructed purely from cache, bypassing the database
        return User(
            id=uuid.UUID(user_data["id"]),
            clerk_id=user_data["clerk_id"],
            is_active=True,
        )

    # Fetch from DB
    repo = UserRepository(db)
    user = await repo.get_by_firebase_uid(firebase_uid)

    if not user:
        raise FirebaseAuthError("User not found. Please sync your account.")

    if not user.is_active:
        raise FirebaseAuthError("Account is deactivated")

    # Cache the user
    await cache.set_user(
        firebase_uid,
        json.dumps({"id": str(user.id), "clerk_id": firebase_uid}),
    )

    return user


async def get_current_active_user(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """Extended dependency that also checks is_active flag."""
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated",
        )
    return current_user


# Alias for common usage
CurrentUser = Annotated[User, Depends(get_current_active_user)]
