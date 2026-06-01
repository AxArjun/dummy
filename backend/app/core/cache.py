"""
FuelIQ — Redis Cache Client
Thread-safe async Redis client with connection pooling and typed helpers.
"""
from typing import Any
from datetime import timedelta

import structlog
from redis.asyncio import Redis, ConnectionPool
from redis.asyncio.retry import Retry
from redis.backoff import ExponentialBackoff
from redis.exceptions import RedisError

from app.config.settings import get_settings

logger = structlog.get_logger(__name__)
settings = get_settings()


class RedisClient:
    """
    Singleton Redis client wrapper.
    Provides typed get/set operations with serialization.
    """

    _pool: ConnectionPool | None = None
    _client: Redis | None = None

    @classmethod
    def _get_pool(cls) -> ConnectionPool:
        if cls._pool is None:
            retry = Retry(ExponentialBackoff(), 3)
            cls._pool = ConnectionPool.from_url(
                str(settings.REDIS_URL),
                encoding="utf-8",
                decode_responses=True,
                max_connections=50,
                retry=retry,
                retry_on_error=[ConnectionError, TimeoutError],
                socket_connect_timeout=5,
                socket_timeout=5,
            )
        return cls._pool

    @classmethod
    def get_client(cls) -> Redis:
        if cls._client is None:
            cls._client = Redis(connection_pool=cls._get_pool())
        return cls._client

    @classmethod
    async def close(cls) -> None:
        if cls._client:
            await cls._client.aclose()
            cls._client = None
        if cls._pool:
            await cls._pool.aclose()
            cls._pool = None


def get_redis() -> Redis:
    """FastAPI dependency for Redis client."""
    return RedisClient.get_client()


class CacheService:
    """
    High-level cache operations with structured key management.
    Keys follow the pattern: fueliq:{namespace}:{identifier}
    """

    PREFIX = "fueliq"

    def __init__(self, redis: Redis):
        self._redis = redis

    def _key(self, namespace: str, identifier: str) -> str:
        return f"{self.PREFIX}:{namespace}:{identifier}"

    # ─── JWKS ─────────────────────────────────────────────────────────────────

    async def get_jwks(self) -> str | None:
        return await self._redis.get(self._key("jwks", "clerk"))

    async def set_jwks(self, jwks_data: str) -> None:
        await self._redis.setex(
            self._key("jwks", "clerk"),
            settings.REDIS_JWKS_TTL,
            jwks_data,
        )

    # ─── User ─────────────────────────────────────────────────────────────────

    async def get_user(self, user_id: str) -> str | None:
        return await self._redis.get(self._key("user", user_id))

    async def set_user(self, user_id: str, data: str) -> None:
        await self._redis.setex(self._key("user", user_id), settings.REDIS_USER_TTL, data)

    async def invalidate_user(self, user_id: str) -> None:
        await self._redis.delete(self._key("user", user_id))

    # ─── Vehicle Stats ────────────────────────────────────────────────────────

    async def get_vehicle_stats(self, vehicle_id: str) -> str | None:
        return await self._redis.get(self._key("vehicle_stats", vehicle_id))

    async def set_vehicle_stats(self, vehicle_id: str, data: str) -> None:
        await self._redis.setex(
            self._key("vehicle_stats", vehicle_id),
            settings.ANALYTICS_CACHE_TTL,
            data,
        )

    async def invalidate_vehicle_stats(self, vehicle_id: str) -> None:
        await self._redis.delete(self._key("vehicle_stats", vehicle_id))

    # ─── Analytics ────────────────────────────────────────────────────────────

    async def get_analytics(self, vehicle_id: str, period: str) -> str | None:
        return await self._redis.get(self._key("analytics", f"{vehicle_id}:{period}"))

    async def set_analytics(self, vehicle_id: str, period: str, data: str) -> None:
        await self._redis.setex(
            self._key("analytics", f"{vehicle_id}:{period}"),
            settings.ANALYTICS_CACHE_TTL,
            data,
        )

    async def invalidate_vehicle_analytics(self, vehicle_id: str) -> None:
        """Invalidate all analytics cache entries for a vehicle."""
        pattern = self._key("analytics", f"{vehicle_id}:*")
        keys = await self._redis.keys(pattern)
        if keys:
            await self._redis.delete(*keys)

    # ─── Rate Limiting ────────────────────────────────────────────────────────

    async def increment_rate_limit(
        self, identifier: str, window_seconds: int = 60
    ) -> int:
        """
        Sliding window rate limit counter.
        Returns current count for the window.
        """
        key = self._key("ratelimit", identifier)
        pipe = self._redis.pipeline()
        await pipe.incr(key)
        await pipe.expire(key, window_seconds)
        results = await pipe.execute()
        return results[0]

    # ─── Generic ──────────────────────────────────────────────────────────────

    async def get(self, key: str) -> str | None:
        try:
            return await self._redis.get(key)
        except RedisError as e:
            logger.warning("cache_get_failed", key=key, error=str(e))
            return None

    async def set(
        self,
        key: str,
        value: str,
        ttl: int | None = None,
    ) -> None:
        try:
            if ttl:
                await self._redis.setex(key, ttl, value)
            else:
                await self._redis.set(key, value)
        except RedisError as e:
            logger.warning("cache_set_failed", key=key, error=str(e))

    async def delete(self, key: str) -> None:
        try:
            await self._redis.delete(key)
        except RedisError as e:
            logger.warning("cache_delete_failed", key=key, error=str(e))

    async def health_check(self) -> bool:
        try:
            await self._redis.ping()
            return True
        except RedisError:
            return False
