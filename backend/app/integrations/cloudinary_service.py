import io
from typing import Dict, Any, Optional
import cloudinary
import cloudinary.uploader
import cloudinary.api

from app.config import get_settings
from app.exceptions import BadRequestException, InternalServerErrorException

settings = get_settings()


# Initialize Cloudinary SDK
if settings.CLOUDINARY_CLOUD_NAME and settings.CLOUDINARY_API_KEY and settings.CLOUDINARY_API_SECRET:
    cloudinary.config(
        cloud_name=settings.CLOUDINARY_CLOUD_NAME,
        api_key=settings.CLOUDINARY_API_KEY,
        api_secret=settings.CLOUDINARY_API_SECRET,
        secure=True,
    )

MAX_IMAGE_BYTES = 5 * 1024 * 1024  # 5 MB
ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}


def validate_image_file(file_bytes: bytes, content_type: Optional[str] = None) -> str:
    """
    Validates file size, MIME type and magic header bytes.
    Returns the detected image format ('jpg', 'png', 'webp').
    """
    if not file_bytes:
        raise BadRequestException("Image file is empty", code="IMAGE_EMPTY")

    if len(file_bytes) > MAX_IMAGE_BYTES:
        raise BadRequestException(
            f"Image file exceeds maximum allowed size of 5 MB ({len(file_bytes)} bytes)",
            code="IMAGE_SIZE_EXCEEDED",
        )

    # Magic byte inspection
    format_detected: Optional[str] = None
    if file_bytes.startswith(b"\xFF\xD8\xFF"):
        format_detected = "jpg"
    elif file_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
        format_detected = "png"
    elif file_bytes.startswith(b"RIFF") and len(file_bytes) > 12 and file_bytes[8:12] == b"WEBP":
        format_detected = "webp"

    if not format_detected:
        raise BadRequestException(
            "Invalid image file format. Only JPEG, PNG, and WebP are allowed.",
            code="INVALID_IMAGE_FORMAT",
        )

    if content_type:
        expected_types = {
            "jpg": ["image/jpeg", "image/jpg", "application/octet-stream"],
            "png": ["image/png", "application/octet-stream"],
            "webp": ["image/webp", "application/octet-stream"],
        }
        if content_type.lower() not in expected_types.get(format_detected, []):
            raise BadRequestException(
                f"Content-Type '{content_type}' does not match detected image format '{format_detected}'.",
                code="MIME_TYPE_MISMATCH",
            )

    return format_detected


def upload_product_image(
    file_bytes: bytes,
    product_id: str,
    content_type: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Validates and uploads an image to Cloudinary in folder 'stitch_style/products/<product_id>'.
    Returns metadata dict.
    """
    detected_format = validate_image_file(file_bytes, content_type)

    folder_path = f"stitch_style/products/{product_id}"

    try:
        response = cloudinary.uploader.upload(
            file_bytes,
            folder=folder_path,
            resource_type="image",
            overwrite=False,
            unique_filename=True,
        )
    except Exception as exc:
        raise InternalServerErrorException(
            f"Failed to upload image to Cloudinary: {str(exc)}",
            code="CLOUDINARY_UPLOAD_FAILED",
        )

    secure_url = response.get("secure_url") or response.get("url")
    public_id = response.get("public_id")
    asset_id = response.get("asset_id")
    width = response.get("width", 0)
    height = response.get("height", 0)
    format_returned = response.get("format", detected_format)
    bytes_size = response.get("bytes", len(file_bytes))

    return {
        "cloudinary_url": secure_url,
        "cloudinary_public_id": public_id,
        "cloudinary_asset_id": asset_id,
        "width": width,
        "height": height,
        "format": format_returned,
        "bytes_size": bytes_size,
    }


def delete_cloudinary_image(public_id: str) -> bool:
    """
    Safely deletes an asset from Cloudinary by public ID.
    """
    if not public_id:
        return False
    try:
        res = cloudinary.uploader.destroy(public_id, resource_type="image", invalidate=True)
        return res.get("result") in ("ok", "not found")
    except Exception:
        # Avoid crashing when cleaning up; logging will capture
        return False
