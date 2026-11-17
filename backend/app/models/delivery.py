import uuid
from decimal import Decimal
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import (
    String,
    Boolean,
    Integer,
    Numeric,
    DateTime,
    CheckConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class DeliverySettings(Base):
    __tablename__ = "delivery_settings"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    is_free_delivery_active: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    free_delivery_threshold: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(10, 2), nullable=True
    )
    default_delivery_charge: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), default=Decimal("50.00"), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        CheckConstraint("default_delivery_charge >= 0", name="chk_default_delivery_charge_positive"),
        CheckConstraint(
            "free_delivery_threshold IS NULL OR free_delivery_threshold >= 0",
            name="chk_free_delivery_threshold_positive",
        ),
    )


class DeliveryRule(Base):
    __tablename__ = "delivery_rules"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    min_order_amount: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), default=Decimal("0.00"), nullable=False
    )
    max_order_amount: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(10, 2), nullable=True
    )
    charge: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    priority: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        CheckConstraint("min_order_amount >= 0", name="chk_rule_min_positive"),
        CheckConstraint(
            "max_order_amount IS NULL OR max_order_amount >= min_order_amount",
            name="chk_rule_max_gte_min",
        ),
        CheckConstraint("charge >= 0", name="chk_rule_charge_positive"),
    )
