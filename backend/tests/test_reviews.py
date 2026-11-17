import uuid
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.main import app
from app.database import get_db, SessionLocal
from app.models.catalog import Category, Product
from app.models.user import User, UserRole
from app.models.order import Order, OrderItem, OrderStatus
from app.models.address import Address
from app.security.password import hash_password
from app.security.jwt import create_access_token


@pytest.fixture
def db_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def client(db_session: Session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def admin_headers(db_session: Session):
    admin = db_session.query(User).filter(User.email == "reviews_admin@stitchstyle.com").first()
    if not admin:
        admin = User(
            email="reviews_admin@stitchstyle.com",
            password_hash=hash_password("AdminSecure2026!"),
            full_name="Reviews Admin",
            role=UserRole.ADMIN,
            is_active=True,
        )
        db_session.add(admin)
        db_session.commit()
        db_session.refresh(admin)

    role_str = admin.role.value if hasattr(admin.role, "value") else str(admin.role)
    token = create_access_token(user_id=admin.id, role=role_str)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def customer_headers(db_session: Session):
    customer = db_session.query(User).filter(User.email == "reviews_customer@stitchstyle.com").first()
    if not customer:
        customer = User(
            email="reviews_customer@stitchstyle.com",
            password_hash=hash_password("CustomerSecure2026!"),
            full_name="Reviews Customer",
            role=UserRole.CUSTOMER,
            is_active=True,
        )
        db_session.add(customer)
        db_session.commit()
        db_session.refresh(customer)

    role_str = customer.role.value if hasattr(customer.role, "value") else str(customer.role)
    token = create_access_token(user_id=customer.id, role=role_str)
    return {"Authorization": f"Bearer {token}", "user_id": str(customer.id)}


def _setup_delivered_product(client: TestClient, admin_headers: dict, customer_headers: dict) -> str:
    """Helper to create a product and a completed delivered order for the customer."""
    # 1. Create category & product
    cat = client.post("/api/v1/admin/categories", json={"name": f"Rev Cat {uuid.uuid4().hex[:4]}"}, headers=admin_headers).json()
    prod = client.post(
        "/api/v1/admin/products",
        json={"name": "Handloom Chanderi Saree", "price": 1800.00, "category_id": cat["id"]},
        headers=admin_headers,
    ).json()

    # 2. Create customer address
    addr = client.post(
        "/api/v1/addresses",
        json={
            "recipient_name": "Kavita Sen",
            "phone": "+91 9123456789",
            "street": "12 Lake View Road",
            "city": "Jaipur",
            "state": "Rajasthan",
            "postal_code": "302001",
        },
        headers=customer_headers,
    ).json()

    # 3. Place order
    order = client.post(
        "/api/v1/orders",
        json={"address_id": addr["id"], "items": [{"product_id": prod["id"], "quantity": 1}]},
        headers=customer_headers,
    ).json()

    # 4. Advance through fulfillment to delivered
    client.patch(f"/api/v1/admin/orders/{order['id']}/status", json={"status": "confirmed"}, headers=admin_headers)
    client.patch(f"/api/v1/admin/orders/{order['id']}/status", json={"status": "preparing"}, headers=admin_headers)
    client.patch(f"/api/v1/admin/orders/{order['id']}/status", json={"status": "out_for_delivery"}, headers=admin_headers)
    client.patch(f"/api/v1/admin/orders/{order['id']}/status", json={"status": "delivered"}, headers=admin_headers)

    return prod["id"]


# ---------------- Test Reviews ----------------

def test_rating_bounds_validation(client: TestClient, customer_headers: dict):
    dummy_product_id = str(uuid.uuid4())
    # Rating 0 should fail
    res0 = client.post(
        f"/api/v1/products/{dummy_product_id}/reviews",
        json={"rating": 0, "comment": "Horrible"},
        headers=customer_headers,
    )
    assert res0.status_code in (400, 422)

    # Rating 6 should fail
    res6 = client.post(
        f"/api/v1/products/{dummy_product_id}/reviews",
        json={"rating": 6, "comment": "Too good"},
        headers=customer_headers,
    )
    assert res6.status_code in (400, 422)


def test_review_rejected_without_delivered_order(client: TestClient, admin_headers: dict, customer_headers: dict):
    # Create product without placing any order
    cat = client.post("/api/v1/admin/categories", json={"name": f"Rev Test Cat {uuid.uuid4().hex[:4]}"}, headers=admin_headers).json()
    prod = client.post(
        "/api/v1/admin/products",
        json={"name": "Unpurchased Kurti", "price": 899.00, "category_id": cat["id"]},
        headers=admin_headers,
    ).json()

    res = client.post(
        f"/api/v1/products/{prod['id']}/reviews",
        json={"rating": 5, "comment": "Looks nice in photo"},
        headers=customer_headers,
    )
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "PURCHASE_VERIFICATION_REQUIRED"


def test_review_lifecycle_and_rating_stats(client: TestClient, admin_headers: dict, customer_headers: dict):
    # 1. Setup delivered product
    prod_id = _setup_delivered_product(client, admin_headers, customer_headers)

    # 2. Customer posts a 5-star review
    review_res = client.post(
        f"/api/v1/products/{prod_id}/reviews",
        json={"rating": 5, "comment": "Stunning quality fabric and perfect stitching!"},
        headers=customer_headers,
    )
    assert review_res.status_code == 201
    rev_data = review_res.json()
    rev_id = rev_data["id"]
    assert rev_data["rating"] == 5
    assert rev_data["comment"] == "Stunning quality fabric and perfect stitching!"
    assert rev_data["is_visible"] is True

    # 3. Duplicate review attempt should fail (409 Conflict)
    dup_res = client.post(
        f"/api/v1/products/{prod_id}/reviews",
        json={"rating": 4, "comment": "Another review attempt"},
        headers=customer_headers,
    )
    assert dup_res.status_code == 409
    assert dup_res.json()["error"]["code"] == "REVIEW_ALREADY_EXISTS"

    # 4. Check public stats summary
    stats_res = client.get(f"/api/v1/products/{prod_id}/reviews")
    assert stats_res.status_code == 200
    stats = stats_res.json()
    assert stats["average_rating"] == 5.0
    assert stats["total_reviews"] == 1
    assert stats["rating_distribution"]["5"] == 1

    # 5. Customer updates review to 4-star
    update_res = client.put(
        f"/api/v1/reviews/{rev_id}",
        json={"rating": 4, "comment": "Good quality, delivery took 3 days."},
        headers=customer_headers,
    )
    assert update_res.status_code == 200
    assert update_res.json()["rating"] == 4

    # 6. Admin moderates visibility
    hide_res = client.patch(
        f"/api/v1/admin/reviews/{rev_id}/visibility",
        json={"is_visible": False},
        headers=admin_headers,
    )
    assert hide_res.status_code == 200
    assert hide_res.json()["is_visible"] is False

    # Stats now reflect 0 visible reviews
    stats_after_hide = client.get(f"/api/v1/products/{prod_id}/reviews").json()
    assert stats_after_hide["total_reviews"] == 0

    # 7. Customer deletes their review
    del_res = client.delete(f"/api/v1/reviews/{rev_id}", headers=customer_headers)
    assert del_res.status_code == 204
