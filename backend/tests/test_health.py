def test_root_endpoint(client):
    """Verifies that the root endpoint responds with basic service info."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "name" in data
    assert "version" in data
    assert data["version"] == "1.0.0"


def test_health_liveness(client):
    """Verifies that /api/v1/health responds with healthy status."""
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["version"] == "1.0.0"


def test_database_health_readiness(client):
    """Verifies that /api/v1/health/db successfully queries PostgreSQL."""
    response = client.get("/api/v1/health/db")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["database"] == "connected"
