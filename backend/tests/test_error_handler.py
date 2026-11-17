def test_uniform_404_error_format(client):
    """Verifies that non-existent routes return the uniform error schema."""
    response = client.get("/api/v1/non_existent_route_abc123")
    assert response.status_code == 404
    data = response.json()
    assert "error" in data
    assert "code" in data["error"]
    assert "message" in data["error"]
    assert data["error"]["code"] == "NOT_FOUND"


def test_uniform_405_error_format(client):
    """Verifies that invalid HTTP methods return the uniform error schema."""
    response = client.post("/api/v1/health")
    assert response.status_code == 405
    data = response.json()
    assert "error" in data
    assert "code" in data["error"]
    assert "message" in data["error"]
    assert data["error"]["code"] == "METHOD_NOT_ALLOWED"
