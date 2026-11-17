import time
import uuid
import pytest
from app.database import get_db_context
from app.models.user import User, UserRole
from app.models.token import RefreshToken
from app.repositories.user_repo import UserRepository
from app.security.jwt import create_access_token
from app.security.password import hash_password
from app.security.rate_limiter import limiter


@pytest.fixture(autouse=True)
def reset_rate_limits():
    """Resets in-memory rate limiter between tests."""
    limiter._records.clear()


def test_registration_creates_customer(client):
    """Test that registration creates a customer and returns valid tokens."""
    email = f"cust_{uuid.uuid4().hex[:8]}@example.com"
    payload = {
        "email": email,
        "password": "Password123!Secure",
        "full_name": "Test Customer",
        "phone": "+919876543210"
    }

    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()

    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == email
    assert data["user"]["role"] == "customer"
    assert data["user"]["is_active"] is True


def test_registration_rejects_role_injection(client):
    """Test that attempting to pass role='admin' during registration is rejected with 422."""
    payload = {
        "email": f"hacker_{uuid.uuid4().hex[:8]}@example.com",
        "password": "Password123!Secure",
        "full_name": "Privilege Escalation Attempt",
        "role": "admin"  # Injected field
    }

    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 422
    data = response.json()
    assert data["error"]["code"] == "VALIDATION_ERROR"


def test_password_is_stored_as_argon2id_hash(client):
    """Test that customer password is stored as an Argon2id hash in PostgreSQL."""
    email = f"hashcheck_{uuid.uuid4().hex[:8]}@example.com"
    payload = {
        "email": email,
        "password": "SecretPassword2026!",
        "full_name": "Hash Checker"
    }

    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201

    with get_db_context() as db:
        user = UserRepository.get_by_email(db, email)
        assert user is not None
        assert user.password_hash.startswith("$argon2id$")
        assert "SecretPassword2026!" not in user.password_hash


def test_registration_duplicate_email(client):
    """Test that duplicate email registration returns 409 conflict."""
    email = f"dup_{uuid.uuid4().hex[:8]}@example.com"
    payload = {
        "email": email,
        "password": "Password123!Secure",
        "full_name": "Duplicate User"
    }

    r1 = client.post("/api/v1/auth/register", json=payload)
    assert r1.status_code == 201

    r2 = client.post("/api/v1/auth/register", json=payload)
    assert r2.status_code == 409
    assert r2.json()["error"]["code"] == "EMAIL_ALREADY_EXISTS"


def test_unified_login_customer(client):
    """Test login for customer returns customer role."""
    email = f"login_cust_{uuid.uuid4().hex[:8]}@example.com"
    client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "CustomerPassword123!",
        "full_name": "Customer Login Test"
    })

    response = client.post("/api/v1/auth/login", json={
        "email": email,
        "password": "CustomerPassword123!"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["user"]["role"] == "customer"
    assert data["access_token"] is not None


def test_unified_login_admin(client):
    """Test login for admin returns admin role."""
    email = f"admin_{uuid.uuid4().hex[:8]}@example.com"
    with get_db_context() as db:
        UserRepository.create_user(
            db=db,
            email=email,
            password_hash=hash_password("AdminPassword123!"),
            full_name="Admin User",
            role=UserRole.ADMIN.value
        )

    response = client.post("/api/v1/auth/login", json={
        "email": email,
        "password": "AdminPassword123!"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["user"]["role"] == "admin"


def test_login_wrong_email_or_password(client):
    """Test that both wrong email and wrong password return identical generic error message."""
    r1 = client.post("/api/v1/auth/login", json={
        "email": "non_existent_user@example.com",
        "password": "SomePassword123!"
    })
    assert r1.status_code == 401
    assert r1.json()["error"]["message"] == "Invalid email or password."

    email = f"existing_{uuid.uuid4().hex[:8]}@example.com"
    client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "RightPassword123!",
        "full_name": "Existing"
    })

    r2 = client.post("/api/v1/auth/login", json={
        "email": email,
        "password": "WrongPassword123!"
    })
    assert r2.status_code == 401
    assert r2.json()["error"]["message"] == "Invalid email or password."


def test_login_inactive_user_blocked(client):
    """Test that deactivated users cannot log in."""
    email = f"inactive_{uuid.uuid4().hex[:8]}@example.com"
    with get_db_context() as db:
        UserRepository.create_user(
            db=db,
            email=email,
            password_hash=hash_password("Password123!"),
            full_name="Inactive User",
            is_active=False
        )

    response = client.post("/api/v1/auth/login", json={
        "email": email,
        "password": "Password123!"
    })
    assert response.status_code == 403
    assert response.json()["error"]["code"] == "ACCOUNT_INACTIVE"


def test_customer_blocked_from_admin_route(client):
    """Test that customer tokens receive 403 Forbidden on admin routes."""
    email = f"cust_block_{uuid.uuid4().hex[:8]}@example.com"
    reg = client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "Password123!",
        "full_name": "Blocked Customer"
    })
    customer_token = reg.json()["access_token"]

    response = client.get(
        "/api/v1/admin/ping",
        headers={"Authorization": f"Bearer {customer_token}"}
    )
    assert response.status_code == 403
    assert response.json()["error"]["code"] == "FORBIDDEN_ADMIN_ONLY"


