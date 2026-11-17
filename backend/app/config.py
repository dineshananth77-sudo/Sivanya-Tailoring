from functools import lru_cache
from pathlib import Path
from typing import List, Union
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    # Core Application Settings
    PROJECT_NAME: str = Field(default="Stitch & Style API")
    ENVIRONMENT: str = Field(default="development")
    DEBUG: bool = Field(default=False)
    API_V1_STR: str = Field(default="/api/v1")
    HOST: str = Field(default="127.0.0.1")
    PORT: int = Field(default=8000)

    # Database Configuration (Fail-fast: must not be empty)
    DATABASE_URL: str = Field(..., description="PostgreSQL Connection string with psycopg3 driver")

    # Security & JWT (Fail-fast: secret required with min 32 chars)
    JWT_SECRET: str = Field(..., min_length=32, description="Cryptographic secret key for JWT signing")
    JWT_ALGORITHM: str = Field(default="HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=15, gt=0)
    REFRESH_TOKEN_EXPIRE_DAYS: int = Field(default=30, gt=0)

    # CORS Configuration
    CORS_ORIGINS: Union[str, List[str]] = Field(default=["*"])

    # Cloudinary Credentials (Fail-fast: required for image upload/management)
    CLOUDINARY_CLOUD_NAME: str = Field(..., min_length=1, description="Cloudinary cloud name")
    CLOUDINARY_API_KEY: str = Field(..., min_length=1, description="Cloudinary API key")
    CLOUDINARY_API_SECRET: str = Field(..., min_length=1, description="Cloudinary API secret")

    @field_validator("DATABASE_URL")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("DATABASE_URL must not be empty.")
        if not (v.startswith("postgresql://") or v.startswith("postgresql+psycopg://")):
            raise ValueError(
                "DATABASE_URL must start with 'postgresql://' or 'postgresql+psycopg://'"
            )
        # Normalize to psycopg 3 driver dialect
        if v.startswith("postgresql://"):
            v = "postgresql+psycopg://" + v[len("postgresql://"):]
        return v

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",") if origin.strip()]
        return v

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT.lower() == "production"

    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )


@lru_cache()
def get_settings() -> Settings:
    """Returns cached application settings instance or raises ValidationError if misconfigured."""
    return Settings()
