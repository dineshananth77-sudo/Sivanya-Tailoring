import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.review_service import ReviewService
from app.schemas.reviews import (
    ReviewCreate,
    ReviewUpdate,
    ReviewResponse,
    ProductReviewSummaryResponse,
)

router = APIRouter(tags=["Reviews"])


@router.get(
    "/products/{product_id}/reviews",
    response_model=ProductReviewSummaryResponse,
    summary="Get product reviews and rating summary",
)
def get_product_reviews(
    product_id: uuid.UUID,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    service = ReviewService(db)
    return service.get_product_reviews(product_id=product_id, page=page, limit=limit)


@router.post(
    "/products/{product_id}/reviews",
    response_model=ReviewResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a verified review for a delivered product",
)
def create_review(
    product_id: uuid.UUID,
    payload: ReviewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReviewService(db)
    return service.create_review(
        product_id=product_id, customer_id=current_user.id, payload=payload
    )


@router.put(
    "/reviews/{review_id}",
    response_model=ReviewResponse,
    summary="Update my review",
)
def update_review(
    review_id: uuid.UUID,
    payload: ReviewUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReviewService(db)
    return service.update_review(
        review_id=review_id, customer_id=current_user.id, payload=payload
    )


@router.delete(
    "/reviews/{review_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete my review",
)
def delete_review(
    review_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReviewService(db)
    service.delete_review(review_id=review_id, customer_id=current_user.id)
    return None
