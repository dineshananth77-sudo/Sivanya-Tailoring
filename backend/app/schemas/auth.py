import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict, EmailStr, Field


class RegisterRequest(BaseModel):
    """Registration schema: strictly forbids client injection of role or extra fields."""
    model_config = ConfigDict(extra="forbid")

    full_name: str = Field(..., min_length=2, max_length=100, description="Customer full name")
    email: EmailStr = Field(..., description="Unique customer email address")
    password: str = Field(..., min_length=8, max_length=128, description="Plaintext password (min 8 characters)")
    phone: str | None = Field(default=None, max_length=20, description="Optional phone number")


class LoginRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    email: EmailStr = Field(..., description="Registered email address")
    password: str = Field(..., min_length=1, description="Account password")


class RefreshTokenRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    refresh_token: str = Field(..., min_length=10, description="Raw refresh token string")


class ChangePasswordRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    current_password: str = Field(..., min_length=1, description="Current account password")
    new_password: str = Field(..., min_length=8, max_length=128, description="New account password (min 8 characters)")


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    full_name: str
    phone: str | None
    role: str
    is_active: bool
    created_at: datetime


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse
