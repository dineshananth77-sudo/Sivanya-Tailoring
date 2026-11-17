from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.api.v1.api import api_router
from app.middleware.error_handler import register_error_handlers
from app.middleware.logging import RequestLoggingMiddleware, setup_logging


def create_app() -> FastAPI:
    settings = get_settings()
    setup_logging(debug=settings.DEBUG)

    # In production, disable public API interactive documentation
    docs_url = None if settings.is_production else "/docs"
    redoc_url = None if settings.is_production else "/redoc"
    openapi_url = None if settings.is_production else "/openapi.json"

    app = FastAPI(
        title=settings.PROJECT_NAME,
        version="1.0.0",
        docs_url=docs_url,
        redoc_url=redoc_url,
        openapi_url=openapi_url,
    )

    # 1. Register uniform error response handlers
    register_error_handlers(app)

    # 2. Register request audit logger
    app.add_middleware(RequestLoggingMiddleware)

    # 3. Configure CORS (supports dynamic localhost/127.0.0.1 ports with credentials for Flutter Web)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS if isinstance(settings.CORS_ORIGINS, list) else [settings.CORS_ORIGINS],
        allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )

    # 4. Mount API v1 router
    app.include_router(api_router, prefix=settings.API_V1_STR)

    @app.get("/", tags=["Root"])
    def root():
        return {
            "name": settings.PROJECT_NAME,
            "version": "1.0.0",
            "environment": settings.ENVIRONMENT,
            "docs": docs_url or "disabled in production"
        }

    return app


app = create_app()
