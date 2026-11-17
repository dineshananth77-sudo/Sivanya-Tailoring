import uuid
from typing import Optional, List, Tuple, Dict
from sqlalchemy import select, func, desc
from sqlalchemy.orm import Session, joinedload

from app.models.review import Review
from app.models.order import Order, OrderItem, OrderStatus


class ReviewRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, review_id: uuid.UUID) -> Optional[Review]:
        return self.db.execute(
            select(Review)
            .options(joinedload(Review.customer), joinedload(Review.product))
            .where(Review.id == review_id)
        ).scalar_one_or_none()

    def get_by_product_and_customer(
        self, product_id: uuid.UUID, customer_id: uuid.UUID
    ) -> Optional[Review]:
        return self.db.execute(
            select(Review).where(
                Review.product_id == product_id, Review.customer_id == customer_id
            )
        ).scalar_one_or_none()

    def customer_has_delivered_order_for_product(
        self, customer_id: uuid.UUID, product_id: uuid.UUID
    ) -> bool:
        stmt = (
            select(func.count(OrderItem.id))
            .select_from(Order)
            .join(OrderItem, Order.id == OrderItem.order_id)
            .where(
                Order.customer_id == customer_id,
                Order.status == OrderStatus.DELIVERED.value,
                OrderItem.product_id == product_id,
            )
        )
        count = self.db.execute(stmt).scalar_one()
        return count > 0

    def list_by_product(
        self,
        product_id: uuid.UUID,
        visible_only: bool = True,
        page: int = 1,
        limit: int = 20,
    ) -> Tuple[List[Review], int]:
        query = (
            select(Review)
            .options(joinedload(Review.customer))
            .where(Review.product_id == product_id)
        )
        if visible_only:
            query = query.where(Review.is_visible == True)

        count_query = select(func.count()).select_from(query.order_by(None).subquery())
        total = self.db.execute(count_query).scalar_one()

        query = query.order_by(desc(Review.created_at))
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit)

        items = list(self.db.execute(query).scalars().all())
        return items, total

    def get_rating_stats(self, product_id: uuid.UUID) -> Tuple[float, int, Dict[str, int]]:
        query = select(Review.rating).where(
            Review.product_id == product_id, Review.is_visible == True
        )
        ratings = list(self.db.execute(query).scalars().all())

        total = len(ratings)
        distribution = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
        for r in ratings:
            key = str(r)
            if key in distribution:
                distribution[key] += 1

        avg = round(sum(ratings) / total, 1) if total > 0 else 0.0
        return avg, total, distribution

    def list_all_admin(
        self,
        visible: Optional[bool] = None,
        page: int = 1,
        limit: int = 20,
    ) -> Tuple[List[Review], int]:
        query = select(Review).options(
            joinedload(Review.customer), joinedload(Review.product)
        )
        if visible is not None:
            query = query.where(Review.is_visible == visible)

        count_query = select(func.count()).select_from(query.order_by(None).subquery())
        total = self.db.execute(count_query).scalar_one()

        query = query.order_by(desc(Review.created_at))
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit)

        items = list(self.db.execute(query).scalars().all())
        return items, total

    def create(self, review: Review) -> Review:
        self.db.add(review)
        self.db.commit()
        self.db.refresh(review)
        return self.get_by_id(review.id) or review

    def update(self, review: Review) -> Review:
        self.db.commit()
        self.db.refresh(review)
        return self.get_by_id(review.id) or review

    def delete(self, review: Review) -> None:
        self.db.delete(review)
        self.db.commit()
