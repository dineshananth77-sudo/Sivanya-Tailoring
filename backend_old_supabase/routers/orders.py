from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field

from supabase_client import supabase
from routers.auth import get_current_user

router = APIRouter(
    prefix="/orders",
    tags=["Orders"]
)


class CreateOrderRequest(BaseModel):
    design_title: str = Field(..., min_length=1, max_length=200)
    design_category: str = Field(default="", max_length=100)
    design_price: str = Field(default="", max_length=50)
    garment_type: str = Field(..., min_length=1, max_length=100)
    measurements: dict[str, Any] = Field(default_factory=dict)
    fabric_preference: str | None = Field(None, max_length=200)
    special_instructions: str | None = Field(None, max_length=2000)
    reference_image_url: str | None = Field(None, max_length=1000)


# 1. Create a new order (JWT-protected)
@router.post("/")
def create_order(
    payload: CreateOrderRequest,
    user: dict = Depends(get_current_user)
):
    """
    Creates a new tailoring order for the authenticated customer.
    The user_id is taken from the JWT token — never from the request body.
    """
    customer_id = str(user["id"])

    order_data = {
        "user_id": customer_id,
        "design_title": payload.design_title,
        "design_category": payload.design_category,
        "design_price": payload.design_price,
        "garment_type": payload.garment_type,
        "measurements": payload.measurements,
        "fabric_preference": payload.fabric_preference,
        "special_instructions": payload.special_instructions,
        "reference_image_url": payload.reference_image_url,
        "status": "pending",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    try:
        response = (
            supabase.table("orders")
            .insert(order_data)
            .execute()
        )
    except Exception as error:
        error_msg = str(error)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create order: {error_msg}"
        )

    if not response.data:
        raise HTTPException(
            status_code=500,
            detail="Order creation failed — no data returned."
        )

    created = response.data[0]
    return {
        "id": created["id"],
        "status": created.get("status", "pending"),
        "created_at": created.get("created_at"),
        "message": "Order placed successfully"
    }


# 2. List all orders for the authenticated customer (JWT-protected)
@router.get("/")
def get_my_orders(
    user: dict = Depends(get_current_user)
):
    """
    Returns all orders belonging to the authenticated customer,
    ordered by creation date descending (newest first).
    """
    customer_id = str(user["id"])

    response = (
        supabase.table("orders")
        .select(
            "id, design_title, design_category, design_price, "
            "garment_type, status, created_at"
        )
        .eq("user_id", customer_id)
        .order("created_at", desc=True)
        .execute()
    )

    return {"orders": response.data or []}


# 3. Get a single order by ID (JWT-protected, ownership enforced)
@router.get("/{order_id}")
def get_order_detail(
    order_id: str,
    user: dict = Depends(get_current_user)
):
    """
    Returns full detail of a single order.
    Returns 404 if the order doesn't exist or belongs to another customer.
    """
    customer_id = str(user["id"])

    response = (
        supabase.table("orders")
        .select("*")
        .eq("id", order_id)
        .eq("user_id", customer_id)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=404,
            detail="Order not found."
        )

    return response.data[0]

