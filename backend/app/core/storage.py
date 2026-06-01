"""
FuelIQ — Storage Service (MinIO/S3)
Production-grade object storage with presigned URLs and content validation.
"""
import io
import uuid
from datetime import datetime, UTC
from typing import BinaryIO

import aioboto3
import structlog
from botocore.exceptions import ClientError

from app.config.settings import get_settings

logger = structlog.get_logger(__name__)
settings = get_settings()


class StorageService:
    """
    Abstraction over MinIO/S3 for receipt and image storage.
    
    Key design decisions:
    - Presigned URLs for direct client uploads (avoids routing 10MB files through API)
    - Private bucket + presigned GET URLs for secure access
    - Organized key structure: {prefix}/{user_id}/{date}/{uuid}.{ext}
    """

    ALLOWED_CONTENT_TYPES = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
    }
    MAX_SIZE_BYTES = 10 * 1024 * 1024  # 10MB

    def __init__(self):
        self._session = aioboto3.Session(
            aws_access_key_id=settings.S3_ACCESS_KEY,
            aws_secret_access_key=settings.S3_SECRET_KEY,
        )

    def _build_key(self, prefix: str, user_id: uuid.UUID, file_id: str, ext: str) -> str:
        """
        Build a structured object key.
        Pattern: {prefix}/{user_id}/{YYYY-MM}/{file_id}{ext}
        """
        now = datetime.now(UTC)
        return f"{prefix}/{user_id}/{now.strftime('%Y-%m')}/{file_id}{ext}"

    async def generate_presigned_upload_url(
        self,
        prefix: str,
        user_id: uuid.UUID,
        content_type: str,
        *,
        file_size_limit: int | None = None,
    ) -> dict:
        """
        Generate a presigned URL for direct client-to-storage upload.
        The API never receives the file bytes — clients upload directly.
        
        Returns:
            upload_url: POST URL for the client
            object_key: Key to reference the object after upload
            fields: Form fields required for the multipart POST
        """
        if content_type not in self.ALLOWED_CONTENT_TYPES:
            raise ValueError(f"Unsupported content type: {content_type}")

        ext = self.ALLOWED_CONTENT_TYPES[content_type]
        file_id = str(uuid.uuid4())
        object_key = self._build_key(prefix, user_id, file_id, ext)

        conditions = [
            {"content-type": content_type},
            ["content-length-range", 1, file_size_limit or self.MAX_SIZE_BYTES],
        ]

        async with self._session.client(
            "s3",
            endpoint_url=settings.S3_ENDPOINT_URL,
            region_name="us-east-1",
        ) as client:
            try:
                response = await client.generate_presigned_post(
                    Bucket=settings.S3_BUCKET_NAME,
                    Key=object_key,
                    Fields={"Content-Type": content_type},
                    Conditions=conditions,
                    ExpiresIn=300,  # 5 minutes to complete upload
                )
                return {
                    "upload_url": response["url"],
                    "object_key": object_key,
                    "fields": response["fields"],
                    "expires_in": 300,
                }
            except ClientError as e:
                logger.error("presigned_upload_url_failed", error=str(e))
                raise

    async def generate_presigned_download_url(
        self, object_key: str, expiry: int | None = None
    ) -> str:
        """Generate a presigned GET URL for secure file access."""
        async with self._session.client(
            "s3",
            endpoint_url=settings.S3_ENDPOINT_URL,
            region_name="us-east-1",
        ) as client:
            try:
                url = await client.generate_presigned_url(
                    "get_object",
                    Params={"Bucket": settings.S3_BUCKET_NAME, "Key": object_key},
                    ExpiresIn=expiry or settings.S3_PRESIGNED_URL_EXPIRY,
                )
                return url
            except ClientError as e:
                logger.error("presigned_download_url_failed", key=object_key, error=str(e))
                raise

    async def upload_bytes(
        self,
        data: bytes | BinaryIO,
        prefix: str,
        user_id: uuid.UUID,
        content_type: str,
    ) -> str:
        """
        Direct upload for server-side file processing (e.g., after OCR validation).
        Returns the object key.
        """
        if content_type not in self.ALLOWED_CONTENT_TYPES:
            raise ValueError(f"Unsupported content type: {content_type}")

        ext = self.ALLOWED_CONTENT_TYPES[content_type]
        file_id = str(uuid.uuid4())
        object_key = self._build_key(prefix, user_id, file_id, ext)

        async with self._session.client(
            "s3",
            endpoint_url=settings.S3_ENDPOINT_URL,
            region_name="us-east-1",
        ) as client:
            await client.put_object(
                Bucket=settings.S3_BUCKET_NAME,
                Key=object_key,
                Body=data if isinstance(data, bytes) else data.read(),
                ContentType=content_type,
                # Server-side encryption
                ServerSideEncryption="AES256",
                # Prevent public access
                ACL="private",
            )

        logger.info("file_uploaded", key=object_key, content_type=content_type)
        return object_key

    async def delete_object(self, object_key: str) -> None:
        """Delete an object. Called when user deletes a log with a receipt."""
        async with self._session.client(
            "s3",
            endpoint_url=settings.S3_ENDPOINT_URL,
            region_name="us-east-1",
        ) as client:
            await client.delete_object(
                Bucket=settings.S3_BUCKET_NAME,
                Key=object_key,
            )
        logger.info("file_deleted", key=object_key)

    async def health_check(self) -> bool:
        """Verify storage connectivity."""
        async with self._session.client(
            "s3",
            endpoint_url=settings.S3_ENDPOINT_URL,
            region_name="us-east-1",
        ) as client:
            try:
                await client.head_bucket(Bucket=settings.S3_BUCKET_NAME)
                return True
            except Exception:
                return False
