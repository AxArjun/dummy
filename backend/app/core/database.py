"""
FuelIQ — SQLAlchemy Database Engine Configuration
Async engine with connection pooling, read replica routing, and health checks.
"""
from contextlib import asynccontextmanager
from typing import AsyncGenerator, AsyncIterator

import structlog
import sqlalchemy as sa
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.pool import NullPool

from app.config.settings import get_settings

logger = structlog.get_logger(__name__)
settings = get_settings()


class Base(DeclarativeBase):
    """
    SQLAlchemy declarative base.
    All ORM models inherit from this.
    """
    pass


def _build_async_url(url: str) -> str:
    """Convert postgresql:// to postgresql+asyncpg://"""
    return str(url).replace("postgresql://", "postgresql+asyncpg://").replace(
        "postgres://", "postgresql+asyncpg://"
    )


def _create_engine(url: str, *, is_read_replica: bool = False) -> AsyncEngine:
    """
    Factory for async SQLAlchemy engines.
    Read replicas use a separate pool configuration.
    """
    pool_class = NullPool if settings.APP_ENV == "testing" else None

    kwargs = {
        "echo": settings.DATABASE_ECHO and not settings.is_production,
        "pool_pre_ping": True,  # Validate connections before use
        "pool_recycle": 3600,   # Recycle connections every hour
    }

    if pool_class:
        kwargs["poolclass"] = pool_class
    else:
        # Production pool config
        pool_size = settings.DATABASE_POOL_SIZE // 2 if is_read_replica else settings.DATABASE_POOL_SIZE
        kwargs.update(
            {
                "pool_size": pool_size,
                "max_overflow": settings.DATABASE_MAX_OVERFLOW,
                "pool_timeout": settings.DATABASE_POOL_TIMEOUT,
            }
        )

    return create_async_engine(_build_async_url(url), **kwargs)


# Primary write engine
_write_engine: AsyncEngine = _create_engine(str(settings.DATABASE_URL))

# Read replica engine (falls back to primary if not configured)
_read_engine: AsyncEngine = (
    _create_engine(str(settings.DATABASE_READ_URL), is_read_replica=True)
    if settings.DATABASE_READ_URL
    else _write_engine
)

# Session factories
WriteSessionFactory = async_sessionmaker(
    bind=_write_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)

ReadSessionFactory = async_sessionmaker(
    bind=_read_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)


async def get_write_session() -> AsyncGenerator[AsyncSession, None]:
    """
    FastAPI dependency for write database sessions.
    Provides transactional context — commits on success, rolls back on exception.
    
    Usage:
        async def my_endpoint(db: AsyncSession = Depends(get_write_session)):
    """
    async with WriteSessionFactory() as session:
        try:
            yield session
            await session.commit()
        except SQLAlchemyError as e:
            await session.rollback()
            logger.error("database_write_error", error=str(e))
            raise
        finally:
            await session.close()


async def get_read_session() -> AsyncGenerator[AsyncSession, None]:
    """
    FastAPI dependency for read-only database sessions.
    Routes to read replica when configured.
    
    Usage:
        async def my_endpoint(db: AsyncSession = Depends(get_read_session)):
    """
    async with ReadSessionFactory() as session:
        try:
            yield session
        except SQLAlchemyError as e:
            logger.error("database_read_error", error=str(e))
            raise
        finally:
            await session.close()


@asynccontextmanager
async def get_session_context(*, write: bool = True) -> AsyncIterator[AsyncSession]:
    """
    Context manager for background tasks / Celery workers.
    Not a FastAPI dependency.
    """
    factory = WriteSessionFactory if write else ReadSessionFactory
    async with factory() as session:
        try:
            yield session
            if write:
                await session.commit()
        except SQLAlchemyError:
            if write:
                await session.rollback()
            raise
        finally:
            await session.close()


async def check_db_health() -> bool:
    """Health check for the database connection."""
    try:
        async with WriteSessionFactory() as session:
            await session.execute(sa.text("SELECT 1"))
        return True
    except Exception as e:
        logger.error("db_health_check_failed", error=str(e))
        return False


async def dispose_engines() -> None:
    """Gracefully close all DB connections. Called on app shutdown."""
    await _write_engine.dispose()
    if _read_engine is not _write_engine:
        await _read_engine.dispose()
    logger.info("database_engines_disposed")
