import math
import uuid
import secrets
from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional, List, Tuple, Dict, Any
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.address import Address
from app.models.order import Order, OrderItem, OrderStatus, OrderStatusHistory
from app.repositories.order_repo import AddressRepository, OrderRepository
from app.repositories.catalog_repo import ProductRepository
from app.services.delivery_service import DeliveryService
from app.schemas.orders import (
    AddressCreate,
    AddressUpdate,
    OrderCreate,
    OrderResponse,
    OrderDetailResponse,
    PaginatedOrdersResponse,
)
from app.exceptions import (
    NotFoundException,
    BadRequestException,
    ForbiddenException,
)

VALID_TRANSITIONS: Dict[str, List[str]] = {
    OrderStatus.PENDING.value: [OrderStatus.CONFIRMED.value, OrderStatus.CANCELLED.value],
    OrderStatus.CONFIRMED.value: [OrderStatus.PREPARING.value, OrderStatus.CANCELLED.value],
    OrderStatus.PREPARING.value: [OrderStatus.OUT_FOR_DELIVERY.value, OrderStatus.CANCELLED.value],
    OrderStatus.OUT_FOR_DELIVERY.value: [OrderStatus.DELIVERED.value, OrderStatus.CANCELLED.value],
    OrderStatus.DELIVERED.value: [],
    OrderStatus.CANCELLED.value: [],
}


