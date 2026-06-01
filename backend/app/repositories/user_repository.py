"""
FuelIQ — User Repository
"""
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.models import User
from app.repositories.base_repository import BaseRepository


class UserRepository(BaseRepository[User]):
    def __init__(self, session: AsyncSession):
        super().__init__(User, session)

    async def get_by_clerk_id(self, clerk_id: str) -> User | None:
        stmt = select(User).where(
            User.clerk_id == clerk_id,
            User.deleted_at.is_(None),
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        stmt = select(User).where(
            User.email == email.lower(),
            User.deleted_at.is_(None),
        )
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def update_fcm_token(self, user_id: uuid.UUID, fcm_token: str) -> None:
        from datetime import datetime, UTC
        stmt = (
            select(User)
            .where(User.id == user_id)
        )
        result = await self._session.execute(stmt)
        user = result.scalar_one_or_none()
        if user:
            user.fcm_token = fcm_token
            user.fcm_token_updated_at = datetime.now(UTC)
            await self._session.flush()

    async def update_last_seen(self, user_id: uuid.UUID) -> None:
        from datetime import datetime, UTC
        result = await self._session.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()
        if user:
            user.last_seen_at = datetime.now(UTC)
