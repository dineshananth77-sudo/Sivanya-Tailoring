import uuid
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.main import app
from app.database import get_db, SessionLocal
from app.models.catalog import Category, Product
from app.models.user import User, UserRole
from app.models.order import OrderStatus
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
    admin = db_session.query(User).filter(User.email == "orders_admin@stitchstyle.com").first()
    if not admin:
        admin = User(
            email="orders_admin@stitchstyle.com",
            password_hash=hash_password("AdminSecure2026!"),
            full_name="Orders Admin",
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
    customer = db_session.query(User).filter(User.email == "orders_customer@stitchstyle.com").first()
    if not customer:
        customer = User(
            email="orders_customer@stitchstyle.com",
            password_hash=hash_password("CustomerSecure2026!"),
            full_name="Orders Customer",
            role=UserRole.CUSTOMER,
            is_active=True,
        )
        db_session.add(customer)
        db_session.commit()
        db_session.refresh(customer)

    # Clean up any existing addresses to guarantee clean isolation across test runs
    db_session.query(Address).filter(Address.customer_id == customer.id).delete()
    db_session.commit()

    role_str = customer.role.value if hasattr(customer.role, "value") else str(customer.role)
    token = create_access_token(user_id=customer.id, role=role_str)
    return {"Authorization": f"Bearer {token}"}


# ---------------- Test Address Management ----------------

def test_customer_address_lifecycle(client: TestClient, customer_headers: dict):
    # 1. Create first address (should auto-become default)
    addr1_payload = {
        "recipient_name": "Priya Sharma",
        "phone": "+91 9876543210",
        "street": "123 MG Road, Flat 4B",
        "city": "Bengaluru",
        "state": "Karnataka",
        "postal_code": "560001",
        "is_default": False,
    }
    res = client.post("/api/v1/addresses", json=addr1_payload, headers=customer_headers)
    assert res.status_code == 201
    addr1 = res.json()
    assert addr1["is_default"] is True  # Auto default on first address

    # 2. Create second address with is_default=True
    addr2_payload = {
        "recipient_name": "Priya Office",
        "phone": "+91 9876543211",
        "street": "Tech Park Block C",
        "city": "Bengaluru",
        "state": "Karnataka",
        "postal_code": "560100",
        "is_default": True,
    }
    res2 = client.post("/api/v1/addresses", json=addr2_payload, headers=customer_headers)
    assert res2.status_code == 201
    addr2 = res2.json()
    assert addr2["is_default"] is True

    # Check addr1 is no longer default
    res_get1 = client.get(f"/api/v1/addresses/{addr1['id']}", headers=customer_headers)
    assert res_get1.json()["is_default"] is False

    # 3. Update Address
    res_up = client.put(
        f"/api/v1/addresses/{addr1['id']}",
        json={"street": "Updated MG Road 123"},
        headers=customer_headers,
    )
    assert res_up.status_code == 200
    assert res_up.json()["street"] == "Updated MG Road 123"

    # 4. Set addr1 back to default
    res_def = client.patch(f"/api/v1/addresses/{addr1['id']}/default", headers=customer_headers)
    assert res_def.status_code == 200
    assert res_def.json()["is_default"] is True

    # 5. Delete addr2
    res_del = client.delete(f"/api/v1/addresses/{addr2['id']}", headers=customer_headers)
    assert res_del.status_code == 204


# ---------------- Test Delivery Quotes & Rules ----------------

def test_delivery_quote_and_admin_rules(client: TestClient, admin_headers: dict):
    # Configure delivery settings: default charge 50.00, free delivery over 1500
    settings_payload = {
        "is_free_delivery_active": True,
        "free_delivery_threshold": 1500.00,
        "default_delivery_charge": 50.00,
    }
    res = client.put("/api/v1/admin/delivery/settings", json=settings_payload, headers=admin_headers)
    assert res.status_code == 200

    # Subtotal 500 -> gets default charge 50.00
    quote1 = client.post("/api/v1/delivery/quote", json={"subtotal": 500.00}).json()
    assert Decimal(str(quote1["delivery_charge"])) == Decimal("50.00")
    assert quote1["is_free_delivery"] is False

    # Subtotal 1600 -> qualifies for free delivery
    quote2 = client.post("/api/v1/delivery/quote", json={"subtotal": 1600.00}).json()
    assert Decimal(str(quote2["delivery_charge"])) == Decimal("0.00")
    assert quote2["is_free_delivery"] is True


# ---------------- Test Order Placement & Snapshots ----------------

def test_order_creation_and_snapshots(client: TestClient, admin_headers: dict, customer_headers: dict):
    # Setup Category and Product
    cat = client.post("/api/v1/admin/categories", json={"name": f"Orders Cat {uuid.uuid4().hex[:4]}"}, headers=admin_headers).json()
    prod = client.post(
        "/api/v1/admin/products",
        json={"name": "Kanjeevaram Saree", "price": 2500.00, "category_id": cat["id"], "stock_quantity": 10},
        headers=admin_headers,
    ).json()

    # Create Address
    addr = client.post(
        "/api/v1/addresses",
        json={
            "recipient_name": "Ananya Roy",
            "phone": "+91 9888877777",
            "street": "77 Park Street",
            "city": "Kolkata",
            "state": "West Bengal",
            "postal_code": "700016",
        },
        headers=customer_headers,
    ).json()

    # Place Order for 2 sarees
    order_payload = {
        "address_id": addr["id"],
        "items": [{"product_id": prod["id"], "quantity": 2}],
        "note": "Please gift wrap with golden ribbon.",
    }
    res = client.post("/api/v1/orders", json=order_payload, headers=customer_headers)
    assert res.status_code == 201
    order = res.json()

    assert order["order_number"].startswith("ORD-")
    assert order["status"] == "pending"
    assert Decimal(str(order["subtotal"])) == Decimal("5000.00")
    assert Decimal(str(order["total"])) >= Decimal("5000.00")

    # Verify frozen address snapshot
    assert order["delivery_address_snapshot"]["recipient_name"] == "Ananya Roy"
    assert order["delivery_address_snapshot"]["city"] == "Kolkata"

    # Verify frozen item snapshot
    assert len(order["items"]) == 1
    item = order["items"][0]
    assert item["product_name_snapshot"] == "Kanjeevaram Saree"
    assert Decimal(str(item["unit_price_snapshot"])) == Decimal("2500.00")
    assert Decimal(str(item["line_total"])) == Decimal("5000.00")

    # Verify initial status history
    assert len(order["status_history"]) >= 1
    assert order["status_history"][0]["new_status"] == "pending"


# ---------------- Test Cancellation Rules & Fulfillment State Machine ----------------

def test_order_cancellation_and_state_machine(client: TestClient, admin_headers: dict, customer_headers: dict):
    # Setup product with 5 stock
    cat = client.post("/api/v1/admin/categories", json={"name": f"Stock Cat {uuid.uuid4().hex[:4]}"}, headers=admin_headers).json()
    prod = client.post(
        "/api/v1/admin/products",
        json={"name": "Designer Anarkali", "price": 1200.00, "category_id": cat["id"], "stock_quantity": 5},
        headers=admin_headers,
    ).json()

    addr = client.post(
        "/api/v1/addresses",
        json={
            "recipient_name": "Meera Patel",
            "phone": "+91 9777766666",
            "street": "10 Palace Road",
            "city": "Ahmedabad",
            "state": "Gujarat",
            "postal_code": "380001",
        },
        headers=customer_headers,
    ).json()

    # 1. Place order for 2 items -> stock decreases to 3
    order1 = client.post(
        "/api/v1/orders",
        json={"address_id": addr["id"], "items": [{"product_id": prod["id"], "quantity": 2}]},
        headers=customer_headers,
    ).json()

    prod_after = client.get(f"/api/v1/products/{prod['id']}").json()
    assert prod_after["stock_quantity"] == 3

    # 2. Customer cancels order while pending -> allowed, stock restored to 5
    res_cancel = client.post(f"/api/v1/orders/{order1['id']}/cancel", headers=customer_headers)
    assert res_cancel.status_code == 200
    assert res_cancel.json()["status"] == "cancelled"

    prod_restored = client.get(f"/api/v1/products/{prod['id']}").json()
    assert prod_restored["stock_quantity"] == 5

    # 3. Place new order
    order2 = client.post(
        "/api/v1/orders",
        json={"address_id": addr["id"], "items": [{"product_id": prod["id"], "quantity": 1}]},
        headers=customer_headers,
    ).json()
    order2_id = order2["id"]

    # 4. Admin moves to CONFIRMED
    res_conf = client.patch(
        f"/api/v1/admin/orders/{order2_id}/status",
        json={"status": "confirmed", "comment": "Order verified with customer."},
        headers=admin_headers,
    )
    assert res_conf.status_code == 200
    assert res_conf.json()["status"] == "confirmed"

    # Customer attempts to cancel confirmed order -> REJECTED (400)
    res_bad_cancel = client.post(f"/api/v1/orders/{order2_id}/cancel", headers=customer_headers)
    assert res_bad_cancel.status_code == 400
    assert res_bad_cancel.json()["error"]["code"] == "CANNOT_CANCEL_ORDER"

    # 5. Admin advances through fulfillment state machine:
    # confirmed -> preparing
    res_prep = client.patch(f"/api/v1/admin/orders/{order2_id}/status", json={"status": "preparing"}, headers=admin_headers)
    assert res_prep.status_code == 200

    # preparing -> out_for_delivery
    res_out = client.patch(f"/api/v1/admin/orders/{order2_id}/status", json={"status": "out_for_delivery"}, headers=admin_headers)
    assert res_out.status_code == 200

    # out_for_delivery -> delivered
    res_del = client.patch(f"/api/v1/admin/orders/{order2_id}/status", json={"status": "delivered"}, headers=admin_headers)
    assert res_del.status_code == 200
    assert res_del.json()["status"] == "delivered"

    # 6. Invalid transition: cannot transition delivered order
    res_invalid = client.patch(f"/api/v1/admin/orders/{order2_id}/status", json={"status": "pending"}, headers=admin_headers)
    assert res_invalid.status_code == 400
    assert res_invalid.json()["error"]["code"] == "INVALID_STATUS_TRANSITION"
