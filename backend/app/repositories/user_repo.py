import uuid
from typing import Optional
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.user import User, UserRole


class UserRepository:
    @staticmethod
    def get_by_id(db: Session, user_id: uuid.UUID) -> Optional[User]:
        return db.get(User, user_id)

    @staticmethod
    def get_by_email(db: Session, email: str) -> Optional[User]:
        stmt = select(User).where(func.lower(User.email) == email.lower().strip())
        return db.execute(stmt).scalar_one_or_none()

    @staticmethod
    def create_user(
        db: Session,
        email: str,
        password_hash: str,
        full_name: str,
        phone: Optional[str] = None,
        role: str = UserRole.CUSTOMER.value,
        is_active: bool = True
    ) -> User:
        user = User(
            email=email.lower().strip(),
            password_hash=password_hash,
            full_name=full_name.strip(),
            phone=phone.strip() if phone else None,
            role=role,
            is_active=is_active
        )
        db.add(user)
        db.flush()
        return user

    @staticmethod
    def update_password(db: Session, user: User, new_password_hash: str) -> None:
        user.password_hash = new_password_hash
        db.flush()

    @staticmethod
    def update_profile(
        db: Session,
        user: User,
        full_name: str,
        phone: Optional[str] = None
    ) -> User:
        user.full_name = full_name.strip()
        user.phone = phone.strip() if phone else None
        db.flush()
        return user
