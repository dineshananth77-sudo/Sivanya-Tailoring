import uuid
from decimal import Decimal
from unittest.mock import patch
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.main import app
from app.database import get_db, SessionLocal
from app.models.catalog import Category, Product, ProductImage
from app.models.user import User, UserRole
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
    admin = db_session.query(User).filter(User.email == "catalog_admin@stitchstyle.com").first()
    if not admin:
        admin = User(
            email="catalog_admin@stitchstyle.com",
            password_hash=hash_password("AdminSecure2026!"),
            full_name="Catalog Admin",
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
    customer = db_session.query(User).filter(User.email == "catalog_customer@stitchstyle.com").first()
    if not customer:
        customer = User(
            email="catalog_customer@stitchstyle.com",
            password_hash=hash_password("CustomerSecure2026!"),
            full_name="Catalog Customer",
            role=UserRole.CUSTOMER,
            is_active=True,
        )
        db_session.add(customer)
        db_session.commit()
        db_session.refresh(customer)

    role_str = customer.role.value if hasattr(customer.role, "value") else str(customer.role)
    token = create_access_token(user_id=customer.id, role=role_str)
    return {"Authorization": f"Bearer {token}"}


# ---------------- Test Category Operations ----------------

def test_admin_category_crud(client: TestClient, admin_headers: dict):
    # 1. Create Category
    payload = {
        "name": "Silk Sarees Test",
        "description": "Premium handcrafted silk sarees",
        "image_url": "https://example.com/saree.jpg",
        "is_active": True,
        "sort_order": 1,
    }
    res = client.post("/api/v1/admin/categories", json=payload, headers=admin_headers)
    assert res.status_code == 201
    cat_data = res.json()
    cat_id = cat_data["id"]
    assert cat_data["name"] == "Silk Sarees Test"
    assert cat_data["slug"] == "silk-sarees-test"

    # 2. Update Category
    update_payload = {"name": "Pure Silk Sarees", "sort_order": 5}
    res = client.put(f"/api/v1/admin/categories/{cat_id}", json=update_payload, headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["name"] == "Pure Silk Sarees"
    assert res.json()["sort_order"] == 5

    # 3. List Admin Categories
    res = client.get("/api/v1/admin/categories", headers=admin_headers)
    assert res.status_code == 200
    all_cats = res.json()
    assert any(c["id"] == cat_id for c in all_cats)

    # 4. Delete Category
    res = client.delete(f"/api/v1/admin/categories/{cat_id}", headers=admin_headers)
    assert res.status_code == 204

    # 5. Verify deleted
    res = client.delete(f"/api/v1/admin/categories/{cat_id}", headers=admin_headers)
    assert res.status_code == 404


def test_customer_forbidden_from_admin_categories(client: TestClient, customer_headers: dict):
    res = client.post("/api/v1/admin/categories", json={"name": "Hacked Category"}, headers=customer_headers)
    assert res.status_code == 403
    assert res.json()["error"]["code"] == "FORBIDDEN_ADMIN_ONLY"


def test_public_categories_list(client: TestClient, admin_headers: dict):
    # Create one active and one inactive category
    active_cat = client.post("/api/v1/admin/categories", json={"name": "Active Category", "is_active": True}, headers=admin_headers).json()
    inactive_cat = client.post("/api/v1/admin/categories", json={"name": "Inactive Category", "is_active": False}, headers=admin_headers).json()

    res = client.get("/api/v1/categories")
    assert res.status_code == 200
    names = [c["name"] for c in res.json()]
    assert "Active Category" in names
    assert "Inactive Category" not in names


# ---------------- Test Product Operations ----------------

def test_product_crud_and_validation(client: TestClient, admin_headers: dict):
    # Setup category
    cat_res = client.post("/api/v1/admin/categories", json={"name": f"Lehengas Cat {uuid.uuid4().hex[:4]}"}, headers=admin_headers)
    cat_id = cat_res.json()["id"]

    # 1. Product price must be > 0
    invalid_prod = {
        "name": "Bridal Lehenga",
        "description": "Zari work",
        "price": -10.00,
        "category_id": cat_id,
    }
    res = client.post("/api/v1/admin/products", json=invalid_prod, headers=admin_headers)
    assert res.status_code in (400, 422)

    # 2. Create valid product
    valid_prod = {
        "name": "Bridal Velvet Lehenga",
        "description": "Royal velvet bridal lehenga with intricate zardozi embroidery.",
        "price": 2499.00,
        "category_id": cat_id,
        "is_available": True,
        "stock_quantity": 10,
    }
    res = client.post("/api/v1/admin/products", json=valid_prod, headers=admin_headers)
    assert res.status_code == 201
    prod_data = res.json()
    prod_id = prod_data["id"]
    assert prod_data["name"] == "Bridal Velvet Lehenga"
    assert prod_data["slug"].startswith("bridal-velvet-lehenga")
    assert Decimal(str(prod_data["price"])) == Decimal("2499.00")

    # 3. Update Product
    update_res = client.put(
        f"/api/v1/admin/products/{prod_id}",
        json={"price": 2299.50, "stock_quantity": 5},
        headers=admin_headers,
    )
    assert update_res.status_code == 200
    assert Decimal(str(update_res.json()["price"])) == Decimal("2299.50")
    assert update_res.json()["stock_quantity"] == 5

    # 4. Get by ID and Slug
    res_by_id = client.get(f"/api/v1/products/{prod_id}")
    assert res_by_id.status_code == 200
    assert res_by_id.json()["id"] == prod_id

    res_by_slug = client.get(f"/api/v1/products/{prod_data['slug']}")
    assert res_by_slug.status_code == 200
    assert res_by_slug.json()["id"] == prod_id


def test_product_search_filter_and_sorting(client: TestClient, admin_headers: dict):
    # Create category
    cat_res = client.post("/api/v1/admin/categories", json={"name": f"Kurti Collection {uuid.uuid4().hex[:4]}"}, headers=admin_headers)
    cat_id = cat_res.json()["id"]

    # Create 3 products
    p1 = client.post(
        "/api/v1/admin/products",
        json={"name": "Cotton Casual Kurti", "description": "Comfortable cotton", "price": 499.00, "category_id": cat_id},
        headers=admin_headers,
    ).json()

    p2 = client.post(
        "/api/v1/admin/products",
        json={"name": "Embroidered Party Kurti", "description": "Silk blend party wear", "price": 1299.00, "category_id": cat_id},
        headers=admin_headers,
    ).json()

    p3 = client.post(
        "/api/v1/admin/products",
        json={"name": "Designer Anarkali Kurti", "description": "Floor length", "price": 2999.00, "category_id": cat_id},
        headers=admin_headers,
    ).json()

    # Search filter
    res = client.get(f"/api/v1/products?search=Casual&category_id={cat_id}")
    assert res.status_code == 200
    assert res.json()["total"] == 1
    assert res.json()["items"][0]["name"] == "Cotton Casual Kurti"

    # Price range filter (min 1000, max 2000)
    res = client.get(f"/api/v1/products?category_id={cat_id}&min_price=1000&max_price=2000")
    assert res.status_code == 200
    assert res.json()["total"] == 1
    assert res.json()["items"][0]["id"] == p2["id"]

    # Sorting price_asc
    res = client.get(f"/api/v1/products?category_id={cat_id}&sort_by=price_asc")
    assert res.status_code == 200
    prices = [Decimal(str(item["price"])) for item in res.json()["items"]]
    assert prices == sorted(prices)

    # Sorting price_desc
    res = client.get(f"/api/v1/products?category_id={cat_id}&sort_by=price_desc")
    assert res.status_code == 200
    prices = [Decimal(str(item["price"])) for item in res.json()["items"]]
    assert prices == sorted(prices, reverse=True)


# ---------------- Test Image Upload & Management ----------------

@patch("cloudinary.uploader.upload")
@patch("cloudinary.uploader.destroy")
def test_product_image_upload_and_primary_flag(mock_destroy, mock_upload, client: TestClient, admin_headers: dict):
    # Setup mock upload response
    mock_upload.return_value = {
        "secure_url": "https://res.cloudinary.com/demo/image/upload/sample.jpg",
        "public_id": "stitch_style/products/sample1",
        "asset_id": "asset12345",
        "width": 800,
        "height": 1000,
        "format": "jpg",
        "bytes": 102400,
    }
    mock_destroy.return_value = {"result": "ok"}

    # Create category & product
    cat = client.post("/api/v1/admin/categories", json={"name": f"Image Test Cat {uuid.uuid4().hex[:4]}"}, headers=admin_headers).json()
    prod = client.post("/api/v1/admin/products", json={"name": "Saree Image Test", "price": 999.00, "category_id": cat["id"]}, headers=admin_headers).json()
    prod_id = prod["id"]

    # Upload valid JPEG
    valid_jpeg_bytes = b"\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00" + b"\x00" * 200
    files = {"file": ("saree1.jpg", valid_jpeg_bytes, "image/jpeg")}

    res = client.post(f"/api/v1/admin/products/{prod_id}/images", files=files, headers=admin_headers)
    assert res.status_code == 201
    img1 = res.json()
    assert img1["is_primary"] is True  # First image is auto-primary
    assert img1["cloudinary_url"] == "https://res.cloudinary.com/demo/image/upload/sample.jpg"

    # Upload second image
    mock_upload.return_value["public_id"] = "stitch_style/products/sample2"
    mock_upload.return_value["secure_url"] = "https://res.cloudinary.com/demo/image/upload/sample2.jpg"
    files2 = {"file": ("saree2.jpg", valid_jpeg_bytes, "image/jpeg")}
    res2 = client.post(f"/api/v1/admin/products/{prod_id}/images", files=files2, headers=admin_headers)
    assert res2.status_code == 201
    img2 = res2.json()
    assert img2["is_primary"] is False

    # Set img2 as primary
    res_patch = client.patch(f"/api/v1/admin/products/{prod_id}/images/{img2['id']}/primary", headers=admin_headers)
    assert res_patch.status_code == 200
    assert res_patch.json()["is_primary"] is True

    # Product detail should now show img2 as primary
    prod_detail = client.get(f"/api/v1/products/{prod_id}").json()
    for img in prod_detail["images"]:
        if img["id"] == img2["id"]:
            assert img["is_primary"] is True
        elif img["id"] == img1["id"]:
            assert img["is_primary"] is False

    # Delete img2
    res_del = client.delete(f"/api/v1/admin/products/{prod_id}/images/{img2['id']}", headers=admin_headers)
    assert res_del.status_code == 204
    mock_destroy.assert_called()


def test_image_upload_magic_bytes_rejection(client: TestClient, admin_headers: dict):
    cat = client.post("/api/v1/admin/categories", json={"name": f"Rejection Test Cat {uuid.uuid4().hex[:4]}"}, headers=admin_headers).json()
    prod = client.post("/api/v1/admin/products", json={"name": "Rejection Prod", "price": 999.00, "category_id": cat["id"]}, headers=admin_headers).json()

    # Send executable / text file pretending to be image
    fake_image_bytes = b"This is not a real image header at all."
    files = {"file": ("malicious.jpg", fake_image_bytes, "image/jpeg")}

    res = client.post(f"/api/v1/admin/products/{prod['id']}/images", files=files, headers=admin_headers)
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "INVALID_IMAGE_FORMAT"


@patch("cloudinary.uploader.upload")
@patch("cloudinary.uploader.destroy")
def test_max_8_images_per_product_limit(mock_destroy, mock_upload, client: TestClient, admin_headers: dict):
    mock_upload.return_value = {
        "secure_url": "https://res.cloudinary.com/demo/image/upload/sample.jpg",
        "public_id": "stitch_style/products/sample_limit",
        "asset_id": "asset12345",
        "width": 800,
        "height": 1000,
        "format": "jpg",
        "bytes": 50000,
    }
    mock_destroy.return_value = {"result": "ok"}

    cat = client.post("/api/v1/admin/categories", json={"name": f"Limit Cat {uuid.uuid4().hex[:4]}"}, headers=admin_headers).json()
    prod = client.post("/api/v1/admin/products", json={"name": "Limit Prod", "price": 499.00, "category_id": cat["id"]}, headers=admin_headers).json()
    prod_id = prod["id"]

    valid_jpeg = b"\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00" + b"\x00" * 100

    # Upload 8 images
    for i in range(8):
        files = {"file": (f"img_{i}.jpg", valid_jpeg, "image/jpeg")}
        res = client.post(f"/api/v1/admin/products/{prod_id}/images", files=files, headers=admin_headers)
        assert res.status_code == 201

    # 9th upload should fail with 400 MAX_IMAGES_EXCEEDED
    files = {"file": ("img_9.jpg", valid_jpeg, "image/jpeg")}
    res = client.post(f"/api/v1/admin/products/{prod_id}/images", files=files, headers=admin_headers)
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "MAX_IMAGES_EXCEEDED"
