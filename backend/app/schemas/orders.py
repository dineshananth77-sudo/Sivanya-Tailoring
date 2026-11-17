from decimal import Decimal
from datetime import datetime
from typing import Optional, List, Dict, Any
import uuid
from pydantic import BaseModel, ConfigDict, Field

from app.models.order import OrderStatus


# ---------------- Address Schemas ----------------

class AddressBase(BaseModel):
    recipient_name: str = Field(..., min_length=2, max_length=150)
    phone: str = Field(..., min_length=7, max_length=30)
    street: str = Field(..., min_length=3, max_length=255)
    city: str = Field(..., min_length=2, max_length=100)
    state: str = Field(..., min_length=2, max_length=100)
    postal_code: str = Field(..., min_length=3, max_length=20)
    is_default: bool = False


class AddressCreate(AddressBase):
    model_config = ConfigDict(extra="forbid")


class AddressUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    recipient_name: Optional[str] = Field(None, min_length=2, max_length=150)
    phone: Optional[str] = Field(None, min_length=7, max_length=30)
    street: Optional[str] = Field(None, min_length=3, max_length=255)
    city: Optional[str] = Field(None, min_length=2, max_length=100)
    state: Optional[str] = Field(None, min_length=2, max_length=100)
    postal_code: Optional[str] = Field(None, min_length=3, max_length=20)
    is_default: Optional[bool] = None


class AddressResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    customer_id: uuid.UUID
    recipient_name: str
    phone: str
    street: str
    city: str
    state: str
    postal_code: str
    is_default: bool
    created_at: datetime
    updated_at: datetime


# ---------------- Delivery Schemas ----------------

class DeliverySettingsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    is_free_delivery_active: bool
    free_delivery_threshold: Optional[Decimal] = None
    default_delivery_charge: Decimal
    updated_at: datetime


class DeliverySettingsUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    is_free_delivery_active: Optional[bool] = None
    free_delivery_threshold: Optional[Decimal] = Field(None, ge=0)
    default_delivery_charge: Optional[Decimal] = Field(None, ge=0)


class DeliveryRuleCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(..., min_length=2, max_length=100)
    min_order_amount: Decimal = Field(default=Decimal("0.00"), ge=0)
    max_order_amount: Optional[Decimal] = Field(None, ge=0)
    charge: Decimal = Field(..., ge=0)
    priority: int = 0
    is_active: bool = True


class DeliveryRuleUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: Optional[str] = Field(None, min_length=2, max_length=100)
    min_order_amount: Optional[Decimal] = Field(None, ge=0)
    max_order_amount: Optional[Decimal] = Field(None, ge=0)
    charge: Optional[Decimal] = Field(None, ge=0)
    priority: Optional[int] = None
    is_active: Optional[bool] = None


class DeliveryRuleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    min_order_amount: Decimal
    max_order_amount: Optional[Decimal] = None
    charge: Decimal
    priority: int
    is_active: bool
    created_at: datetime


class DeliveryQuoteRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    subtotal: Decimal = Field(..., ge=0)


class DeliveryQuoteResponse(BaseModel):
    subtotal: Decimal
    delivery_charge: Decimal
    total: Decimal
    is_free_delivery: bool
    applied_rule: Optional[str] = None


# ---------------- Order Schemas ----------------

class OrderItemCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    product_id: uuid.UUID
    quantity: int = Field(..., gt=0, le=100)


class OrderCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    address_id: uuid.UUID
    items: List[OrderItemCreate] = Field(..., min_length=1)
    note: Optional[str] = Field(None, max_length=1000)


class OrderItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    product_id: uuid.UUID
    product_name_snapshot: str
    unit_price_snapshot: Decimal
    quantity: int
    line_total: Decimal


class OrderStatusHistoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    old_status: Optional[str] = None
    new_status: str
    changed_by_user_id: Optional[uuid.UUID] = None
    comment: Optional[str] = None
    created_at: datetime


class OrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    order_number: str
    customer_id: uuid.UUID
    status: str
    subtotal: Decimal
    delivery_charge: Decimal
    total: Decimal
    delivery_address_snapshot: Dict[str, Any]
    note: Optional[str] = None
    items: List[OrderItemResponse] = []
    created_at: datetime
    updated_at: datetime


class OrderDetailResponse(OrderResponse):
    status_history: List[OrderStatusHistoryResponse] = []


class PaginatedOrdersResponse(BaseModel):
    items: List[OrderResponse]
    total: int
    page: int
    limit: int
    total_pages: int


class OrderStatusUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    status: OrderStatus
    comment: Optional[str] = Field(None, max_length=500)
