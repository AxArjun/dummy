"""
FuelIQ — Notification Service + FCM Integration
Firebase Cloud Messaging push notifications with fallback handling.
"""
import uuid
from datetime import datetime, UTC
from typing import Any

import structlog
from firebase_admin import messaging
from firebase_admin.exceptions import FirebaseError

from app.config.settings import get_settings
from app.models.models import Notification, NotificationType, Reminder
from app.repositories.base_repository import BaseRepository

logger = structlog.get_logger(__name__)
settings = get_settings()


class NotificationPayload:
    """Structured notification content."""

    @staticmethod
    def service_reminder(reminder: Reminder, vehicle_name: str) -> dict:
        return {
            "title": f"🔧 Service Due: {reminder.title}",
            "body": f"Your {vehicle_name} is due for {reminder.title}. "
                    f"Schedule service to keep your vehicle in top condition.",
            "action_url": f"/garage/{reminder.vehicle_id}/reminders/{reminder.id}",
        }

    @staticmethod
    def service_overdue(reminder: Reminder, vehicle_name: str) -> dict:
        return {
            "title": f"⚠️ Overdue: {reminder.title}",
            "body": f"Your {vehicle_name} is overdue for {reminder.title}. "
                    f"Please schedule service immediately.",
            "action_url": f"/garage/{reminder.vehicle_id}/reminders/{reminder.id}",
        }

    @staticmethod
    def weekly_summary(
        vehicle_name: str,
        total_cost: float,
        fill_count: int,
        currency: str = "₹",
    ) -> dict:
        return {
            "title": f"📊 Weekly Summary — {vehicle_name}",
            "body": f"This week: {fill_count} fill{'s' if fill_count != 1 else ''}, "
                    f"{currency}{total_cost:.0f} spent on fuel.",
            "action_url": "/analytics",
        }


class FCMService:
    """
    Firebase Cloud Messaging service.
    Handles single-device and topic-based push notifications.
    """

    def __init__(self):
        # Firebase Admin SDK is initialized in app lifespan (main.py)
        pass

    async def send_to_device(
        self,
        fcm_token: str,
        title: str,
        body: str,
        data: dict[str, str] | None = None,
        *,
        image_url: str | None = None,
    ) -> str | None:
        """
        Send a notification to a specific device.
        Returns FCM message ID on success, None on failure (non-critical path).
        """
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                    image=image_url,
                ),
                data={k: str(v) for k, v in (data or {}).items()},
                token=fcm_token,
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        icon="ic_notification",
                        color="#1E88E5",
                        sound="default",
                        channel_id="fueliq_reminders",
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            alert=messaging.ApsAlert(title=title, body=body),
                            badge=1,
                            sound="default",
                        )
                    )
                ),
            )

            message_id = messaging.send(message)
            logger.info("fcm_sent", message_id=message_id)
            return message_id

        except messaging.UnregisteredError:
            logger.warning("fcm_token_unregistered", token=fcm_token[:20])
            return None
        except FirebaseError as e:
            logger.error("fcm_send_failed", error=str(e), token=fcm_token[:20])
            return None
        except Exception as e:
            logger.error("fcm_unexpected_error", error=str(e))
            return None


class NotificationService:
    """
    High-level notification orchestration.
    Creates DB record + sends FCM push (best-effort, non-blocking).
    """

    def __init__(self, session, fcm_service: FCMService | None = None):
        self._session = session
        self._fcm = fcm_service or FCMService()
        self._repo = BaseRepository(Notification, session)

    async def send_service_reminder(
        self,
        user_id: uuid.UUID,
        fcm_token: str | None,
        reminder: Reminder,
        vehicle_name: str,
        is_overdue: bool = False,
    ) -> Notification:
        """
        Send service reminder push notification.
        1. Create notification DB record
        2. Send FCM (best-effort)
        3. Update notification with FCM message ID
        """
        payload_fn = (
            NotificationPayload.service_overdue
            if is_overdue
            else NotificationPayload.service_reminder
        )
        payload = payload_fn(reminder, vehicle_name)

        notification_type = (
            NotificationType.SERVICE_OVERDUE
            if is_overdue
            else NotificationType.SERVICE_REMINDER
        )

        # Create DB record
        notification = await self._repo.create({
            "user_id": user_id,
            "notification_type": notification_type,
            "title": payload["title"],
            "body": payload["body"],
            "action_url": payload["action_url"],
            "meta_data": {
                "reminder_id": str(reminder.id),
                "vehicle_id": str(reminder.vehicle_id),
                "service_type": reminder.service_type.value if reminder.service_type else None,
            },
        })

        # Send FCM (non-blocking failure)
        if fcm_token:
            message_id = await self._fcm.send_to_device(
                fcm_token=fcm_token,
                title=payload["title"],
                body=payload["body"],
                data={
                    "notification_id": str(notification.id),
                    "action_url": payload["action_url"],
                    "type": notification_type.value,
                },
            )

            if message_id:
                notification.fcm_message_id = message_id
                notification.delivered_at = datetime.now(UTC)

        return notification

    async def mark_all_read(self, user_id: uuid.UUID) -> int:
        """Mark all unread notifications as read. Returns count updated."""
        from sqlalchemy import update, and_
        from app.models.models import Notification as NotifModel

        stmt = (
            update(NotifModel)
            .where(
                and_(
                    NotifModel.user_id == user_id,
                    NotifModel.is_read == False,
                )
            )
            .values(is_read=True, read_at=datetime.now(UTC))
        )
        result = await self._session.execute(stmt)
        return result.rowcount
