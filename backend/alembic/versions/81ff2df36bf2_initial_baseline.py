"""initial_baseline

Revision ID: 81ff2df36bf2
Revises: 
Create Date: 2026-11-15 09:42:23.550424

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '81ff2df36bf2'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema - enable pgcrypto extension for UUID generation."""
    op.execute('CREATE EXTENSION IF NOT EXISTS "pgcrypto";')


def downgrade() -> None:
    """Downgrade schema."""
    pass
