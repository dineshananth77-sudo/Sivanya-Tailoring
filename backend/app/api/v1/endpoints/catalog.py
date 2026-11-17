from decimal import Decimal
from typing import Optional, List
import uuid
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.catalog_service import CatalogService
from app.schemas.catalog import (
    CategoryResponse,
    ProductDetailResponse,
    PaginatedProductsResponse,
)

router = APIRouter()


@router.get("/categories", response_model=List[CategoryResponse], summary="List active categories")
def get_categories(db: Session = Depends(get_db)):
    service = CatalogService(db)
    return service.list_categories(active_only=True)


@router.get("/products", response_model=PaginatedProductsResponse, summary="List active products with filters")
def get_products(
    category_id: Optional[uuid.UUID] = Query(None, description="Filter by category UUID"),
    search: Optional[str] = Query(None, description="Search term in name or description"),
    min_price: Optional[Decimal] = Query(None, description="Minimum price filter"),
    max_price: Optional[Decimal] = Query(None, description="Maximum price filter"),
    sort_by: str = Query("newest", pattern="^(newest|price_asc|price_desc)$", description="Sort option"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    db: Session = Depends(get_db),
):
    service = CatalogService(db)
    return service.list_products(
        category_id=category_id,
        search=search,
        min_price=min_price,
        max_price=max_price,
        sort_by=sort_by,
        active_only=True,
        available_only=False,
        page=page,
        limit=limit,
    )


@router.get("/products/{id_or_slug}", response_model=ProductDetailResponse, summary="Get product details")
def get_product_detail(
    id_or_slug: str,
    db: Session = Depends(get_db),
):
    service = CatalogService(db)
    return service.get_product(id_or_slug)
