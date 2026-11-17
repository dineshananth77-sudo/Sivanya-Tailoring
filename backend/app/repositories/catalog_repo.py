import math
import uuid
from decimal import Decimal
from typing import Optional, List, Tuple
from sqlalchemy import select, func, or_, desc, asc
from sqlalchemy.orm import Session, joinedload, selectinload

from app.models.catalog import Category, Product, ProductImage


class CategoryRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, category_id: uuid.UUID) -> Optional[Category]:
        return self.db.execute(
            select(Category).where(Category.id == category_id)
        ).scalar_one_or_none()

    def get_by_slug(self, slug: str) -> Optional[Category]:
        return self.db.execute(
            select(Category).where(Category.slug == slug)
        ).scalar_one_or_none()

    def get_by_name(self, name: str) -> Optional[Category]:
        return self.db.execute(
            select(Category).where(func.lower(Category.name) == name.lower())
        ).scalar_one_or_none()

    def list_all(self, active_only: bool = True) -> List[Category]:
        query = select(Category)
        if active_only:
            query = query.where(Category.is_active == True)
        query = query.order_by(Category.sort_order.asc(), Category.name.asc())
        return list(self.db.execute(query).scalars().all())

    def create(self, category: Category) -> Category:
        self.db.add(category)
        self.db.commit()
        self.db.refresh(category)
        return category

    def update(self, category: Category) -> Category:
        self.db.commit()
        self.db.refresh(category)
        return category

    def delete(self, category: Category) -> None:
        self.db.delete(category)
        self.db.commit()


class ProductRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, product_id: uuid.UUID) -> Optional[Product]:
        return self.db.execute(
            select(Product)
            .options(
                joinedload(Product.category),
                selectinload(Product.images),
            )
            .where(Product.id == product_id)
        ).scalar_one_or_none()

    def get_by_slug(self, slug: str) -> Optional[Product]:
        return self.db.execute(
            select(Product)
            .options(
                joinedload(Product.category),
                selectinload(Product.images),
            )
            .where(Product.slug == slug)
        ).scalar_one_or_none()

    def list_paginated(
        self,
        category_id: Optional[uuid.UUID] = None,
        search: Optional[str] = None,
        min_price: Optional[Decimal] = None,
        max_price: Optional[Decimal] = None,
        sort_by: str = "newest",
        active_only: bool = True,
        available_only: bool = False,
        page: int = 1,
        limit: int = 20,
    ) -> Tuple[List[Product], int]:
        query = select(Product).options(
            joinedload(Product.category),
            selectinload(Product.images),
        )

        if active_only:
            query = query.where(Product.is_active == True)
        if available_only:
            query = query.where(Product.is_available == True)
        if category_id:
            query = query.where(Product.category_id == category_id)
        if min_price is not None:
            query = query.where(Product.price >= min_price)
        if max_price is not None:
            query = query.where(Product.price <= max_price)
        if search:
            pattern = f"%{search.strip().lower()}%"
            query = query.where(
                or_(
                    func.lower(Product.name).like(pattern),
                    func.lower(Product.description).like(pattern),
                )
            )

        # Count total items
        count_query = select(func.count()).select_from(query.order_by(None).subquery())
        total = self.db.execute(count_query).scalar_one()

        # Sorting
        if sort_by == "price_asc":
            query = query.order_by(Product.price.asc())
        elif sort_by == "price_desc":
            query = query.order_by(Product.price.desc())
        else:  # "newest"
            query = query.order_by(Product.created_at.desc())

        # Pagination
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit)

        items = list(self.db.execute(query).scalars().all())
        return items, total

    def create(self, product: Product) -> Product:
        self.db.add(product)
        self.db.commit()
        self.db.refresh(product)
        return self.get_by_id(product.id) or product

    def update(self, product: Product) -> Product:
        self.db.commit()
        self.db.refresh(product)
        return self.get_by_id(product.id) or product

    def delete(self, product: Product) -> None:
        self.db.delete(product)
        self.db.commit()


class ProductImageRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, image_id: uuid.UUID) -> Optional[ProductImage]:
        return self.db.execute(
            select(ProductImage).where(ProductImage.id == image_id)
        ).scalar_one_or_none()

    def list_by_product_id(self, product_id: uuid.UUID) -> List[ProductImage]:
        return list(
            self.db.execute(
                select(ProductImage)
                .where(ProductImage.product_id == product_id)
                .order_by(ProductImage.sort_order.asc(), ProductImage.created_at.asc())
            ).scalars().all()
        )

    def count_by_product(self, product_id: uuid.UUID) -> int:
        return self.db.execute(
            select(func.count(ProductImage.id)).where(ProductImage.product_id == product_id)
        ).scalar_one()

    def create(self, image: ProductImage) -> ProductImage:
        self.db.add(image)
        self.db.commit()
        self.db.refresh(image)
        return image

    def set_primary(self, product_id: uuid.UUID, image_id: uuid.UUID) -> None:
        # Reset all to not primary
        images = self.list_by_product_id(product_id)
        for img in images:
            img.is_primary = (img.id == image_id)
        self.db.commit()

    def delete(self, image: ProductImage) -> None:
        self.db.delete(image)
        self.db.commit()
