from typing import Optional, Dict, Any
import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.api.deps import require_admin
from app.models.user import User
from app.services.review_service import ReviewService
from app.schemas.reviews import (
    ReviewResponse,
    ReviewVisibilityUpdate,
)

router = APIRouter(prefix="/admin/reviews", tags=["Admin Reviews"])


@router.get("", summary="List all reviews for moderation (Admin)")
def admin_list_reviews(
    visible: Optional[bool] = Query(None, description="Filter by visibility status"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = ReviewService(db)
    return service.admin_list_reviews(visible=visible, page=page, limit=limit)


@router.patch("/{review_id}/visibility", response_model=ReviewResponse, summary="Toggle review visibility (Admin)")
def admin_toggle_review_visibility(
    review_id: uuid.UUID,
    payload: ReviewVisibilityUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = ReviewService(db)
    return service.admin_set_visibility(review_id=review_id, is_visible=payload.is_visible)


@router.delete("/{review_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete review (Admin)")
def admin_delete_review(
    review_id: uuid.UUID,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = ReviewService(db)
    service.admin_delete_review(review_id=review_id)
    return None
