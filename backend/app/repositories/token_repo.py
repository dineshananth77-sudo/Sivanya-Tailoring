import uuid
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.models.token import RefreshToken


class TokenRepository:
    @staticmethod
    def create_refresh_token(
        db: Session,
        user_id: uuid.UUID,
        token_hash: str,
        family_id: uuid.UUID,
        expires_at: datetime
    ) -> RefreshToken:
        token = RefreshToken(
            user_id=user_id,
            token_hash=token_hash,
            family_id=family_id,
            expires_at=expires_at
        )
        db.add(token)
        db.flush()
        return token

    @staticmethod
    def get_by_hash(db: Session, token_hash: str) -> Optional[RefreshToken]:
        stmt = select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        return db.execute(stmt).scalar_one_or_none()

    @staticmethod
    def revoke_token(db: Session, token: RefreshToken) -> None:
        token.revoked_at = datetime.now(timezone.utc)
        db.flush()

    @staticmethod
    def revoke_family(db: Session, family_id: uuid.UUID) -> int:
        """Revokes all tokens belonging to a family when reuse is detected."""
        now = datetime.now(timezone.utc)
        stmt = (
            update(RefreshToken)
            .where(RefreshToken.family_id == family_id)
            .where(RefreshToken.revoked_at.is_(None))
            .values(revoked_at=now)
        )
        result = db.execute(stmt)
        db.flush()
        return result.rowcount
