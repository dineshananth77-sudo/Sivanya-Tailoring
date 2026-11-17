from typing import Any

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field

from supabase_client import supabase
from routers.auth import get_current_user

router = APIRouter(
    prefix="/wishlist",
    tags=["Wishlist"]
)


class WishlistItemPayload(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    category: str = Field(..., min_length=1, max_length=100)
    price: str | None = Field(None, max_length=50)
    image: str | None = Field(None, max_length=1000)


# 1. Get current customer's wishlist (JWT-protected)
@router.get("/")
def get_my_wishlist(
    user: dict = Depends(get_current_user)
):
    """
    Returns all wishlist items saved by the authenticated customer.
    """
    customer_id = str(user["id"])

    response = (
        supabase.table("wishlist")
        .select("title, category, price, image")
        .eq("user_id", customer_id)
        .execute()
    )

    return {"items": response.data or []}


# 2. Toggle or Add wishlist item (JWT-protected)
@router.post("/toggle")
def toggle_wishlist_item(
    payload: WishlistItemPayload,
    user: dict = Depends(get_current_user)
):
    """
    Toggles a wishlist item: if present, removes it; if absent, adds it.
    Returns status: 'added' or 'removed'.
    """
    customer_id = str(user["id"])

    # Check if already in wishlist
    existing = (
        supabase.table("wishlist")
        .select("id")
        .eq("user_id", customer_id)
        .eq("title", payload.title)
        .eq("category", payload.category)
        .execute()
    )

    if existing.data:
        # Remove
        supabase.table("wishlist").delete().eq("user_id", customer_id).eq("title", payload.title).eq("category", payload.category).execute()
        return {"status": "removed", "item": payload.model_dump()}
    else:
        # Add
        supabase.table("wishlist").insert({
            "user_id": customer_id,
            "title": payload.title,
            "category": payload.category,
            "price": payload.price,
            "image": payload.image,
        }).execute()
        return {"status": "added", "item": payload.model_dump()}


# 3. Explicitly remove an item (JWT-protected)
@router.delete("/")
def remove_wishlist_item(
    title: str,
    category: str,
    user: dict = Depends(get_current_user)
):
    """
    Removes a specific item from the authenticated customer's wishlist.
    """
    customer_id = str(user["id"])

    supabase.table("wishlist").delete().eq("user_id", customer_id).eq("title", title).eq("category", category).execute()

    return {"status": "removed", "title": title, "category": category}

