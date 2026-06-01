"""
FuelIQ — Clerk JWT Authentication Middleware
Production-grade JWT verification using Clerk's JWKS endpoint.
"""
import json
import uuid
from typing import Annotated

import httpx
import structlog
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from jose.exceptions import ExpiredSignatureError, JWTClaimsError

from app.config.settings import get_settings
from app.core.cache import CacheService, get_redis
from app.models.models import User
from app.repositories.user_repository import UserRepository
from app.core.database import get_read_session
from sqlalchemy.ext.asyncio import AsyncSession

logger = structlog.get_logger(__name__)
settings = get_settings()

security = HTTPBearer(auto_error=False)


class ClerkAuthError(HTTPException):
    def __init__(self, detail: str = "Authentication failed"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            headers={"WWW-Authenticate": "Bearer"},
        )


class ClerkJWTVerifier:
    """
    Verifies Clerk-issued JWTs using JWKS.
    JWKS is cached in Redis for 24h to avoid per-request external calls.
    """

    def __init__(self, cache: CacheService):
        self._cache = cache

    async def _fetch_jwks(self) -> dict:
        """
        Fetch JWKS from Clerk's well-known endpoint.
        Falls back to direct HTTP if cache unavailable.
        """
        # Try cache first
        cached = await self._cache.get_jwks()
        if cached:
            return json.loads(cached)

        # Fetch from Clerk
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                resp = await client.get(settings.CLERK_JWKS_URL)
                resp.raise_for_status()
                jwks = resp.json()
            except httpx.HTTPError as e:
                logger.error("clerk_jwks_fetch_failed", error=str(e))
                raise ClerkAuthError("Authentication service unavailable")

        # Cache the JWKS
        await self._cache.set_jwks(json.dumps(jwks))
        logger.info("clerk_jwks_cached", key_count=len(jwks.get("keys", [])))
        return jwks

    async def verify(self, token: str) -> dict:
        """
        Verify a Clerk JWT token.
        Returns decoded claims on success, raises ClerkAuthError on failure.
        """
        jwks = await self._fetch_jwks()

        try:
            # Extract header to get key ID (kid)
            header = jwt.get_unverified_header(token)
            kid = header.get("kid")

            # Find matching key from JWKS
            public_key = None
            for key in jwks.get("keys", []):
                if key.get("kid") == kid:
                    public_key = key
                    break

            if not public_key:
                logger.warning("clerk_jwt_kid_not_found", kid=kid)
                # Invalidate JWKS cache and retry once (key rotation scenario)
                await self._cache.delete("fueliq:jwks:clerk")
                jwks = await self._fetch_jwks()
                for key in jwks.get("keys", []):
                    if key.get("kid") == kid:
                        public_key = key
                        break

            if not public_key:
                raise ClerkAuthError("JWT key not found")

            # Verify and decode
            claims = jwt.decode(
                token,
                public_key,
                algorithms=["RS256"],
                options={
                    "verify_aud": False,  # Clerk doesn't always set aud
                    "verify_exp": True,
                    "verify_iat": True,
                    "leeway": 10,  # 10 second clock skew tolerance
                },
                issuer=settings.CLERK_ISSUER,
            )

            return claims

        except ExpiredSignatureError:
            raise ClerkAuthError("Token has expired")
        except JWTClaimsError as e:
            logger.warning("clerk_jwt_claims_error", error=str(e))
            raise ClerkAuthError("Invalid token claims")
        except JWTError as e:
            logger.warning("clerk_jwt_error", error=str(e))
            raise ClerkAuthError("Invalid token")


async def get_current_user(
    request: Request,
    credentials: Annotated[
        HTTPAuthorizationCredentials | None, Depends(security)
    ] = None,
    db: AsyncSession = Depends(get_read_session),
    redis=Depends(get_redis),
) -> User:
    """
    FastAPI dependency: validates JWT and returns the authenticated User model.
    
    Usage:
        async def my_endpoint(user: User = Depends(get_current_user)):
    """
    if not credentials:
        raise ClerkAuthError("Authorization header missing")

    token = credentials.credentials
    cache = CacheService(redis)
    verifier = ClerkJWTVerifier(cache)

    # Verify JWT
    claims = await verifier.verify(token)
    clerk_id: str = claims.get("sub", "")

    if not clerk_id:
        raise ClerkAuthError("Invalid token: missing sub claim")

    # Request ID for tracing
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
    request.state.clerk_id = clerk_id
    request.state.request_id = request_id

    # Try user cache
    cached_user = await cache.get_user(clerk_id)
    if cached_user:
        user_data = json.loads(cached_user)
        # We still need a full ORM object for type safety
        # Lightweight: use cache for auth check, return minimal user
        repo = UserRepository(db)
        user = await repo.get_by_clerk_id(clerk_id)
        if not user:
            raise ClerkAuthError("User not found")
        return user

    # Fetch from DB
    repo = UserRepository(db)
    user = await repo.get_by_clerk_id(clerk_id)

    if not user:
        raise ClerkAuthError("User not found. Please sync your account.")

    if not user.is_active:
        raise ClerkAuthError("Account is deactivated")

    # Cache the user
    await cache.set_user(
        clerk_id,
        json.dumps({"id": str(user.id), "clerk_id": clerk_id}),
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
