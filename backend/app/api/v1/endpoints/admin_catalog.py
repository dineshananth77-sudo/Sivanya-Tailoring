from decimal import Decimal
from typing import Optional, List, Dict, Any
import uuid
from fastapi import APIRouter, Depends, Query, UploadFile, File, Form, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.api.deps import require_admin
from app.models.user import User
from app.services.catalog_service import CatalogService
from app.schemas.catalog import (
    CategoryCreate,
    CategoryUpdate,
    CategoryResponse,
    ProductCreate,
    ProductUpdate,
    ProductDetailResponse,
    PaginatedProductsResponse,
    ProductImageResponse,
)

router = APIRouter(prefix="/admin", tags=["Admin Catalog"])


# ================= Admin Categories =================

@router.get("/categories", response_model=List[CategoryResponse], summary="List all categories (Admin)")
def admin_list_categories(
    active_only: bool = Query(False, description="Whether to return only active categories"),
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = CatalogService(db)
    return service.list_categories(active_only=active_only)


@router.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED, summary="Create category (Admin)")
def admin_create_category(
    payload: CategoryCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = CatalogService(db)
    return service.create_category(payload)


@router.put("/categories/{category_id}", response_model=CategoryResponse, summary="Update category (Admin)")
def admin_update_category(
    category_id: uuid.UUID,
    payload: CategoryUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = CatalogService(db)
    return service.update_category(category_id, payload)


@router.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete category (Admin)")
def admin_delete_category(
    category_id: uuid.UUID,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = CatalogService(db)
    service.delete_category(category_id)
    return None


# ================= Admin Products =================

@router.get("/products", response_model=PaginatedProductsResponse, summary="List all products (Admin)")
def admin_list_products(
    category_id: Optional[uuid.UUID] = Query(None),
    search: Optional[str] = Query(None),
    min_price: Optional[Decimal] = Query(None),
    max_price: Optional[Decimal] = Query(None),
    sort_by: str = Query("newest"),
    active_only: bool = Query(False, description="Filter for active only; defaults to all"),
    available_only: bool = Query(False),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = CatalogService(db)
    return service.list_products(
        category_id=category_id,
        search=search,
        min_price=min_price,
        max_price=max_price,
        sort_by=sort_by,
        active_only=active_only,
        available_only=available_only,
        page=page,
        limit=limit,
    )


@router.post("/products", response_model=ProductDetailResponse, status_code=status.HTTP_201_CREATED, summary="Create product (Admin)")
def admin_create_product(
    payload: ProductCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = CatalogService(db)
    return service.create_product(payload)


@router.put("/products/{product_id}", response_model=ProductDetailResponse, summary="Update product (Admin)")
def admin_update_product(
    product_id: uuid.UUID,
    payload: ProductUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = CatalogService(db)
    return service.update_product(product_id, payload)


@router.delete("/products/{product_id}", summary="Delete or deactivate product (Admin)")
def admin_delete_product(
    product_id: uuid.UUID,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = CatalogService(db)
    return service.delete_product(product_id)


# ================= Admin Product Images =================

@router.post(
    "/products/{product_id}/images",
    response_model=ProductImageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload product image (Admin)",
)
async def admin_upload_product_image(
    product_id: uuid.UUID,
    file: UploadFile = File(...),
    is_primary: bool = Form(False),
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = CatalogService(db)
    file_bytes = await file.read()
    return service.add_product_image(
        product_id=product_id,
        file_bytes=file_bytes,
        content_type=file.content_type,
        is_primary=is_primary,
    )


@router.patch(
    "/products/{product_id}/images/{image_id}/primary",
    response_model=ProductImageResponse,
    summary="Set product primary image (Admin)",
)
def admin_set_primary_image(
    product_id: uuid.UUID,
    image_id: uuid.UUID,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = CatalogService(db)
    return service.set_primary_image(product_id=product_id, image_id=image_id)


@router.delete(
    "/products/{product_id}/images/{image_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete product image (Admin)",
)
def admin_delete_product_image(
    product_id: uuid.UUID,
    image_id: uuid.UUID,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = CatalogService(db)
    service.delete_product_image(product_id=product_id, image_id=image_id)
    return None
