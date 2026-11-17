from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.delivery_service import DeliveryService
from app.schemas.orders import DeliveryQuoteRequest, DeliveryQuoteResponse

router = APIRouter(prefix="/delivery", tags=["Delivery"])


@router.post("/quote", response_model=DeliveryQuoteResponse, summary="Get delivery charge quote")
def get_delivery_quote(
    payload: DeliveryQuoteRequest,
    db: Session = Depends(get_db),
):
    service = DeliveryService(db)
    return service.calculate_quote(payload.subtotal)
