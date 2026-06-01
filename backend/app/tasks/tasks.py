"""
FuelIQ — Celery Task Definitions
All background task implementations.
"""
import asyncio
from datetime import datetime, timedelta, UTC

import structlog
from celery import shared_task
from sqlalchemy import select, and_, text, update

from app.tasks.celery_app import celery_app
from app.core.database import get_session_context
from app.models.models import Reminder, ReminderStatus, Vehicle, User
from app.modules.notifications.notification_service import NotificationService, FCMService

logger = structlog.get_logger(__name__)


def run_async(coro):
    """Helper to run async code in Celery sync context."""
    loop = asyncio.new_event_loop()
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


@celery_app.task(
    bind=True,
    max_retries=3,
    default_retry_delay=300,
    name="app.tasks.tasks.check_service_reminders",
)
def check_service_reminders(self):
    """
    Scheduled task: check for due/overdue reminders and send push notifications.
    Runs daily at 08:00 UTC.
    
    Query: Find all reminders due within the next 7 days OR overdue,
    where notification hasn't been sent yet.
    """
    logger.info("check_service_reminders_started")
    
    async def _run():
        async with get_session_context(write=True) as session:
            now = datetime.now(UTC)
            seven_days_ahead = now + timedelta(days=7)
            
            # Fetch due/overdue reminders with user FCM tokens
            stmt = select(Reminder).join(
                Vehicle, Reminder.vehicle_id == Vehicle.id
            ).join(
                User, Vehicle.user_id == User.id
            ).where(
                and_(
                    Reminder.status == ReminderStatus.PENDING,
                    Reminder.notification_sent == False,
                    Reminder.deleted_at.is_(None),
                    Reminder.reminder_type == "date_based",
                    Reminder.remind_at <= seven_days_ahead,
                )
            ).with_for_update(skip_locked=True)  # Skip locked rows for parallel workers

            result = await session.execute(stmt)
            reminders = result.scalars().all()
            
            logger.info("reminders_found", count=len(reminders))
            
            fcm_service = FCMService()
            notif_service = NotificationService(session, fcm_service)
            sent_count = 0
            
            for reminder in reminders:
                try:
                    # Get vehicle and user
                    vehicle_result = await session.execute(
                        select(Vehicle).where(Vehicle.id == reminder.vehicle_id)
                    )
                    vehicle = vehicle_result.scalar_one_or_none()
                    if not vehicle:
                        continue
                    
                    user_result = await session.execute(
                        select(User).where(User.id == vehicle.user_id)
                    )
                    user = user_result.scalar_one_or_none()
                    if not user or not user.is_active:
                        continue
                    
                    is_overdue = reminder.remind_at < now
                    vehicle_name = f"{vehicle.year} {vehicle.make} {vehicle.model}"
                    
                    await notif_service.send_service_reminder(
                        user_id=user.id,
                        fcm_token=user.fcm_token,
                        reminder=reminder,
                        vehicle_name=vehicle_name,
                        is_overdue=is_overdue,
                    )
                    
                    # Mark reminder as notified
                    reminder.notification_sent = True
                    reminder.notification_sent_at = now
                    if is_overdue:
                        reminder.status = ReminderStatus.OVERDUE
                    else:
                        reminder.status = ReminderStatus.NOTIFIED
                    
                    sent_count += 1
                    
                except Exception as e:
                    logger.error(
                        "reminder_notification_failed",
                        reminder_id=str(reminder.id),
                        error=str(e),
                    )

            logger.info("reminders_processed", sent=sent_count, total=len(reminders))
            return sent_count

    try:
        return run_async(_run())
    except Exception as exc:
        logger.error("check_service_reminders_failed", error=str(exc))
        raise self.retry(exc=exc)


@celery_app.task(name="app.tasks.tasks.refresh_vehicle_stats")
def refresh_vehicle_stats():
    """
    Refresh the vehicle_stats materialized view.
    Runs every 5 minutes. Uses CONCURRENTLY to avoid locking.
    """
    async def _run():
        async with get_session_context(write=True) as session:
            await session.execute(
                text("REFRESH MATERIALIZED VIEW CONCURRENTLY vehicle_stats")
            )
            logger.info("vehicle_stats_refreshed")

    try:
        run_async(_run())
    except Exception as e:
        logger.error("refresh_vehicle_stats_failed", error=str(e))


@celery_app.task(name="app.tasks.tasks.send_weekly_summaries")
def send_weekly_summaries():
    """
    Send weekly fuel summary notifications to active users.
    Runs Mondays at 09:00 UTC.
    """
    async def _run():
        async with get_session_context(write=False) as session:
            # Get users with fuel logs in the last 7 days
            stmt = text("""
                SELECT
                    u.id,
                    u.fcm_token,
                    u.display_name,
                    v.make || ' ' || v.model AS vehicle_name,
                    v.id AS vehicle_id,
                    COUNT(fl.id) AS fill_count,
                    COALESCE(SUM(fl.total_cost), 0) AS total_cost
                FROM users u
                JOIN vehicles v ON v.user_id = u.id
                JOIN fuel_logs fl ON fl.vehicle_id = v.id
                WHERE fl.filled_at >= NOW() - INTERVAL '7 days'
                  AND fl.deleted_at IS NULL
                  AND u.is_active = true
                  AND u.fcm_token IS NOT NULL
                  AND u.deleted_at IS NULL
                GROUP BY u.id, u.fcm_token, u.display_name, v.make, v.model, v.id
                HAVING COUNT(fl.id) > 0
                LIMIT 10000
            """)

            result = await session.execute(stmt)
            rows = result.mappings().all()
            
            fcm = FCMService()
            
            for row in rows:
                try:
                    from app.modules.notifications.notification_service import NotificationPayload
                    payload = NotificationPayload.weekly_summary(
                        vehicle_name=row["vehicle_name"],
                        total_cost=float(row["total_cost"]),
                        fill_count=row["fill_count"],
                    )
                    await fcm.send_to_device(
                        fcm_token=row["fcm_token"],
                        title=payload["title"],
                        body=payload["body"],
                    )
                except Exception as e:
                    logger.warning("weekly_summary_send_failed", user_id=str(row["id"]), error=str(e))

    run_async(_run())


@celery_app.task(name="app.tasks.tasks.cleanup_soft_deleted_records")
def cleanup_soft_deleted_records():
    """
    Hard-delete records that were soft-deleted > 90 days ago.
    Runs daily at 02:00 UTC.
    """
    async def _run():
        async with get_session_context(write=True) as session:
            cutoff = text("""
                DELETE FROM fuel_logs WHERE deleted_at < NOW() - INTERVAL '90 days';
                DELETE FROM expenses WHERE deleted_at < NOW() - INTERVAL '90 days';
                DELETE FROM service_records WHERE deleted_at < NOW() - INTERVAL '90 days';
                DELETE FROM reminders WHERE deleted_at < NOW() - INTERVAL '90 days';
            """)
            await session.execute(cutoff)
            logger.info("soft_delete_cleanup_completed")

    run_async(_run())


@celery_app.task(name="app.tasks.tasks.send_push_notification")
def send_push_notification(fcm_token: str, title: str, body: str, data: dict = None):
    """
    Generic fire-and-forget push notification task.
    Used for immediate/on-demand notifications from API layer.
    """
    async def _run():
        fcm = FCMService()
        await fcm.send_to_device(fcm_token, title, body, data)
    
    run_async(_run())
