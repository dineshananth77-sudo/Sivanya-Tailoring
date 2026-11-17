from datetime import datetime
from typing import Optional, List, Dict
import uuid
from pydantic import BaseModel, ConfigDict, Field


class ReviewCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    rating: int = Field(..., ge=1, le=5, description="Star rating between 1 and 5")
    comment: Optional[str] = Field(None, max_length=2000, description="Customer review commentary")


class ReviewUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    rating: Optional[int] = Field(None, ge=1, le=5)
    comment: Optional[str] = Field(None, max_length=2000)


class ReviewResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    product_id: uuid.UUID
    customer_id: uuid.UUID
    customer_name: Optional[str] = None
    rating: int
    comment: Optional[str] = None
    is_visible: bool
    created_at: datetime
    updated_at: datetime


class ProductReviewSummaryResponse(BaseModel):
    product_id: uuid.UUID
    average_rating: float
    total_reviews: int
    rating_distribution: Dict[str, int]
    reviews: List[ReviewResponse]
    page: int
    limit: int
    total_pages: int


class ReviewVisibilityUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    is_visible: bool