class OrderService:
    def __init__(self, db: Session):
        self.db = db
        self.address_repo = AddressRepository(db)
        self.order_repo = OrderRepository(db)
        self.product_repo = ProductRepository(db)
        self.delivery_service = DeliveryService(db)

    # ================= Address Operations =================

    def list_addresses(self, customer_id: uuid.UUID) -> List[Address]:
        return self.address_repo.list_by_customer(customer_id)

    def get_address(self, address_id: uuid.UUID, customer_id: uuid.UUID) -> Address:
        addr = self.address_repo.get_by_id(address_id)
        if not addr or addr.customer_id != customer_id:
            raise NotFoundException("Address not found.", code="ADDRESS_NOT_FOUND")
        return addr

    def create_address(self, customer_id: uuid.UUID, payload: AddressCreate) -> Address:
        existing = self.address_repo.list_by_customer(customer_id)
        # If first address, auto make default
        is_default = payload.is_default or len(existing) == 0

        addr = Address(
            customer_id=customer_id,
            recipient_name=payload.recipient_name,
            phone=payload.phone,
            street=payload.street,
            city=payload.city,
            state=payload.state,
            postal_code=payload.postal_code,
            is_default=is_default,
        )
        return self.address_repo.create(addr)

    def update_address(self, address_id: uuid.UUID, customer_id: uuid.UUID, payload: AddressUpdate) -> Address:
        addr = self.get_address(address_id, customer_id)

        if payload.recipient_name is not None:
            addr.recipient_name = payload.recipient_name
        if payload.phone is not None:
            addr.phone = payload.phone
        if payload.street is not None:
            addr.street = payload.street
        if payload.city is not None:
            addr.city = payload.city
        if payload.state is not None:
            addr.state = payload.state
        if payload.postal_code is not None:
            addr.postal_code = payload.postal_code
        if payload.is_default is not None:
            addr.is_default = payload.is_default

        return self.address_repo.update(addr)

    def set_default_address(self, address_id: uuid.UUID, customer_id: uuid.UUID) -> Address:
        self.get_address(address_id, customer_id)
        return self.address_repo.set_default(customer_id, address_id)

    def delete_address(self, address_id: uuid.UUID, customer_id: uuid.UUID) -> None:
        addr = self.get_address(address_id, customer_id)
        self.address_repo.delete(addr)

    # ================= Order Operations =================

    def create_order(self, customer_id: uuid.UUID, payload: OrderCreate) -> Order:
        # 1. Fetch and snapshot address
        addr = self.get_address(payload.address_id, customer_id)
        address_snapshot = {
            "recipient_name": addr.recipient_name,
            "phone": addr.phone,
            "street": addr.street,
            "city": addr.city,
            "state": addr.state,
            "postal_code": addr.postal_code,
        }

        # 2. Server-side product price validation & stock check
        subtotal = Decimal("0.00")
        order_items_to_create = []

        for item_in in payload.items:
            product = self.product_repo.get_by_id(item_in.product_id)
            if not product or not product.is_active:
                raise BadRequestException(
                    f"Product '{item_in.product_id}' is no longer available.",
                    code="PRODUCT_UNAVAILABLE",
                )
            if not product.is_available:
                raise BadRequestException(
                    f"Product '{product.name}' is currently marked unavailable.",
                    code="PRODUCT_OUT_OF_STOCK",
                )
            if product.stock_quantity is not None:
                if product.stock_quantity < item_in.quantity:
                    raise BadRequestException(
                        f"Insufficient stock for '{product.name}'. Requested {item_in.quantity}, available {product.stock_quantity}.",
                        code="INSUFFICIENT_STOCK",
                    )
                product.stock_quantity -= item_in.quantity

            unit_price = product.price
            line_total = unit_price * item_in.quantity
            subtotal += line_total

            order_items_to_create.append(
                OrderItem(
                    product_id=product.id,
                    product_name_snapshot=product.name,
                    unit_price_snapshot=unit_price,
                    quantity=item_in.quantity,
                    line_total=line_total,
                )
            )

        # 3. Server-side delivery quote calculation
        quote = self.delivery_service.calculate_quote(subtotal)
        delivery_charge = quote.delivery_charge
        total = subtotal + delivery_charge

        # 4. Generate unique readable order number: ORD-YYYYMMDD-XXXX
        today_str = datetime.now(timezone.utc).strftime("%Y%m%d")
        random_suffix = secrets.token_hex(2).upper()
        order_number = f"ORD-{today_str}-{random_suffix}"

        # 5. Create Order atomically
        order = Order(
            order_number=order_number,
            customer_id=customer_id,
            status=OrderStatus.PENDING.value,
            subtotal=subtotal,
            delivery_charge=delivery_charge,
            total=total,
            delivery_address_snapshot=address_snapshot,
            note=payload.note,
        )
        order.items = order_items_to_create

        # Initial audit log
        history = OrderStatusHistory(
            old_status=None,
            new_status=OrderStatus.PENDING.value,
            changed_by_user_id=customer_id,
            comment="Order placed by customer.",
        )
        order.status_history = [history]

        return self.order_repo.create(order)

    def get_order_for_customer(self, order_id: uuid.UUID, customer_id: uuid.UUID) -> Order:
        order = self.order_repo.get_by_id(order_id)
        if not order or order.customer_id != customer_id:
            raise NotFoundException(f"Order '{order_id}' not found.", code="ORDER_NOT_FOUND")
        return order

    def list_orders_for_customer(
        self, customer_id: uuid.UUID, page: int = 1, limit: int = 20
    ) -> PaginatedOrdersResponse:
        orders, total = self.order_repo.list_paginated(
            customer_id=customer_id, page=page, limit=limit
        )
        total_pages = math.ceil(total / limit) if total > 0 else 1
        return PaginatedOrdersResponse(
            items=orders,
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )

    def cancel_order_by_customer(self, order_id: uuid.UUID, customer_id: uuid.UUID) -> Order:
        order = self.get_order_for_customer(order_id, customer_id)

        if order.status != OrderStatus.PENDING.value:
            raise BadRequestException(
                f"Cannot cancel order in status '{order.status}'. Only pending orders can be cancelled by customer.",
                code="CANNOT_CANCEL_ORDER",
            )

        old_status = order.status
        order.status = OrderStatus.CANCELLED.value

        # Restore stock if product tracked
        for item in order.items:
            product = self.product_repo.get_by_id(item.product_id)
            if product and product.stock_quantity is not None:
                product.stock_quantity += item.quantity

        history = OrderStatusHistory(
            order_id=order.id,
            old_status=old_status,
            new_status=OrderStatus.CANCELLED.value,
            changed_by_user_id=customer_id,
            comment="Order cancelled by customer.",
        )
        self.order_repo.add_status_history(history)
        return self.order_repo.update(order)

    # ================= Admin Order Operations =================

    def get_order_for_admin(self, order_id: uuid.UUID) -> Order:
        order = self.order_repo.get_by_id(order_id)
        if not order:
            raise NotFoundException(f"Order '{order_id}' not found.", code="ORDER_NOT_FOUND")
        return order

    def list_orders_for_admin(
        self,
        status: Optional[str] = None,
        search: Optional[str] = None,
        page: int = 1,
        limit: int = 20,
    ) -> PaginatedOrdersResponse:
        orders, total = self.order_repo.list_paginated(
            status=status, search=search, page=page, limit=limit
        )
        total_pages = math.ceil(total / limit) if total > 0 else 1
        return PaginatedOrdersResponse(
            items=orders,
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages,
        )

    def update_order_status_by_admin(
        self,
        order_id: uuid.UUID,
        new_status: OrderStatus,
        admin_id: uuid.UUID,
        comment: Optional[str] = None,
    ) -> Order:
        order = self.get_order_for_admin(order_id)
        old_status = order.status

        if old_status == new_status.value:
            return order

        allowed = VALID_TRANSITIONS.get(old_status, [])
        if new_status.value not in allowed:
            raise BadRequestException(
                f"Invalid status transition from '{old_status}' to '{new_status.value}'. Allowed transitions: {allowed}",
                code="INVALID_STATUS_TRANSITION",
            )

        # Restore stock if admin cancels
        if new_status == OrderStatus.CANCELLED:
            for item in order.items:
                product = self.product_repo.get_by_id(item.product_id)
                if product and product.stock_quantity is not None:
                    product.stock_quantity += item.quantity

        order.status = new_status.value

        history = OrderStatusHistory(
            order_id=order.id,
            old_status=old_status,
            new_status=new_status.value,
            changed_by_user_id=admin_id,
            comment=comment or f"Status changed to {new_status.value} by admin.",
        )
        self.order_repo.add_status_history(history)
        return self.order_repo.update(order)
