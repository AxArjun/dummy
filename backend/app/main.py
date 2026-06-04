"""
FuelIQ — Main FastAPI Application
Production-grade app factory with all middleware, routers, and lifecycle management.
"""
import json
from contextlib import asynccontextmanager
from typing import AsyncIterator

import sentry_sdk
import structlog
import firebase_admin
from firebase_admin import credentials
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from prometheus_fastapi_instrumentator import Instrumentator
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

from app.config.settings import get_settings
from app.core.cache import RedisClient
from app.core.database import dispose_engines
from app.middleware.security import (
    LoggingMiddleware,
    RateLimitMiddleware,
    RequestIDMiddleware,
    SecurityHeadersMiddleware,
)

logger = structlog.get_logger(__name__)
settings = get_settings()


# ─── Structured Logging Setup ─────────────────────────────────────────────────

structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.JSONRenderer() if settings.is_production
        else structlog.dev.ConsoleRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(
        20 if settings.is_production else 10  # INFO in prod, DEBUG in dev
    ),
    logger_factory=structlog.PrintLoggerFactory(),
)


# ─── Sentry Initialization ────────────────────────────────────────────────────

if settings.SENTRY_DSN:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        environment=settings.APP_ENV,
        traces_sample_rate=settings.SENTRY_TRACES_SAMPLE_RATE,
        profiles_sample_rate=settings.SENTRY_PROFILES_SAMPLE_RATE,
        integrations=[
            FastApiIntegration(transaction_style="endpoint"),
            SqlalchemyIntegration(),
        ],
        release=settings.APP_VERSION,
        send_default_pii=False,  # GDPR: never send PII to Sentry
    )


# ─── App Lifespan ─────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """
    Application lifecycle manager.
    Startup: validate connections, warm caches.
    Shutdown: close pools gracefully.
    """
    logger.info(
        "fueliq_starting",
        version=settings.APP_VERSION,
        environment=settings.APP_ENV,
    )
    
    # Initialize Firebase Admin SDK (single source of truth)
    try:
        cred_dict = json.loads(settings.FIREBASE_SERVICE_ACCOUNT_JSON)
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
        logger.info("firebase_admin_initialized", method="service_account")
    except (json.JSONDecodeError, KeyError) as parse_err:
        logger.warning(
            "firebase_service_account_parse_failed",
            error=str(parse_err),
            fallback="adc",
        )
        firebase_admin.initialize_app()
        logger.info("firebase_admin_initialized", method="adc_fallback")
    except ValueError:
        # Already initialized (e.g. during tests)
        pass
    except Exception as e:
        logger.error("firebase_admin_initialization_failed", error=str(e))

    # Validate DB connection
    from app.core.database import check_db_health
    db_ok = await check_db_health()
    if not db_ok:
        logger.critical("startup_db_connection_failed")
        raise RuntimeError("Database connection failed on startup")

    # Validate Redis connection
    redis = RedisClient.get_client()
    from app.core.cache import CacheService
    cache = CacheService(redis)
    redis_ok = await cache.health_check()
    if not redis_ok:
        logger.warning("startup_redis_connection_failed")  # Warning, not critical

    logger.info("fueliq_started", db=db_ok, redis=redis_ok)

    yield  # App runs here

    # Shutdown
    await dispose_engines()
    await RedisClient.close()
    logger.info("fueliq_shutdown_complete")


# ─── App Factory ──────────────────────────────────────────────────────────────

def create_application() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description="FuelIQ — Vehicle Intelligence Platform API",
        docs_url="/docs" if not settings.is_production else None,
        redoc_url="/redoc" if not settings.is_production else None,
        openapi_url="/openapi.json" if not settings.is_production else None,
        lifespan=lifespan,
    )

    # ── Middleware (order matters: outermost registered last) ──────────────────
    # TrustedHost (first security check)
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=settings.TRUSTED_HOSTS,
    )

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
        expose_headers=["X-Request-ID", "X-Response-Time", "X-RateLimit-Limit"],
    )

    # Custom middleware stack (innermost to outermost)
    app.add_middleware(SecurityHeadersMiddleware)
    app.add_middleware(LoggingMiddleware)
    app.add_middleware(RateLimitMiddleware)
    app.add_middleware(RequestIDMiddleware)

    # ── Exception Handlers ─────────────────────────────────────────────────────

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        errors = []
        for error in exc.errors():
            field = ".".join(str(loc) for loc in error["loc"] if loc != "body")
            errors.append({
                "code": "VALIDATION_ERROR",
                "message": error["msg"],
                "field": field or None,
            })
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={"success": False, "errors": errors},
        )

    @app.exception_handler(Exception)
    async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        request_id = getattr(request.state, "request_id", "unknown")
        logger.error("unhandled_exception", error=str(exc), request_id=request_id)

        if settings.is_development:
            import traceback
            detail = traceback.format_exc()
        else:
            detail = "An internal error occurred"

        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "success": False,
                "errors": [{"code": "INTERNAL_ERROR", "message": detail}],
            },
        )

    # ── Prometheus Metrics ────────────────────────────────────────────────────
    Instrumentator(
        should_group_status_codes=True,
        should_ignore_untemplated=True,
        excluded_handlers=["/health", "/metrics"],
    ).instrument(app).expose(app, endpoint="/metrics")

    # ── Routers ───────────────────────────────────────────────────────────────
    _register_routers(app)

    # ── Health Check ──────────────────────────────────────────────────────────
    @app.get("/health", tags=["health"], include_in_schema=False)
    async def health_check():
        from app.core.database import check_db_health
        from app.core.cache import CacheService

        db_ok = await check_db_health()
        redis = RedisClient.get_client()
        cache_ok = await CacheService(redis).health_check()

        status_text = "healthy" if db_ok and cache_ok else "degraded"
        http_status = 200 if db_ok else 503

        return JSONResponse(
            status_code=http_status,
            content={
                "status": status_text,
                "version": settings.APP_VERSION,
                "environment": settings.APP_ENV,
                "dependencies": {
                    "database": "ok" if db_ok else "error",
                    "cache": "ok" if cache_ok else "error",
                },
            },
        )

    return app


def _register_routers(app: FastAPI) -> None:
    """Register all API v1 routers."""
    from app.api.v1.routers import (
        auth_router,
        users_router,
        vehicles_router,
        fuel_router,
        expenses_router,
        services_router,
        analytics_router,
        notifications_router,
        ocr_router,
    )

    prefix = settings.API_V1_PREFIX

    app.include_router(auth_router.router, prefix=prefix)
    app.include_router(users_router.router, prefix=prefix)
    app.include_router(vehicles_router.router, prefix=prefix)
    app.include_router(fuel_router.router, prefix=prefix)
    app.include_router(expenses_router.router, prefix=prefix)
    app.include_router(services_router.router, prefix=prefix)
    app.include_router(analytics_router.router, prefix=prefix)
    app.include_router(notifications_router.router, prefix=prefix)
    app.include_router(ocr_router.router, prefix=prefix)


# ─── App Instance ─────────────────────────────────────────────────────────────
app = create_application()
