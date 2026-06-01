"""
FuelIQ — Celery Application + Task Definitions
Background worker for reminders, analytics refresh, and cleanup jobs.
"""
import uuid
from datetime import datetime, timedelta, UTC

import structlog
from celery import Celery
from celery.schedules import crontab

from app.config.settings import get_settings

logger = structlog.get_logger(__name__)
settings = get_settings()


# ─── Celery App Configuration ─────────────────────────────────────────────────

celery_app = Celery(
    "fueliq",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=["app.tasks.tasks"],
)

celery_app.conf.update(
    # Serialization
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    
    # Timezone
    timezone="UTC",
    enable_utc=True,
    
    # Reliability
    task_acks_late=True,          # Acknowledge after completion, not receipt
    task_reject_on_worker_lost=True,
    worker_prefetch_multiplier=1, # One task at a time per worker for fair distribution
    
    # Retry behavior
    task_max_retries=3,
    task_default_retry_delay=60,  # 60s between retries
    
    # Result expiry
    result_expires=3600,          # 1 hour
    
    # Beat schedule (periodic tasks)
    beat_schedule={
        # Check for due reminders daily at 08:00 UTC (13:30 IST)
        "check-service-reminders": {
            "task": "app.tasks.tasks.check_service_reminders",
            "schedule": crontab(hour=8, minute=0),
            "options": {"queue": "reminders"},
        },
        # Refresh materialized views every 5 minutes
        "refresh-vehicle-stats": {
            "task": "app.tasks.tasks.refresh_vehicle_stats",
            "schedule": crontab(minute="*/5"),
            "options": {"queue": "analytics"},
        },
        # Weekly summary notifications (Monday 09:00 UTC)
        "send-weekly-summaries": {
            "task": "app.tasks.tasks.send_weekly_summaries",
            "schedule": crontab(day_of_week=1, hour=9, minute=0),
            "options": {"queue": "notifications"},
        },
        # Cleanup soft-deleted records older than 90 days (daily at 02:00 UTC)
        "cleanup-soft-deleted": {
            "task": "app.tasks.tasks.cleanup_soft_deleted_records",
            "schedule": crontab(hour=2, minute=0),
            "options": {"queue": "maintenance"},
        },
    },
    
    # Queues
    task_routes={
        "app.tasks.tasks.check_service_reminders": {"queue": "reminders"},
        "app.tasks.tasks.refresh_vehicle_stats": {"queue": "analytics"},
        "app.tasks.tasks.send_weekly_summaries": {"queue": "notifications"},
        "app.tasks.tasks.cleanup_soft_deleted_records": {"queue": "maintenance"},
        "app.tasks.tasks.send_push_notification": {"queue": "notifications"},
    },
)
