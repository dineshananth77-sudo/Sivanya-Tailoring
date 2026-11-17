import math
import uuid
from decimal import Decimal
from typing import Optional, List, Tuple, Dict, Any
from sqlalchemy.orm import Session

from app.models.catalog import Category, Product, ProductImage
from app.repositories.catalog_repo import (
    CategoryRepository,
    ProductRepository,
    ProductImageRepository,
)
from app.schemas.catalog import (
    CategoryCreate,
    CategoryUpdate,
    ProductCreate,
    ProductUpdate,
    ProductListItem,
    PaginatedProductsResponse,
)
from app.integrations.cloudinary_service import (
    upload_product_image,
    delete_cloudinary_image,
)
from app.exceptions import (
    NotFoundException,
    BadRequestException,
    ConflictException,
)

MAX_IMAGES_PER_PRODUCT = 8


class CatalogService:
    def __init__(self, db: Session):
        self.db = db
        self.category_repo = CategoryRepository(db)
        self.product_repo = ProductRepository(db)
        self.image_repo = ProductImageRepository(db)

    # ================= Category Operations =================

    def list_categories(self, active_only: bool = True) -> List[Category]:
        return self.category_repo.list_all(active_only=active_only)

    def get_category_by_id(self, category_id: uuid.UUID) -> Category:
        category = self.category_repo.get_by_id(category_id)
        if not category:
            raise NotFoundException(f"Category with ID '{category_id}' not found.", code="CATEGORY_NOT_FOUND")
        return category

    def create_category(self, payload: CategoryCreate) -> Category:
        existing_name = self.category_repo.get_by_name(payload.name)
        if existing_name:
            raise ConflictException(f"Category with name '{payload.name}' already exists.", code="CATEGORY_NAME_EXISTS")

        slug = payload.slug or payload.name.lower().replace(" ", "-")
        existing_slug = self.category_repo.get_by_slug(slug)
        if existing_slug:
            slug = f"{slug}-{uuid.uuid4().hex[:6]}"

        category = Category(
            name=payload.name,
            slug=slug,
            description=payload.description,
            image_url=payload.image_url,
            is_active=payload.is_active,
            sort_order=payload.sort_order,
        )
        return self.category_repo.create(category)

    def update_category(self, category_id: uuid.UUID, payload: CategoryUpdate) -> Category:
        category = self.get_category_by_id(category_id)

        if payload.name is not None and payload.name != category.name:
            existing_name = self.category_repo.get_by_name(payload.name)
            if existing_name and existing_name.id != category.id:
                raise ConflictException(f"Category with name '{payload.name}' already exists.", code="CATEGORY_NAME_EXISTS")
            category.name = payload.name

        if payload.slug is not None and payload.slug != category.slug:
            existing_slug = self.category_repo.get_by_slug(payload.slug)
            if existing_slug and existing_slug.id != category.id:
                raise ConflictException(f"Category slug '{payload.slug}' already exists.", code="CATEGORY_SLUG_EXISTS")
            category.slug = payload.slug

        if payload.description is not None:
            category.description = payload.description
        if payload.image_url is not None:
            category.image_url = payload.image_url
        if payload.is_active is not None:
            category.is_active = payload.is_active
        if payload.sort_order is not None:
            category.sort_order = payload.sort_order

        return self.category_repo.update(category)

    def delete_category(self, category_id: uuid.UUID) -> None:
        category = self.get_category_by_id(category_id)
        # Check if products exist in category
        products, total = self.product_repo.list_paginated(category_id=category_id, active_only=False, limit=1)
        if total > 0:
            raise BadRequestException(
                f"Cannot delete category '{category.name}' because it contains {total} products. Deactivate it or reassign products first.",
                code="CATEGORY_HAS_PRODUCTS",
            )
        self.category_repo.delete(category)

    # ================= Product Operations =================

    def get_product(self, id_or_slug: str) -> Product:
        try:
            prod_uuid = uuid.UUID(id_or_slug)
            product = self.product_repo.get_by_id(prod_uuid)
        except ValueError:
            product = self.product_repo.get_by_slug(id_or_slug)

        if not product:
            raise NotFoundException(f"Product '{id_or_slug}' not found.", code="PRODUCT_NOT_FOUND")
        return product

    def list_products(
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
    ) -> PaginatedProductsResponse:
        if page < 1:
            page = 1
        if limit < 1 or limit > 100:
            limit = 20

        products, total = self.product_repo.list_paginated(
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

        items = []
        for prod in products:
            primary_img = next((img.cloudinary_url for img in prod.images if img.is_primary), None)
            if not primary_img and prod.images:
                primary_img = prod.images[0].cloudinary_url

            items.append(
                ProductListItem(
                    id=prod.id,
                    name=prod.name,
                    slug=prod.slug,
                    price=prod.price,
                    category_id=prod.category_id,
                    category_name=prod.category.name if prod.category else None,
                    is_available=prod.is_available,
                    stock_quantity=prod.stock_quantity,
                    is_active=prod.is_active,
                    primary_image_url=primary_img,
                    created_at=prod.created_at,
                )
            )

        total_pages = math.ceil(total / limit) if total > 0 else 1

        return PaginatedProductsResponse(
            items=items,
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )

    def create_product(self, payload: ProductCreate) -> Product:
        # Verify category exists
        self.get_category_by_id(payload.category_id)

        slug = payload.slug or payload.name.lower().replace(" ", "-")
        existing_slug = self.product_repo.get_by_slug(slug)
        if existing_slug:
            slug = f"{slug}-{uuid.uuid4().hex[:6]}"

        product = Product(
            name=payload.name,
            slug=slug,
            description=payload.description,
            price=payload.price,
            category_id=payload.category_id,
            is_available=payload.is_available,
            stock_quantity=payload.stock_quantity,
            is_active=payload.is_active,
        )
        return self.product_repo.create(product)

    def update_product(self, product_id: uuid.UUID, payload: ProductUpdate) -> Product:
        product = self.get_product(str(product_id))

        if payload.category_id is not None and payload.category_id != product.category_id:
            self.get_category_by_id(payload.category_id)
            product.category_id = payload.category_id

        if payload.name is not None:
            product.name = payload.name

        if payload.slug is not None and payload.slug != product.slug:
            existing_slug = self.product_repo.get_by_slug(payload.slug)
            if existing_slug and existing_slug.id != product.id:
                raise ConflictException(f"Product slug '{payload.slug}' already exists.", code="PRODUCT_SLUG_EXISTS")
            product.slug = payload.slug

        if payload.description is not None:
            product.description = payload.description
        if payload.price is not None:
            product.price = payload.price
        if payload.is_available is not None:
            product.is_available = payload.is_available
        if payload.stock_quantity is not None:
            product.stock_quantity = payload.stock_quantity
        if payload.is_active is not None:
            product.is_active = payload.is_active

        return self.product_repo.update(product)

    def delete_product(self, product_id: uuid.UUID) -> Dict[str, Any]:
        """
        Deletes a product.
        Requirement: A product that has orders must be deactivated instead of hard-deleted.
        """
        product = self.get_product(str(product_id))

        # Check for order items:
        # In Phase 4 we will check if any order_items reference this product.
        # If order items exist or if we want safe archival, we check and soft delete.
        has_orders = False
        try:
            from app.models.order import OrderItem
            order_count = self.db.query(OrderItem).filter(OrderItem.product_id == product.id).count()
            has_orders = order_count > 0
        except Exception:
            has_orders = False

        if has_orders:
            product.is_active = False
            product.is_available = False
            self.product_repo.update(product)
            return {
                "id": str(product.id),
                "action": "deactivated",
                "message": "Product has order history and was deactivated instead of deleted.",
            }

        # Otherwise hard delete product and its images from Cloudinary
        for img in list(product.images):
            delete_cloudinary_image(img.cloudinary_public_id)

        self.product_repo.delete(product)
        return {
            "id": str(product.id),
            "action": "deleted",
            "message": "Product and associated assets permanently deleted.",
        }

    # ================= Product Image Operations =================

    def add_product_image(
        self,
        product_id: uuid.UUID,
        file_bytes: bytes,
        content_type: Optional[str] = None,
        is_primary: bool = False,
    ) -> ProductImage:
        product = self.get_product(str(product_id))

        current_count = self.image_repo.count_by_product(product.id)
        if current_count >= MAX_IMAGES_PER_PRODUCT:
            raise BadRequestException(
                f"Maximum of {MAX_IMAGES_PER_PRODUCT} images allowed per product.",
                code="MAX_IMAGES_EXCEEDED",
            )

        # Upload to Cloudinary
        upload_meta = upload_product_image(
            file_bytes=file_bytes,
            product_id=str(product.id),
            content_type=content_type,
        )

        # Auto make primary if it's the first image
        mark_as_primary = is_primary or (current_count == 0)

        image = ProductImage(
            product_id=product.id,
            cloudinary_url=upload_meta["cloudinary_url"],
            cloudinary_public_id=upload_meta["cloudinary_public_id"],
            cloudinary_asset_id=upload_meta["cloudinary_asset_id"],
            width=upload_meta["width"],
            height=upload_meta["height"],
            format=upload_meta["format"],
            bytes_size=upload_meta["bytes_size"],
            sort_order=current_count,
            is_primary=mark_as_primary,
        )

        try:
            saved_image = self.image_repo.create(image)
            if mark_as_primary and current_count > 0:
                self.image_repo.set_primary(product.id, saved_image.id)
            return saved_image
        except Exception as exc:
            # Clean up uploaded asset if DB save fails
            delete_cloudinary_image(upload_meta["cloudinary_public_id"])
            raise exc

    def set_primary_image(self, product_id: uuid.UUID, image_id: uuid.UUID) -> ProductImage:
        self.get_product(str(product_id))
        image = self.image_repo.get_by_id(image_id)
        if not image or image.product_id != product_id:
            raise NotFoundException("Image not found for this product.", code="IMAGE_NOT_FOUND")

        self.image_repo.set_primary(product_id, image_id)
        self.db.refresh(image)
        return image

    def delete_product_image(self, product_id: uuid.UUID, image_id: uuid.UUID) -> None:
        self.get_product(str(product_id))
        image = self.image_repo.get_by_id(image_id)
        if not image or image.product_id != product_id:
            raise NotFoundException("Image not found for this product.", code="IMAGE_NOT_FOUND")

        was_primary = image.is_primary
        public_id = image.cloudinary_public_id

        self.image_repo.delete(image)
        delete_cloudinary_image(public_id)

        # If deleted image was primary, assign the first remaining image as primary
        if was_primary:
            remaining = self.image_repo.list_by_product_id(product_id)
            if remaining:
                self.image_repo.set_primary(product_id, remaining[0].id)
