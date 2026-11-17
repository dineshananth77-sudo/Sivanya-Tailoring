import time
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File
from supabase_client import supabase
from routers.auth import get_current_user

router = APIRouter(
    prefix="/upload",
    tags=["Upload"]
)

ALLOWED_MIME_TYPES = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
}


@router.post("/reference-image")
async def upload_reference_image(
    file: UploadFile = File(...),
    user: dict = Depends(get_current_user)
):
    """
    Accepts multipart image file from authenticated customer.
    Uploads file to Supabase Storage ('reference-images' bucket)
    using backend service role and returns the permanent public URL.
    """
    content_type = file.content_type or ""
    if content_type.lower() not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported image type: {content_type}. Use JPEG, PNG, or WEBP."
        )

    ext = ALLOWED_MIME_TYPES[content_type.lower()]
    file_bytes = await file.read()

    # Limit to 10 MB
    if len(file_bytes) > 10 * 1024 * 1024:
        raise HTTPException(
            status_code=400,
            detail="File size exceeds maximum limit of 10MB."
        )

    customer_id = str(user["id"])
    timestamp = int(time.time() * 1000)
    file_name = f"{customer_id}/{timestamp}.{ext}"

    try:
        supabase.storage.from_("reference-images").upload(
            file_name,
            file_bytes,
            file_options={"content-type": content_type}
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to upload image to storage: {str(e)}"
        )

    # Generate public URL (bucket is public)
    public_url_resp = supabase.storage.from_("reference-images").get_public_url(file_name)
    public_url = public_url_resp if isinstance(public_url_resp, str) else public_url_resp.get("publicUrl", "")

    return {
        "message": "Image uploaded successfully",
        "file_path": file_name,
        "image_url": public_url,
    }

