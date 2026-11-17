import uuid
from datetime import datetime, timedelta, timezone
from typing import Tuple
from sqlalchemy.orm import Session

from app.config import get_settings
from app.exceptions import (
    BadRequestException,
    ConflictException,
    ForbiddenException,
    UnauthorizedException,
)
from app.models.user import User, UserRole
from app.repositories.token_repo import TokenRepository
from app.repositories.user_repo import UserRepository
from app.schemas.auth import (
    ChangePasswordRequest,
    LoginRequest,
    RegisterRequest,
)
from app.security.jwt import create_access_token
from app.security.password import hash_password, needs_rehash, verify_password
from app.security.tokens import generate_secure_token, hash_token


class AuthService:
    def __init__(self, db: Session):
        self.db = db
        self.settings = get_settings()

    def _create_refresh_token_for_user(
        self,
        user_id: uuid.UUID,
        family_id: uuid.UUID | None = None
    ) -> Tuple[str, datetime]:
        """Generates, hashes and stores a new refresh token in the database."""
        raw_token = generate_secure_token(48)
        token_hash = hash_token(raw_token)
        family = family_id or uuid.uuid4()
        expires_at = datetime.now(timezone.utc) + timedelta(days=self.settings.REFRESH_TOKEN_EXPIRE_DAYS)

        TokenRepository.create_refresh_token(
            db=self.db,
            user_id=user_id,
            token_hash=token_hash,
            family_id=family,
            expires_at=expires_at
        )
        return raw_token, expires_at

    def register(self, data: RegisterRequest) -> Tuple[str, str, User]:
        """Registers a new customer. Role is strictly hardcoded to customer."""
        existing = UserRepository.get_by_email(self.db, data.email)
        if existing:
            raise ConflictException(
                code="EMAIL_ALREADY_EXISTS",
                message="An account with this email address is already registered."
            )

        password_hash = hash_password(data.password)
        user = UserRepository.create_user(
            db=self.db,
            email=data.email,
            password_hash=password_hash,
            full_name=data.full_name,
            phone=data.phone,
            role=UserRole.CUSTOMER.value,
            is_active=True
        )

        access_token = create_access_token(user.id, user.role)
        raw_refresh_token, _ = self._create_refresh_token_for_user(user.id)
        self.db.commit()

        return access_token, raw_refresh_token, user

    def login(self, data: LoginRequest) -> Tuple[str, str, User]:
        """Unified login for customers and admins with generic error response."""
        user = UserRepository.get_by_email(self.db, data.email)
        generic_error = UnauthorizedException(
            code="INVALID_CREDENTIALS",
            message="Invalid email or password."
        )

        if not user:
            raise generic_error

        if not verify_password(data.password, user.password_hash):
            raise generic_error

        if not user.is_active:
            raise ForbiddenException(
                code="ACCOUNT_INACTIVE",
                message="This account has been deactivated. Please contact support."
            )

        # Silent hash upgrade if Argon2 parameters have changed
        if needs_rehash(user.password_hash):
            UserRepository.update_password(self.db, user, hash_password(data.password))

        access_token = create_access_token(user.id, user.role)
        raw_refresh_token, _ = self._create_refresh_token_for_user(user.id)
        self.db.commit()

        return access_token, raw_refresh_token, user

    def refresh(self, raw_refresh_token: str) -> Tuple[str, str, User]:
        """Rotates refresh token and detects token reuse attacks."""
        token_hash = hash_token(raw_refresh_token)
        stored_token = TokenRepository.get_by_hash(self.db, token_hash)

        if not stored_token:
            raise UnauthorizedException(
                code="INVALID_REFRESH_TOKEN",
                message="Refresh token is invalid or does not exist."
            )

        # Token Reuse Detection: If this token was already revoked, someone is replaying it!
        if stored_token.is_revoked:
            TokenRepository.revoke_family(self.db, stored_token.family_id)
            self.db.commit()
            raise UnauthorizedException(
                code="TOKEN_REUSE_DETECTED",
                message="Security alert: Token reuse detected. All active sessions have been invalidated."
            )

        # Check Expiration
        if stored_token.is_expired:
            TokenRepository.revoke_token(self.db, stored_token)
            self.db.commit()
            raise UnauthorizedException(
                code="REFRESH_TOKEN_EXPIRED",
                message="Refresh token has expired. Please log in again."
            )

        user = stored_token.user
        if not user or not user.is_active:
            TokenRepository.revoke_token(self.db, stored_token)
            self.db.commit()
            raise ForbiddenException(
                code="ACCOUNT_INACTIVE",
                message="This user account is no longer active."
            )

        # Rotate: Revoke used token and issue new token in the same family
        TokenRepository.revoke_token(self.db, stored_token)
        new_access_token = create_access_token(user.id, user.role)
        new_raw_refresh, _ = self._create_refresh_token_for_user(
            user.id,
            family_id=stored_token.family_id
        )
        self.db.commit()

        return new_access_token, new_raw_refresh, user

    def logout(self, raw_refresh_token: str) -> None:
        """Revokes the given refresh token."""
        token_hash = hash_token(raw_refresh_token)
        stored_token = TokenRepository.get_by_hash(self.db, token_hash)
        if stored_token and not stored_token.is_revoked:
            TokenRepository.revoke_token(self.db, stored_token)
            self.db.commit()

    def change_password(self, user: User, data: ChangePasswordRequest) -> None:
        """Verifies current password and updates to new Argon2id hash."""
        if not verify_password(data.current_password, user.password_hash):
            raise BadRequestException(
                code="INVALID_CURRENT_PASSWORD",
                message="The current password provided is incorrect."
            )

        if data.current_password == data.new_password:
            raise BadRequestException(
                code="PASSWORD_IDENTICAL",
                message="New password cannot be identical to current password."
            )

        new_hash = hash_password(data.new_password)
        UserRepository.update_password(self.db, user, new_hash)

        # Revoke all refresh tokens for this user upon password change
        for token in user.refresh_tokens:
            if not token.is_revoked:
                TokenRepository.revoke_token(self.db, token)

        self.db.commit()