def test_admin_allowed_on_admin_route(client):
    """Test that admin tokens receive 200 on admin routes."""
    email = f"admin_allow_{uuid.uuid4().hex[:8]}@example.com"
    with get_db_context() as db:
        user = UserRepository.create_user(
            db=db,
            email=email,
            password_hash=hash_password("AdminPass123!"),
            full_name="Allowed Admin",
            role=UserRole.ADMIN.value
        )
        token = create_access_token(user.id, user.role)

    response = client.get(
        "/api/v1/admin/ping",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert response.json()["message"] == "Admin authorization verified."


def test_tampered_token_rejected(client):
    """Test that tampered tokens fail signature validation."""
    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.tampered"}
    )
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "INVALID_TOKEN"


def test_refresh_token_rotation_and_reuse_detection(client):
    """
    Test refresh token rotation:
    1. Initial refresh yields new tokens and revokes old.
    2. Attempting to replay the old revoked token triggers reuse detection.
    """
    email = f"reuse_{uuid.uuid4().hex[:8]}@example.com"
    reg = client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "Password123!",
        "full_name": "Reuse Test"
    })
    initial_refresh = reg.json()["refresh_token"]

    # 1. First legitimate rotation
    r1 = client.post("/api/v1/auth/refresh", json={"refresh_token": initial_refresh})
    assert r1.status_code == 200
    data1 = r1.json()
    new_refresh = data1["refresh_token"]
    assert new_refresh != initial_refresh

    # 2. Replay attack: Attacker tries to use the old initial_refresh token!
    r2 = client.post("/api/v1/auth/refresh", json={"refresh_token": initial_refresh})
    assert r2.status_code == 401
    assert r2.json()["error"]["code"] == "TOKEN_REUSE_DETECTED"

    # 3. Because reuse was detected, the whole family was revoked, so new_refresh also fails!
    r3 = client.post("/api/v1/auth/refresh", json={"refresh_token": new_refresh})
    assert r3.status_code == 401


def test_logout_revokes_token(client):
    """Test that logging out revokes the refresh token."""
    email = f"logout_{uuid.uuid4().hex[:8]}@example.com"
    reg = client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "Password123!",
        "full_name": "Logout Test"
    })
    refresh_token = reg.json()["refresh_token"]

    logout_resp = client.post("/api/v1/auth/logout", json={"refresh_token": refresh_token})
    assert logout_resp.status_code == 200

    # Refreshing with the revoked token must now fail
    ref_resp = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert ref_resp.status_code == 401


def test_change_password(client):
    """Test user changing password, old password invalidated, new password works."""
    email = f"chg_pwd_{uuid.uuid4().hex[:8]}@example.com"
    reg = client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "OldPassword123!",
        "full_name": "Change Password Test"
    })
    access_token = reg.json()["access_token"]

    # Attempt with wrong current password
    bad_resp = client.post(
        "/api/v1/auth/change-password",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"current_password": "WrongPassword!", "new_password": "NewPassword2026!"}
    )
    assert bad_resp.status_code == 400
    assert bad_resp.json()["error"]["code"] == "INVALID_CURRENT_PASSWORD"

    # Successful change
    ok_resp = client.post(
        "/api/v1/auth/change-password",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"current_password": "OldPassword123!", "new_password": "NewPassword2026!"}
    )
    assert ok_resp.status_code == 200

    # Old password fails
    old_login = client.post("/api/v1/auth/login", json={"email": email, "password": "OldPassword123!"})
    assert old_login.status_code == 401

    # New password succeeds
    new_login = client.post("/api/v1/auth/login", json={"email": email, "password": "NewPassword2026!"})
    assert new_login.status_code == 200


def test_rate_limiting(client):
    """Test that exceeding the rate limit triggers HTTP 429."""
    for i in range(10):
        client.post("/api/v1/auth/register", json={
            "email": f"rate_{i}_{uuid.uuid4().hex[:6]}@example.com",
            "password": "Password123!",
            "full_name": "Rate Limit Test"
        })

    # The 11th request exceeds limit of 10 per minute
    exceeded_resp = client.post("/api/v1/auth/register", json={
        "email": f"rate_excess_{uuid.uuid4().hex[:6]}@example.com",
        "password": "Password123!",
        "full_name": "Rate Limit Exceeded"
    })
    assert exceeded_resp.status_code == 429
    assert exceeded_resp.json()["error"]["code"] == "RATE_LIMIT_EXCEEDED"
