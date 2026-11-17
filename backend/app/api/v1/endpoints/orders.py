import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.order_service import OrderService
from app.schemas.orders import (
    OrderCreate,
    OrderResponse,
    OrderDetailResponse,
    PaginatedOrdersResponse,
)

router = APIRouter(prefix="/orders", tags=["Orders"])


@router.post("", response_model=OrderDetailResponse, status_code=status.HTTP_201_CREATED, summary="Place order")
def place_order(
    payload: OrderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrderService(db)
    return service.create_order(customer_id=current_user.id, payload=payload)


@router.get("", response_model=PaginatedOrdersResponse, summary="List my orders")
def list_my_orders(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrderService(db)
    return service.list_orders_for_customer(customer_id=current_user.id, page=page, limit=limit)


@router.get("/{order_id}", response_model=OrderDetailResponse, summary="Get my order details")
def get_my_order(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrderService(db)
    return service.get_order_for_customer(order_id=order_id, customer_id=current_user.id)


@router.post("/{order_id}/cancel", response_model=OrderDetailResponse, summary="Cancel my pending order")
def cancel_my_order(
    order_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrderService(db)
    return service.cancel_order_by_customer(order_id=order_id, customer_id=current_user.id)
