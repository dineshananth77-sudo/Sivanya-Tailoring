from decimal import Decimal
from datetime import datetime
from typing import Optional, List
import uuid
import re
from pydantic import BaseModel, ConfigDict, Field, field_validator


def slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    return text.strip("-")


# ---------------- Category Schemas ----------------

class CategoryBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    slug: Optional[str] = Field(None, max_length=120)
    description: Optional[str] = None
    image_url: Optional[str] = Field(None, max_length=500)
    is_active: bool = True
    sort_order: int = 0


class CategoryCreate(CategoryBase):
    model_config = ConfigDict(extra="forbid")

    @field_validator("slug", mode="before")
    @classmethod
    def set_slug(cls, v: Optional[str], info) -> Optional[str]:
        if not v and "name" in info.data:
            return slugify(info.data["name"])
        return slugify(v) if v else None


class CategoryUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    slug: Optional[str] = Field(None, max_length=120)
    description: Optional[str] = None
    image_url: Optional[str] = Field(None, max_length=500)
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None

    @field_validator("slug", mode="before")
    @classmethod
    def format_slug(cls, v: Optional[str]) -> Optional[str]:
        return slugify(v) if v else None


class CategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    slug: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    is_active: bool
    sort_order: int
    created_at: datetime
    updated_at: datetime


# ---------------- Product Image Schemas ----------------

class ProductImageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    product_id: uuid.UUID
    cloudinary_url: str
    cloudinary_public_id: str
    width: int
    height: int
    format: str
    bytes_size: int
    sort_order: int
    is_primary: bool
    created_at: datetime


# ---------------- Product Schemas ----------------

class ProductBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    slug: Optional[str] = Field(None, max_length=240)
    description: str = Field("", max_length=5000)
    price: Decimal = Field(..., gt=0, decimal_places=2)
    category_id: uuid.UUID
    is_available: bool = True
    stock_quantity: Optional[int] = Field(None, ge=0)
    is_active: bool = True


class ProductCreate(ProductBase):
    model_config = ConfigDict(extra="forbid")

    @field_validator("slug", mode="before")
    @classmethod
    def set_slug(cls, v: Optional[str], info) -> Optional[str]:
        if not v and "name" in info.data:
            return slugify(info.data["name"])
        return slugify(v) if v else None


class ProductUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: Optional[str] = Field(None, min_length=2, max_length=200)
    slug: Optional[str] = Field(None, max_length=240)
    description: Optional[str] = Field(None, max_length=5000)
    price: Optional[Decimal] = Field(None, gt=0, decimal_places=2)
    category_id: Optional[uuid.UUID] = None
    is_available: Optional[bool] = None
    stock_quantity: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None

    @field_validator("slug", mode="before")
    @classmethod
    def format_slug(cls, v: Optional[str]) -> Optional[str]:
        return slugify(v) if v else None


class ProductListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    slug: str
    price: Decimal
    category_id: uuid.UUID
    category_name: Optional[str] = None
    is_available: bool
    stock_quantity: Optional[int] = None
    is_active: bool
    primary_image_url: Optional[str] = None
    created_at: datetime


class ProductDetailResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    slug: str
    description: str
    price: Decimal
    category_id: uuid.UUID
    category: CategoryResponse
    is_available: bool
    stock_quantity: Optional[int] = None
    is_active: bool
    images: List[ProductImageResponse] = []
    created_at: datetime
    updated_at: datetime


class PaginatedProductsResponse(BaseModel):
    items: List[ProductListItem]
    total: int
    page: int
    limit: int
    total_pages: int
