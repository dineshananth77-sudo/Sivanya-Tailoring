from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field

from supabase_client import supabase
from routers.auth import get_current_user

router = APIRouter(
    prefix="/measurements",
    tags=["Measurements"]
)

# Outfit-specific measurement field templates
OUTFIT_MEASUREMENT_FIELDS = {
    "Blouse": [
        "bust", "waist", "shoulder", "sleeve_length", "armhole", "blouse_length"
    ],
    "Kurti": [
        "bust", "waist", "hip", "shoulder", "sleeve_length", "kurti_length"
    ],
    "Lehenga": [
        "waist", "hip", "lehenga_length"
    ],
    "Salwar Suit": [
        "bust", "waist", "hip", "shoulder", "sleeve_length", "suit_length"
    ],
    "Dress": [
        "bust", "waist", "hip", "shoulder", "dress_length"
    ],
    "Saree": [
        "blouse_bust", "blouse_waist", "petticoat_waist", "petticoat_length"
    ],
    "General": [
        "chest", "bust", "waist", "hip", "shoulder", "length"
    ]
}


class MeasurementUpdateRequest(BaseModel):
    measurements: dict[str, Any] = Field(
        ...,
        description="Key-value dictionary of measurements (e.g. {'chest': '36', 'waist': '30'})"
    )
    outfit_type: str | None = Field(
        None,
        description="Optional outfit category (e.g. Blouse, Kurti, Lehenga)"
    )


# 1. Get standard measurement fields for outfit types
@router.get("/outfit-fields")
def get_outfit_measurement_fields():
    """
    Returns standard measurement fields required for each outfit type.
    """
    return {
        "outfits": list(OUTFIT_MEASUREMENT_FIELDS.keys()),
        "fields": OUTFIT_MEASUREMENT_FIELDS
    }


# 2. Get current customer's saved measurements (JWT-protected)
@router.get("/")
def get_my_measurements(
    user: dict = Depends(get_current_user)
):
    """
    Fetches the saved measurements for the authenticated customer.
    Returns empty measurements map if none have been saved yet.
    """
    customer_id = str(user["id"])

    response = (
        supabase.table("customer_measurements")
        .select("id, user_id, measurements, updated_at")
        .eq("user_id", customer_id)
        .execute()
    )

    if not response.data:
        return {
            "user_id": customer_id,
            "measurements": {},
            "updated_at": None
        }

    record = response.data[0]
    return {
        "id": record.get("id"),
        "user_id": record.get("user_id"),
        "measurements": record.get("measurements") or {},
        "updated_at": record.get("updated_at")
    }


# 3. Save or update customer's measurements (JWT-protected)
@router.put("/")
def save_my_measurements(
    payload: MeasurementUpdateRequest,
    user: dict = Depends(get_current_user)
):
    """
    Upserts body measurements for the authenticated customer.
    Merges new values with previously saved values so partial updates do not erase existing data.
    """
    customer_id = str(user["id"])
    new_measurements = payload.measurements

    # Sanitize measurement values: remove empty entries, clean whitespace
    clean_new_measurements: dict[str, Any] = {}
    for key, value in new_measurements.items():
        if value is not None:
            clean_str = str(value).strip()
            if clean_str:
                # Normalize keys (lowercase and underscore)
                normalized_key = key.strip().lower().replace(" ", "_")
                clean_new_measurements[normalized_key] = clean_str

    if not clean_new_measurements:
        raise HTTPException(
            status_code=400,
            detail="At least one valid measurement must be provided."
        )

    # Fetch existing measurements to merge
    existing = (
        supabase.table("customer_measurements")
        .select("id, measurements")
        .eq("user_id", customer_id)
        .execute()
    )

    merged_measurements: dict[str, Any] = {}
    if existing.data:
        existing_record = existing.data[0]
        existing_data = existing_record.get("measurements") or {}
        if isinstance(existing_data, dict):
            merged_measurements.update(existing_data)

    # Apply new values
    merged_measurements.update(clean_new_measurements)

    now_utc = datetime.now(timezone.utc).isoformat()

    upsert_data = {
        "user_id": customer_id,
        "measurements": merged_measurements,
        "updated_at": now_utc
    }

    try:
        response = (
            supabase.table("customer_measurements")
            .upsert(upsert_data, on_conflict="user_id")
            .execute()
        )
    except Exception as error:
        error_msg = str(error)
        if "customer_measurements_user_id_fkey" in error_msg:
            raise HTTPException(
                status_code=500,
                detail="Database constraint error: customer_measurements.user_id must reference public.customers(id). Please run the provided SQL migration in Supabase SQL editor."
            )
        raise HTTPException(
            status_code=500,
            detail=f"Failed to save measurements: {error_msg}"
        )

    if not response.data:
        raise HTTPException(
            status_code=500,
            detail="Failed to save measurements."
        )

    saved_record = response.data[0]

    return {
        "message": "Measurements saved successfully",
        "user_id": customer_id,
        "measurements": saved_record.get("measurements") or merged_measurements,
        "updated_at": saved_record.get("updated_at") or now_utc
    }
