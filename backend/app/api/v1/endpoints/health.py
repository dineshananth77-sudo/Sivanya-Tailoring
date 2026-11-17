from fastapi import APIRouter, status
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.database import check_database_connection
from app.exceptions import AppException

router = APIRouter(prefix="/health", tags=["Health"])
settings = get_settings()


@router.get("", status_code=status.HTTP_200_OK)
def health_check():
    """Liveness probe confirming the API server is responsive."""
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "environment": settings.ENVIRONMENT,
        "version": "1.0.0"
    }


@router.get("/db", status_code=status.HTTP_200_OK)
def database_health_check():
    """Readiness probe checking live PostgreSQL database connectivity."""
    is_connected = check_database_connection()
    if not is_connected:
        raise AppException(
            code="DATABASE_UNAVAILABLE",
            message="Database connection could not be established.",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE
        )
    return {
        "status": "healthy",
        "database": "connected"
    }
