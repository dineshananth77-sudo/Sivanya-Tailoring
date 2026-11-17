from decimal import Decimal
from typing import Optional, List
import uuid
from sqlalchemy.orm import Session

from app.models.delivery import DeliverySettings, DeliveryRule
from app.repositories.order_repo import DeliveryRepository
from app.schemas.orders import (
    DeliveryQuoteResponse,
    DeliverySettingsUpdate,
    DeliveryRuleCreate,
    DeliveryRuleUpdate,
)
from app.exceptions import NotFoundException


class DeliveryService:
    def __init__(self, db: Session):
        self.db = db
        self.delivery_repo = DeliveryRepository(db)

    def calculate_quote(self, subtotal: Decimal) -> DeliveryQuoteResponse:
        settings = self.delivery_repo.get_settings()
        rules = self.delivery_repo.list_rules(active_only=True)

        # 1. Check Global Free Delivery Threshold
        if settings.is_free_delivery_active:
            if settings.free_delivery_threshold is not None and subtotal >= settings.free_delivery_threshold:
                return DeliveryQuoteResponse(
                    subtotal=subtotal,
                    delivery_charge=Decimal("0.00"),
                    total=subtotal,
                    is_free_delivery=True,
                    applied_rule="Free Delivery Threshold",
                )

        # 2. Check Custom Rules by Priority
        for rule in rules:
            min_ok = subtotal >= rule.min_order_amount
            max_ok = (rule.max_order_amount is None) or (subtotal <= rule.max_order_amount)
            if min_ok and max_ok:
                is_free = rule.charge == Decimal("0.00")
                return DeliveryQuoteResponse(
                    subtotal=subtotal,
                    delivery_charge=rule.charge,
                    total=subtotal + rule.charge,
                    is_free_delivery=is_free,
                    applied_rule=rule.name,
                )

        # 3. Fallback to Default Charge
        charge = settings.default_delivery_charge
        is_free = charge == Decimal("0.00")
        return DeliveryQuoteResponse(
            subtotal=subtotal,
            delivery_charge=charge,
            total=subtotal + charge,
            is_free_delivery=is_free,
            applied_rule="Default Delivery Charge",
        )

    def get_settings(self) -> DeliverySettings:
        return self.delivery_repo.get_settings()

    def update_settings(self, payload: DeliverySettingsUpdate) -> DeliverySettings:
        settings = self.delivery_repo.get_settings()
        if payload.is_free_delivery_active is not None:
            settings.is_free_delivery_active = payload.is_free_delivery_active
        if payload.free_delivery_threshold is not None:
            settings.free_delivery_threshold = payload.free_delivery_threshold
        if payload.default_delivery_charge is not None:
            settings.default_delivery_charge = payload.default_delivery_charge
        return self.delivery_repo.update_settings(settings)

    def list_rules(self, active_only: bool = False) -> List[DeliveryRule]:
        return self.delivery_repo.list_rules(active_only=active_only)

    def create_rule(self, payload: DeliveryRuleCreate) -> DeliveryRule:
        rule = DeliveryRule(
            name=payload.name,
            min_order_amount=payload.min_order_amount,
            max_order_amount=payload.max_order_amount,
            charge=payload.charge,
            priority=payload.priority,
            is_active=payload.is_active,
        )
        return self.delivery_repo.create_rule(rule)

    def update_rule(self, rule_id: uuid.UUID, payload: DeliveryRuleUpdate) -> DeliveryRule:
        rule = self.delivery_repo.get_rule_by_id(rule_id)
        if not rule:
            raise NotFoundException(f"Delivery rule '{rule_id}' not found.", code="RULE_NOT_FOUND")

        if payload.name is not None:
            rule.name = payload.name
        if payload.min_order_amount is not None:
            rule.min_order_amount = payload.min_order_amount
        if payload.max_order_amount is not None:
            rule.max_order_amount = payload.max_order_amount
        if payload.charge is not None:
            rule.charge = payload.charge
        if payload.priority is not None:
            rule.priority = payload.priority
        if payload.is_active is not None:
            rule.is_active = payload.is_active

        return self.delivery_repo.update_rule(rule)

    def delete_rule(self, rule_id: uuid.UUID) -> None:
        rule = self.delivery_repo.get_rule_by_id(rule_id)
        if not rule:
            raise NotFoundException(f"Delivery rule '{rule_id}' not found.", code="RULE_NOT_FOUND")
        self.delivery_repo.delete_rule(rule)
