import math
import uuid
from typing import Optional, List, Tuple, Dict, Any
from sqlalchemy.orm import Session

from app.models.review import Review
from app.repositories.review_repo import ReviewRepository
from app.repositories.catalog_repo import ProductRepository
from app.schemas.reviews import (
    ReviewCreate,
    ReviewUpdate,
    ReviewResponse,
    ProductReviewSummaryResponse,
)
from app.exceptions import (
    NotFoundException,
    BadRequestException,
    ConflictException,
    ForbiddenException,
)


class ReviewService:
    def __init__(self, db: Session):
        self.db = db
        self.review_repo = ReviewRepository(db)
        self.product_repo = ProductRepository(db)

    def _map_review(self, r: Review) -> ReviewResponse:
        return ReviewResponse(
            id=r.id,
            product_id=r.product_id,
            customer_id=r.customer_id,
            customer_name=r.customer.full_name if r.customer else "Verified Customer",
            rating=r.rating,
            comment=r.comment,
            is_visible=r.is_visible,
            created_at=r.created_at,
            updated_at=r.updated_at,
        )

    # ================= Customer Operations =================

    def create_review(
        self, product_id: uuid.UUID, customer_id: uuid.UUID, payload: ReviewCreate
    ) -> ReviewResponse:
        # 1. Product must exist
        product = self.product_repo.get_by_id(product_id)
        if not product or not product.is_active:
            raise NotFoundException(f"Product '{product_id}' not found.", code="PRODUCT_NOT_FOUND")

        # 2. Check duplicate review (one per customer per product)
        existing = self.review_repo.get_by_product_and_customer(product_id, customer_id)
        if existing:
            raise ConflictException(
                "You have already reviewed this product. You can update your existing review.",
                code="REVIEW_ALREADY_EXISTS",
            )

        # 3. Verified Purchase Requirement
        has_purchased = self.review_repo.customer_has_delivered_order_for_product(
            customer_id=customer_id, product_id=product_id
        )
        if not has_purchased:
            raise BadRequestException(
                "You can only review products that have been delivered to you in a completed order.",
                code="PURCHASE_VERIFICATION_REQUIRED",
            )

        review = Review(
            product_id=product_id,
            customer_id=customer_id,
            rating=payload.rating,
            comment=payload.comment,
            is_visible=True,
        )
        saved = self.review_repo.create(review)
        return self._map_review(saved)

    def update_review(
        self, review_id: uuid.UUID, customer_id: uuid.UUID, payload: ReviewUpdate
    ) -> ReviewResponse:
        review = self.review_repo.get_by_id(review_id)
        if not review or review.customer_id != customer_id:
            raise NotFoundException("Review not found.", code="REVIEW_NOT_FOUND")

        if payload.rating is not None:
            review.rating = payload.rating
        if payload.comment is not None:
            review.comment = payload.comment

        updated = self.review_repo.update(review)
        return self._map_review(updated)

    def delete_review(self, review_id: uuid.UUID, customer_id: uuid.UUID) -> None:
        review = self.review_repo.get_by_id(review_id)
        if not review or review.customer_id != customer_id:
            raise NotFoundException("Review not found.", code="REVIEW_NOT_FOUND")
        self.review_repo.delete(review)

    # ================= Public Operations =================

    def get_product_reviews(
        self, product_id: uuid.UUID, page: int = 1, limit: int = 20
    ) -> ProductReviewSummaryResponse:
        # Check product exists
        product = self.product_repo.get_by_id(product_id)
        if not product:
            raise NotFoundException(f"Product '{product_id}' not found.", code="PRODUCT_NOT_FOUND")

        avg, total, distribution = self.review_repo.get_rating_stats(product_id)
        reviews, total_visible = self.review_repo.list_by_product(
            product_id=product_id, visible_only=True, page=page, limit=limit
        )

        total_pages = math.ceil(total_visible / limit) if total_visible > 0 else 1

        return ProductReviewSummaryResponse(
            product_id=product_id,
            average_rating=avg,
            total_reviews=total,
            rating_distribution=distribution,
            reviews=[self._map_review(r) for r in reviews],
            page=page,
            limit=limit,
            total_pages=total_pages,
        )

    # ================= Admin Operations =================

    def admin_list_reviews(
        self, visible: Optional[bool] = None, page: int = 1, limit: int = 20
    ) -> Dict[str, Any]:
        reviews, total = self.review_repo.list_all_admin(
            visible=visible, page=page, limit=limit
        )
        total_pages = math.ceil(total / limit) if total > 0 else 1
        return {
            "items": [self._map_review(r) for r in reviews],
            "total": total,
            "page": page,
            "limit": limit,
            "total_pages": total_pages,
        }

    def admin_set_visibility(self, review_id: uuid.UUID, is_visible: bool) -> ReviewResponse:
        review = self.review_repo.get_by_id(review_id)
        if not review:
            raise NotFoundException(f"Review '{review_id}' not found.", code="REVIEW_NOT_FOUND")

        review.is_visible = is_visible
        updated = self.review_repo.update(review)
        return self._map_review(updated)

    def admin_delete_review(self, review_id: uuid.UUID) -> None:
        review = self.review_repo.get_by_id(review_id)
        if not review:
            raise NotFoundException(f"Review '{review_id}' not found.", code="REVIEW_NOT_FOUND")
        self.review_repo.delete(review)
