"""FuelIQ — OCR Router
Presigned upload URL generation and receipt registration.
On-device OCR (ML Kit) processes the image — the API stores the result.
"""
import uuid
from typing import Annotated
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import CurrentUser
from app.core.storage import StorageService
from app.config.settings import get_settings
from app.schemas.schemas import APIResponse, PresignedUploadResponse, OCRUploadResponse

router = APIRouter(prefix="/ocr", tags=["ocr"])
settings = get_settings()


@router.post(
    "/presigned-receipt-upload",
    response_model=APIResponse[PresignedUploadResponse],
    summary="Get presigned URL for direct receipt upload",
    description="""
    Returns a presigned S3/MinIO URL for the Flutter client to upload a receipt image directly.
    Avoids routing large files through the API server.
    The client uploads directly to storage, then includes the object_key in the fuel log creation request.
    """,
)
async def get_presigned_receipt_upload(
    current_user: CurrentUser,
    content_type: str = Query(
        default="image/jpeg",
        regex="^(image/jpeg|image/png|image/webp)$",
        description="MIME type of the image to upload",
    ),
) -> APIResponse[PresignedUploadResponse]:
    storage = StorageService()
    result = await storage.generate_presigned_upload_url(
        prefix=settings.S3_RECEIPTS_PREFIX,
        user_id=current_user.id,
        content_type=content_type,
    )
    return APIResponse(
        data=PresignedUploadResponse(
            upload_url=result["upload_url"],
            object_key=result["object_key"],
            expires_in=result["expires_in"],
        ),
        message="Upload URL generated. Valid for 5 minutes.",
    )


@router.post(
    "/presigned-avatar-upload",
    response_model=APIResponse[PresignedUploadResponse],
    summary="Get presigned URL for avatar image upload",
)
async def get_presigned_avatar_upload(
    current_user: CurrentUser,
    content_type: str = Query(default="image/jpeg"),
) -> APIResponse[PresignedUploadResponse]:
    storage = StorageService()
    result = await storage.generate_presigned_upload_url(
        prefix=settings.S3_AVATARS_PREFIX,
        user_id=current_user.id,
        content_type=content_type,
        file_size_limit=2 * 1024 * 1024,  # 2MB limit for avatars
    )
    return APIResponse(
        data=PresignedUploadResponse(
            upload_url=result["upload_url"],
            object_key=result["object_key"],
            expires_in=result["expires_in"],
        ),
    )
