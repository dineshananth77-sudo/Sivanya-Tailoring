import pytest
from pydantic import ValidationError
from app.config import Settings


def test_valid_settings():
    """Confirms that valid settings initialize without error."""
    valid_data = {
        "DATABASE_URL": "postgresql+psycopg://test_user:test_pass@localhost:5432/test_db",
        "JWT_SECRET": "a" * 32,
        "CLOUDINARY_CLOUD_NAME": "test_cloud",
        "CLOUDINARY_API_KEY": "123456789",
        "CLOUDINARY_API_SECRET": "secret_key_abc",
        "_env_file": None  # Disable auto-loading from disk for isolated unit tests
    }
    settings = Settings(**valid_data)
    assert settings.DATABASE_URL.startswith("postgresql+psycopg://")
    assert settings.JWT_SECRET == "a" * 32
    assert settings.ACCESS_TOKEN_EXPIRE_MINUTES == 15
    assert settings.REFRESH_TOKEN_EXPIRE_DAYS == 30


def test_refuse_start_missing_database_url():
    """Fails fast if DATABASE_URL is missing."""
    with pytest.raises(ValidationError) as exc_info:
        Settings(
            JWT_SECRET="a" * 32,
            CLOUDINARY_CLOUD_NAME="test_cloud",
            CLOUDINARY_API_KEY="123456789",
            CLOUDINARY_API_SECRET="secret_key_abc",
            _env_file=None
        )
    assert "DATABASE_URL" in str(exc_info.value)


def test_refuse_start_missing_jwt_secret():
    """Fails fast if JWT_SECRET is missing."""
    with pytest.raises(ValidationError) as exc_info:
        Settings(
            DATABASE_URL="postgresql+psycopg://user:pass@localhost:5432/db",
            CLOUDINARY_CLOUD_NAME="test_cloud",
            CLOUDINARY_API_KEY="123456789",
            CLOUDINARY_API_SECRET="secret_key_abc",
            _env_file=None
        )
    assert "JWT_SECRET" in str(exc_info.value)


def test_refuse_start_short_jwt_secret():
    """Fails fast if JWT_SECRET has fewer than 32 characters."""
    with pytest.raises(ValidationError) as exc_info:
        Settings(
            DATABASE_URL="postgresql+psycopg://user:pass@localhost:5432/db",
            JWT_SECRET="too_short_secret",
            CLOUDINARY_CLOUD_NAME="test_cloud",
            CLOUDINARY_API_KEY="123456789",
            CLOUDINARY_API_SECRET="secret_key_abc",
            _env_file=None
        )
    assert "JWT_SECRET" in str(exc_info.value)


def test_refuse_start_missing_cloudinary_credentials():
    """Fails fast if any Cloudinary credential is missing."""
    with pytest.raises(ValidationError) as exc_info:
        Settings(
            DATABASE_URL="postgresql+psycopg://user:pass@localhost:5432/db",
            JWT_SECRET="a" * 32,
            CLOUDINARY_API_KEY="123456789",
            CLOUDINARY_API_SECRET="secret_key_abc",
            _env_file=None
        )
    assert "CLOUDINARY_CLOUD_NAME" in str(exc_info.value)


def test_refuse_start_invalid_database_url_protocol():
    """Fails fast if database URL does not use postgresql protocol."""
    with pytest.raises(ValidationError) as exc_info:
        Settings(
            DATABASE_URL="mysql://user:pass@localhost:3306/db",
            JWT_SECRET="a" * 32,
            CLOUDINARY_CLOUD_NAME="test_cloud",
            CLOUDINARY_API_KEY="123456789",
            CLOUDINARY_API_SECRET="secret_key_abc",
            _env_file=None
        )
    assert "DATABASE_URL" in str(exc_info.value)
