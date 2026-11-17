
from fastapi import APIRouter, HTTPException
from supabase_client import supabase

router = APIRouter(
    prefix="/products",
    tags=["Products"]
)


# Get all products or filter by category
@router.get("/")
def get_products(category: str = None):

    query = supabase.table("products").select("*")

    if category:
        query = query.eq("category", category)

    response = query.execute()

    return response.data


# Get all product categories
@router.get("/categories/list")
def get_categories():

    response = (
        supabase.table("products")
        .select("category")
        .execute()
    )

    categories = sorted(set(
        item["category"] for item in response.data
    ))

    return categories


# Get a single product by ID
@router.get("/{product_id}")
def get_product(product_id: int):

    response = (
        supabase.table("products")
        .select("*")
        .eq("id", product_id)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=404,
            detail="Product not found"
        )

    return response.data[0]
