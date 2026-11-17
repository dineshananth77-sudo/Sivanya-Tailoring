from typing import Annotated
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.auth import (
    ChangePasswordRequest,
    LoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)
from app.security.rate_limiter import rate_limit
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(rate_limit(max_requests=10, window_seconds=60, scope="register"))],
    summary="Register a new customer account"
)
def register(
    data: RegisterRequest,
    db: Annotated[Session, Depends(get_db)]
):
    """
    Registers a new customer.
    The role is strictly enforced by the backend as 'customer'.
    Any client attempt to specify a role field is rejected with a 422 error.
    """
    service = AuthService(db)
    access_token, refresh_token, user = service.register(data)
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(rate_limit(max_requests=15, window_seconds=60, scope="login"))],
    summary="Unified login for customers and admins"
)
def login(
    data: LoginRequest,
    db: Annotated[Session, Depends(get_db)]
):
    """
    Authenticates both customers and admins.
    Returns access token, rotating refresh token, and the user profile including role.
    """
    service = AuthService(db)
    access_token, refresh_token, user = service.login(data)
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )


@router.post(
    "/refresh",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Rotate refresh token and obtain new access token"
)
def refresh_token(
    data: RefreshTokenRequest,
    db: Annotated[Session, Depends(get_db)]
):
    """
    Rotates the refresh token. If a previously revoked token is reused,
    the entire token family is immediately revoked as a security measure.
    """
    service = AuthService(db)
    access_token, new_refresh_token, user = service.refresh(data.refresh_token)
    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )


@router.post(
    "/logout",
    status_code=status.HTTP_200_OK,
    summary="Revoke refresh token and terminate session"
)
def logout(
    data: RefreshTokenRequest,
    db: Annotated[Session, Depends(get_db)]
):
    """Revokes the given refresh token in PostgreSQL."""
    service = AuthService(db)
    service.logout(data.refresh_token)
    return {"message": "Logged out successfully."}


@router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Get currently authenticated user profile and role"
)
def get_current_user_profile(
    current_user: Annotated[User, Depends(get_current_user)]
):
    """Returns the profile and role of the authenticated customer or admin."""
    return UserResponse.model_validate(current_user)


@router.post(
    "/change-password",
    status_code=status.HTTP_200_OK,
    summary="Change password for authenticated user"
)
def change_password(
    data: ChangePasswordRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """Verifies the old password and sets the new password using Argon2id."""
    service = AuthService(db)
    service.change_password(current_user, data)
    return {"message": "Password updated successfully."}
