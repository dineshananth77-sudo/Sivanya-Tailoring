from typing import Annotated
from fastapi import APIRouter, Depends, status

from app.api.deps import require_admin
from app.models.user import User
from app.schemas.auth import UserResponse

router = APIRouter(prefix="/admin", tags=["Admin (Foundation)"])


@router.get(
    "/ping",
    status_code=status.HTTP_200_OK,
    summary="Admin verification probe"
)
def admin_ping(
    admin: Annotated[User, Depends(require_admin)]
):
    """Probe endpoint verifying caller possesses the admin role."""
    return {
        "message": "Admin authorization verified.",
        "admin": UserResponse.model_validate(admin)
    }
