"""
FuelIQ — Security Middleware
OWASP-compliant request processing: rate limiting, security headers, request ID injection.
"""
import time
import uuid
from typing import Callable

import structlog
from fastapi import Request, Response, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint

from app.config.settings import get_settings
from app.core.cache import RedisClient, CacheService

logger = structlog.get_logger(__name__)
settings = get_settings()


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """
    Inject production-grade security headers on every response.
    OWASP: A05:2021 Security Misconfiguration mitigation.
    """

    SECURITY_HEADERS = {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "X-XSS-Protection": "1; mode=block",
        "Referrer-Policy": "strict-origin-when-cross-origin",
        "Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'",
        "Strict-Transport-Security": "max-age=31536000; includeSubDomains; preload",
        "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
        "Cache-Control": "no-store",
    }

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        response = await call_next(request)
        for header, value in self.SECURITY_HEADERS.items():
            response.headers[header] = value
        return response


class RequestIDMiddleware(BaseHTTPMiddleware):
    """
    Inject X-Request-ID header for distributed tracing.
    Uses client-provided ID if valid UUID, generates new one otherwise.
    """

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        client_id = request.headers.get("X-Request-ID", "")
        try:
            request_id = str(uuid.UUID(client_id))
        except (ValueError, AttributeError):
            request_id = str(uuid.uuid4())

        request.state.request_id = request_id

        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response


class LoggingMiddleware(BaseHTTPMiddleware):
    """
    Structured request/response logging.
    Never logs request bodies (PII risk).
    """

    # Routes excluded from logging (health checks, metrics)
    EXCLUDED_PATHS = {"/health", "/metrics", "/favicon.ico"}

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        if request.url.path in self.EXCLUDED_PATHS:
            return await call_next(request)

        start_time = time.perf_counter()

        log = logger.bind(
            request_id=getattr(request.state, "request_id", "unknown"),
            method=request.method,
            path=request.url.path,
            client_ip=request.headers.get("X-Forwarded-For", ""),
        )

        try:
            response = await call_next(request)
            duration_ms = (time.perf_counter() - start_time) * 1000

            log.info(
                "request_completed",
                status_code=response.status_code,
                duration_ms=round(duration_ms, 2),
            )
            response.headers["X-Response-Time"] = f"{duration_ms:.2f}ms"
            return response

        except Exception as e:
            duration_ms = (time.perf_counter() - start_time) * 1000
            log.error("request_failed", error=str(e), duration_ms=round(duration_ms, 2))
            raise


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Sliding window rate limiting using Redis.
    
    Limits:
    - General endpoints: 120 req/min per user or IP
    - Auth endpoints: 10 req/min per IP
    - OCR endpoints: 20 req/min per user
    
    OWASP: A04:2021 Insecure Design — rate limiting prevents brute force.
    """

    AUTH_PATHS = {"/api/v1/auth/"}
    OCR_PATHS = {"/api/v1/ocr/"}

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        # Skip health checks
        if request.url.path in {"/health", "/metrics"}:
            return await call_next(request)

        # Determine rate limit parameters
        path = request.url.path
        client_ip = request.headers.get("X-Forwarded-For", "unknown").split(",")[0].strip()

        if any(path.startswith(p) for p in self.AUTH_PATHS):
            limit = settings.RATE_LIMIT_AUTH_PER_MINUTE
            identifier = f"auth:{client_ip}"
        elif any(path.startswith(p) for p in self.OCR_PATHS):
            limit = settings.RATE_LIMIT_OCR_PER_MINUTE
            clerk_id = getattr(request.state, "clerk_id", client_ip)
            identifier = f"ocr:{clerk_id}"
        else:
            limit = settings.RATE_LIMIT_PER_MINUTE
            clerk_id = getattr(request.state, "clerk_id", client_ip)
            identifier = f"api:{clerk_id}"

        try:
            redis = RedisClient.get_client()
            cache = CacheService(redis)
            count = await cache.increment_rate_limit(identifier, window_seconds=60)

            if count > limit:
                logger.warning(
                    "rate_limit_exceeded",
                    identifier=identifier,
                    count=count,
                    limit=limit,
                    path=path,
                )
                return JSONResponse(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    content={
                        "success": False,
                        "errors": [{"code": "RATE_LIMIT_EXCEEDED", "message": "Too many requests"}],
                    },
                    headers={
                        "Retry-After": "60",
                        "X-RateLimit-Limit": str(limit),
                        "X-RateLimit-Remaining": "0",
                        "X-RateLimit-Reset": "60",
                    },
                )
        except Exception as e:
            # If Redis is down, fail open (don't block requests)
            logger.error("rate_limit_check_failed", error=str(e))

        response = await call_next(request)
        return response
