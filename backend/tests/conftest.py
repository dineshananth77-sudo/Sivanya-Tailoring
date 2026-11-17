import os
import sys
import pytest
from fastapi.testclient import TestClient

# Ensure backend root is on Python search path
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from app.main import app
from app.config import get_settings


@pytest.fixture(scope="session")
def client():
    """Provides a FastAPI test client instance for HTTP tests."""
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(scope="session")
def settings():
    return get_settings()
