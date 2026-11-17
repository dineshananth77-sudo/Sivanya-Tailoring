from fastapi import APIRouter
from app.api.v1.endpoints import (
    health,
    auth,
    admin,
    catalog,
    admin_catalog,
    addresses,
    delivery,
    orders,
    admin_orders,
    reviews,
    admin_reviews,
)

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(catalog.router)
api_router.include_router(addresses.router)
api_router.include_router(delivery.router)
api_router.include_router(orders.router)
api_router.include_router(reviews.router)
api_router.include_router(admin.router)
api_router.include_router(admin_catalog.router)
api_router.include_router(admin_orders.router)
api_router.include_router(admin_reviews.router)
