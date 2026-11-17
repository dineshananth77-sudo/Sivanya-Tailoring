import uuid
from typing import Annotated
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.database import get_db
from app.exceptions import ForbiddenException, UnauthorizedException
from app.models.user import User, UserRole
from app.repositories.user_repo import UserRepository
from app.security.jwt import decode_access_token

security = HTTPBearer(auto_error=True)


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
    db: Annotated[Session, Depends(get_db)]
) -> User:
    """
    Dependency that decodes the access token, verifies signature and expiry,
    and looks up the active user in the database on every request.
    """
    token = credentials.credentials
    payload = decode_access_token(token)

    try:
        user_id = uuid.UUID(payload["sub"])
    except (ValueError, KeyError, TypeError):
        raise UnauthorizedException(
            code="INVALID_TOKEN_PAYLOAD",
            message="Token payload is malformed."
        )

    user = UserRepository.get_by_id(db, user_id)
    if not user:
        raise UnauthorizedException(
            code="USER_NOT_FOUND",
            message="User account no longer exists."
        )

    if not user.is_active:
        raise ForbiddenException(
            code="ACCOUNT_INACTIVE",
            message="User account is deactivated."
        )

    return user


def require_customer(
    current_user: Annotated[User, Depends(get_current_user)]
) -> User:
    """Dependency verifying the caller is an active customer or admin."""
    if current_user.role not in [UserRole.CUSTOMER.value, UserRole.ADMIN.value]:
        raise ForbiddenException(
            code="FORBIDDEN",
            message="Insufficient permissions for customer operation."
        )
    return current_user


def require_admin(
    current_user: Annotated[User, Depends(get_current_user)]
) -> User:
    """Dependency strictly enforcing that the caller has the admin role."""
    if current_user.role != UserRole.ADMIN.value:
        raise ForbiddenException(
            code="FORBIDDEN_ADMIN_ONLY",
            message="Administrative privileges required to access this resource."
        )
    return current_user
