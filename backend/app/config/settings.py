"""
FuelIQ Backend — Application Configuration
Pydantic Settings v2 with layered environment support.
"""
from functools import lru_cache
from typing import Literal

from pydantic import AnyHttpUrl, PostgresDsn, RedisDsn, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Central configuration object.
    All values read from environment variables.
    Never commit actual values — use .env files locally and secrets manager in prod.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ─── App ─────────────────────────────────────────────────────────────────
    APP_NAME: str = "FuelIQ API"
    APP_VERSION: str = "1.0.0"
    APP_ENV: Literal["development", "staging", "production"] = "development"
    DEBUG: bool = False
    SECRET_KEY: str  # Used for internal signing

    # ─── API ─────────────────────────────────────────────────────────────────
    API_V1_PREFIX: str = "/api/v1"
    ALLOWED_ORIGINS: list[str] = ["http://localhost:3000"]
    TRUSTED_HOSTS: list[str] = [
        "localhost",
        "127.0.0.1",
        "192.168.1.2",
    ]

    # ─── Database ────────────────────────────────────────────────────────────
    DATABASE_URL: PostgresDsn
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 40
    DATABASE_POOL_TIMEOUT: int = 30
    DATABASE_ECHO: bool = False  # Enable SQL logging in dev only

    # Read replica (optional; falls back to primary if not set)
    DATABASE_READ_URL: PostgresDsn | None = None

    # ─── Redis ───────────────────────────────────────────────────────────────
    REDIS_URL: RedisDsn = "redis://localhost:6379/0"
    REDIS_CACHE_TTL: int = 3600  # 1 hour default
    REDIS_JWKS_TTL: int = 86400  # 24 hours
    REDIS_USER_TTL: int = 3600   # 1 hour



    # ─── MinIO / S3 ──────────────────────────────────────────────────────────
    S3_ENDPOINT_URL: str  # MinIO endpoint or AWS S3
    S3_ACCESS_KEY: str
    S3_SECRET_KEY: str
    S3_BUCKET_NAME: str = "fueliq"
    S3_RECEIPTS_PREFIX: str = "receipts"
    S3_AVATARS_PREFIX: str = "avatars"
    S3_VEHICLES_PREFIX: str = "vehicles"
    S3_PRESIGNED_URL_EXPIRY: int = 3600  # 1 hour

    # ─── Firebase ────────────────────────────────────────────────────────────
    FIREBASE_SERVICE_ACCOUNT_JSON: str  # Full JSON string of service account

    # ─── Celery ──────────────────────────────────────────────────────────────
    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"

    # ─── Sentry ──────────────────────────────────────────────────────────────
    SENTRY_DSN: str | None = None
    SENTRY_TRACES_SAMPLE_RATE: float = 0.1  # 10% in prod
    SENTRY_PROFILES_SAMPLE_RATE: float = 0.05

    # ─── Rate Limiting ───────────────────────────────────────────────────────
    RATE_LIMIT_PER_MINUTE: int = 120
    RATE_LIMIT_AUTH_PER_MINUTE: int = 10
    RATE_LIMIT_OCR_PER_MINUTE: int = 20

    # ─── Pagination ──────────────────────────────────────────────────────────
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100

    # ─── File Upload ─────────────────────────────────────────────────────────
    MAX_UPLOAD_SIZE_MB: int = 10
    ALLOWED_IMAGE_TYPES: list[str] = ["image/jpeg", "image/png", "image/webp"]

    # ─── Analytics ───────────────────────────────────────────────────────────
    ANALYTICS_CACHE_TTL: int = 3600  # 1 hour
    MATERIALIZED_VIEW_REFRESH_INTERVAL: int = 300  # 5 minutes

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_origins(cls, v: str | list) -> list[str]:
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",")]
        return v

    @property
    def is_production(self) -> bool:
        return self.APP_ENV == "production"

    @property
    def is_development(self) -> bool:
        return self.APP_ENV == "development"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """
    Cached settings instance.
    Use as FastAPI dependency: Depends(get_settings)
    """
    return Settings()
