import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict
import jwt

from app.config import get_settings
from app.exceptions import UnauthorizedException


def create_access_token(user_id: uuid.UUID, role: str) -> str:
    """Creates a signed, short-lived JWT access token."""
    settings = get_settings()
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    payload: Dict[str, Any] = {
        "sub": str(user_id),
        "role": role,
        "type": "access",
        "jti": str(uuid.uuid4()),
        "iat": int(now.timestamp()),
        "nbf": int(now.timestamp()),
        "exp": int(expires_at.timestamp()),
    }

    token = jwt.encode(
        payload,
        settings.JWT_SECRET,
        algorithm=settings.JWT_ALGORITHM
    )
    return token


def decode_access_token(token: str) -> Dict[str, Any]:
    """Decodes and validates a JWT access token."""
    settings = get_settings()
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM],
            options={"require": ["sub", "role", "exp", "type"]}
        )

        if payload.get("type") != "access":
            raise UnauthorizedException(
                code="INVALID_TOKEN_TYPE",
                message="Invalid token type. Expected access token."
            )

        return payload

    except jwt.ExpiredSignatureError:
        raise UnauthorizedException(
            code="TOKEN_EXPIRED",
            message="Access token has expired. Please refresh your session."
        )
    except jwt.InvalidTokenError as e:
        raise UnauthorizedException(
            code="INVALID_TOKEN",
            message=f"Invalid authentication token: {str(e)}"
        )
