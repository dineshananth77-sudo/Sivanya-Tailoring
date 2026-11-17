import uuid
from decimal import Decimal
from typing import Optional, List, Tuple
from sqlalchemy import select, func, desc, update
from sqlalchemy.orm import Session, selectinload

from app.models.address import Address
from app.models.delivery import DeliverySettings, DeliveryRule
from app.models.order import Order, OrderItem, OrderStatusHistory


class AddressRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, address_id: uuid.UUID) -> Optional[Address]:
        return self.db.execute(
            select(Address).where(Address.id == address_id)
        ).scalar_one_or_none()

    def list_by_customer(self, customer_id: uuid.UUID) -> List[Address]:
        return list(
            self.db.execute(
                select(Address)
                .where(Address.customer_id == customer_id)
                .order_by(Address.is_default.desc(), Address.created_at.desc())
            ).scalars().all()
        )

    def get_default(self, customer_id: uuid.UUID) -> Optional[Address]:
        return self.db.execute(
            select(Address).where(
                Address.customer_id == customer_id, Address.is_default == True
            )
        ).scalar_one_or_none()

    def create(self, address: Address) -> Address:
        if address.is_default:
            self._unset_default_for_customer(address.customer_id)
        self.db.add(address)
        self.db.commit()
        self.db.refresh(address)
        return address

    def update(self, address: Address) -> Address:
        if address.is_default:
            self._unset_default_for_customer(address.customer_id, exclude_id=address.id)
        self.db.commit()
        self.db.refresh(address)
        return address

    def set_default(self, customer_id: uuid.UUID, address_id: uuid.UUID) -> Address:
        self._unset_default_for_customer(customer_id)
        addr = self.get_by_id(address_id)
        if addr:
            addr.is_default = True
            self.db.commit()
            self.db.refresh(addr)
        return addr

    def delete(self, address: Address) -> None:
        self.db.delete(address)
        self.db.commit()

    def _unset_default_for_customer(self, customer_id: uuid.UUID, exclude_id: Optional[uuid.UUID] = None) -> None:
        query = update(Address).where(Address.customer_id == customer_id)
        if exclude_id:
            query = query.where(Address.id != exclude_id)
        query = query.values(is_default=False)
        self.db.execute(query)


class DeliveryRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_settings(self) -> DeliverySettings:
        settings = self.db.execute(select(DeliverySettings)).scalar_one_or_none()
        if not settings:
            settings = DeliverySettings(
                is_free_delivery_active=False,
                free_delivery_threshold=None,
                default_delivery_charge=Decimal("50.00"),
            )
            self.db.add(settings)
            self.db.commit()
            self.db.refresh(settings)
        return settings

    def update_settings(self, settings: DeliverySettings) -> DeliverySettings:
        self.db.commit()
        self.db.refresh(settings)
        return settings

    def list_rules(self, active_only: bool = True) -> List[DeliveryRule]:
        query = select(DeliveryRule)
        if active_only:
            query = query.where(DeliveryRule.is_active == True)
        query = query.order_by(DeliveryRule.priority.desc(), DeliveryRule.min_order_amount.asc())
        return list(self.db.execute(query).scalars().all())

    def get_rule_by_id(self, rule_id: uuid.UUID) -> Optional[DeliveryRule]:
        return self.db.execute(
            select(DeliveryRule).where(DeliveryRule.id == rule_id)
        ).scalar_one_or_none()

    def create_rule(self, rule: DeliveryRule) -> DeliveryRule:
        self.db.add(rule)
        self.db.commit()
        self.db.refresh(rule)
        return rule

    def update_rule(self, rule: DeliveryRule) -> DeliveryRule:
        self.db.commit()
        self.db.refresh(rule)
        return rule

    def delete_rule(self, rule: DeliveryRule) -> None:
        self.db.delete(rule)
        self.db.commit()


class OrderRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, order_id: uuid.UUID) -> Optional[Order]:
        return self.db.execute(
            select(Order)
            .options(
                selectinload(Order.items),
                selectinload(Order.status_history),
            )
            .where(Order.id == order_id)
        ).scalar_one_or_none()

    def get_by_order_number(self, order_number: str) -> Optional[Order]:
        return self.db.execute(
            select(Order)
            .options(
                selectinload(Order.items),
                selectinload(Order.status_history),
            )
            .where(Order.order_number == order_number)
        ).scalar_one_or_none()

    def list_paginated(
        self,
        customer_id: Optional[uuid.UUID] = None,
        status: Optional[str] = None,
        search: Optional[str] = None,
        page: int = 1,
        limit: int = 20,
    ) -> Tuple[List[Order], int]:
        query = select(Order).options(
            selectinload(Order.items),
            selectinload(Order.status_history),
        )

        if customer_id:
            query = query.where(Order.customer_id == customer_id)
        if status:
            query = query.where(Order.status == status)
        if search:
            query = query.where(Order.order_number.ilike(f"%{search.strip()}%"))

        count_query = select(func.count()).select_from(query.order_by(None).subquery())
        total = self.db.execute(count_query).scalar_one()

        query = query.order_by(desc(Order.created_at))
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit)

        items = list(self.db.execute(query).scalars().all())
        return items, total

    def create(self, order: Order) -> Order:
        self.db.add(order)
        self.db.commit()
        self.db.refresh(order)
        return self.get_by_id(order.id) or order

    def update(self, order: Order) -> Order:
        self.db.commit()
        self.db.refresh(order)
        return self.get_by_id(order.id) or order

    def add_status_history(self, history: OrderStatusHistory) -> OrderStatusHistory:
        self.db.add(history)
        self.db.commit()
        self.db.refresh(history)
        return history
