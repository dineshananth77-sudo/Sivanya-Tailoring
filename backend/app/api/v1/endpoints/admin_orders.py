from typing import Optional, List
import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.api.deps import require_admin
from app.models.user import User
from app.services.order_service import OrderService
from app.services.delivery_service import DeliveryService
from app.schemas.orders import (
    OrderDetailResponse,
    PaginatedOrdersResponse,
    OrderStatusUpdateRequest,
    DeliverySettingsResponse,
    DeliverySettingsUpdate,
    DeliveryRuleCreate,
    DeliveryRuleUpdate,
    DeliveryRuleResponse,
)

router = APIRouter(prefix="/admin", tags=["Admin Orders & Delivery"])


# ================= Admin Orders =================

@router.get("/orders", response_model=PaginatedOrdersResponse, summary="List all orders (Admin)")
def admin_list_orders(
    status: Optional[str] = Query(None, description="Filter by status"),
    search: Optional[str] = Query(None, description="Search by order number"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = OrderService(db)
    return service.list_orders_for_admin(status=status, search=search, page=page, limit=limit)


@router.get("/orders/{order_id}", response_model=OrderDetailResponse, summary="Get order details (Admin)")
def admin_get_order(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = OrderService(db)
    return service.get_order_for_admin(order_id)


@router.patch("/orders/{order_id}/status", response_model=OrderDetailResponse, summary="Update order status (Admin)")
def admin_update_order_status(
    order_id: uuid.UUID,
    payload: OrderStatusUpdateRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = OrderService(db)
    return service.update_order_status_by_admin(
        order_id=order_id,
        new_status=payload.status,
        admin_id=admin.id,
        comment=payload.comment,
    )


# ================= Admin Delivery Settings =================

@router.get("/delivery/settings", response_model=DeliverySettingsResponse, summary="Get delivery settings (Admin)")
def admin_get_delivery_settings(
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = DeliveryService(db)
    return service.get_settings()


@router.put("/delivery/settings", response_model=DeliverySettingsResponse, summary="Update delivery settings (Admin)")
def admin_update_delivery_settings(
    payload: DeliverySettingsUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = DeliveryService(db)
    return service.update_settings(payload)


# ================= Admin Delivery Rules =================

@router.get("/delivery/rules", response_model=List[DeliveryRuleResponse], summary="List delivery rules (Admin)")
def admin_list_delivery_rules(
    active_only: bool = Query(False),
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = DeliveryService(db)
    return service.list_rules(active_only=active_only)


@router.post("/delivery/rules", response_model=DeliveryRuleResponse, status_code=status.HTTP_201_CREATED, summary="Create delivery rule (Admin)")
def admin_create_delivery_rule(
    payload: DeliveryRuleCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = DeliveryService(db)
    return service.create_rule(payload)


@router.put("/delivery/rules/{rule_id}", response_model=DeliveryRuleResponse, summary="Update delivery rule (Admin)")
def admin_update_delivery_rule(
    rule_id: uuid.UUID,
    payload: DeliveryRuleUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = DeliveryService(db)
    return service.update_rule(rule_id, payload)


@router.delete("/delivery/rules/{rule_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete delivery rule (Admin)")
def admin_delete_delivery_rule(
    rule_id: uuid.UUID,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    service = DeliveryService(db)
    service.delete_rule(rule_id)
    return None
