from typing import List
import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.order_service import OrderService
from app.schemas.orders import (
    AddressCreate,
    AddressUpdate,
    AddressResponse,
)

router = APIRouter(prefix="/addresses", tags=["Addresses"])


@router.get("", response_model=List[AddressResponse], summary="List my addresses")
def list_my_addresses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrderService(db)
    return service.list_addresses(customer_id=current_user.id)


@router.post("", response_model=AddressResponse, status_code=status.HTTP_201_CREATED, summary="Create address")
def create_address(
    payload: AddressCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrderService(db)
    return service.create_address(customer_id=current_user.id, payload=payload)


@router.get("/{address_id}", response_model=AddressResponse, summary="Get address")
def get_address(
    address_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrderService(db)
    return service.get_address(address_id=address_id, customer_id=current_user.id)


@router.put("/{address_id}", response_model=AddressResponse, summary="Update address")
def update_address(
    address_id: uuid.UUID,
    payload: AddressUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrderService(db)
    return service.update_address(address_id=address_id, customer_id=current_user.id, payload=payload)


@router.patch("/{address_id}/default", response_model=AddressResponse, summary="Set address as default")
def set_default_address(
    address_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrderService(db)
    return service.set_default_address(address_id=address_id, customer_id=current_user.id)


@router.delete("/{address_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete address")
def delete_address(
    address_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = OrderService(db)
    service.delete_address(address_id=address_id, customer_id=current_user.id)
    return None
