# Stitch & Style — Production Deployment & Operations Runbook

## 1. Architecture Overview
Stitch & Style runs on a self-managed backend stack built with:
- **Framework:** Python 3.12 + FastAPI + Uvicorn
- **Database:** PostgreSQL with SQLAlchemy 2.0 (typed declarative mapping) and Psycopg 3 driver
- **Migrations:** Alembic for all schema versioning
- **Authentication:** Dual-token JWT (15-minute access tokens) + cryptographically random Argon2id refresh tokens with SHA-256 hash storage, token rotation, and replay detection
- **Image Storage:** Cloudinary Python SDK with binary magic-byte validation (JPEG, PNG, WebP; 5MB limit) and orphan asset cleanup
- **Frontend Integration:** Flutter with persistent secure storage, automatic token refresh on `401 Unauthorized`, and a unified login screen routing customers to the consumer app and administrators to the integrated Flutter Admin Panel.

---

## 2. Environment Variables & Security Configuration
Create a `.env` file in the `backend/` directory based on `.env.example`:

| Variable | Description | Required | Example |
| :--- | :--- | :---: | :--- |
| `ENVIRONMENT` | Environment name | Yes | `production` / `development` |
| `DEBUG` | Enable debug mode | Yes | `false` |
| `HOST` | Server host | Yes | `0.0.0.0` |
| `PORT` | Server listening port | Yes | `8000` |
| `DATABASE_URL` | PostgreSQL connection string with `psycopg3` driver | Yes | `postgresql+psycopg://stitch_admin:<password>@127.0.0.1:5433/stitch_style_db` |
| `JWT_SECRET` | Cryptographic HMAC-SHA256 secret key (minimum 32 characters) | Yes | 64-character random hex string |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud identifier | Yes | `stitchstyle-cloud` |
| `CLOUDINARY_API_KEY` | Cloudinary API Key | Yes | `987654321098765` |
| `CLOUDINARY_API_SECRET` | Cloudinary API Secret | Yes | `aBcDeFgHiJkLmNoPqRsTuVwXyZ` |
| `CORS_ORIGINS` | Allowed origins | No | `*` or comma-separated domains |

> [!CAUTION]
> The application will refuse to start (fail-fast) if `DATABASE_URL`, `JWT_SECRET` (minimum 32 characters), or any Cloudinary credentials are missing or invalid. Never commit `.env` to source control.

---

## 3. Database Schema & Migration Management

### Initializing / Applying Schema Migrations
```bash
cd backend
# With virtual environment activated:
alembic upgrade head
```

### Database Tables (12 Total):
1. `users`: Customer and admin profiles, case-insensitive unique email index, Argon2id password hash, role enum (`customer`, `admin`), active status flag.
2. `refresh_tokens`: SHA-256 hashed refresh tokens with rotation family ID tracking for replay detection.
3. `categories`: Unique name and slug, active flag, sort order.
4. `products`: Unique slug, price (`NUMERIC(10,2)` check $>0$), category foreign key, stock quantity, active status flag (soft-deactivation).
5. `product_images`: Cloudinary URL, public ID, asset ID, width, height, format, byte size, sort order, primary flag (max 8 per product).
6. `delivery_settings`: Single-row global configuration for promotional free delivery threshold and default delivery charge.
7. `delivery_rules`: Tiered delivery pricing by order subtotal with priority sorting.
8. `addresses`: Customer address book with default address tracking.
9. `orders`: Human-readable order number (`ORD-YYYYMMDD-XXXX`), customer foreign key, status enum, server-recalculated subtotal, delivery charge, total, frozen delivery address JSONB snapshot, notes.
10. `order_items`: Order foreign key, product foreign key, frozen product name snapshot, frozen unit price snapshot, quantity, line total.
11. `order_status_history`: Audit trail capturing old status, new status, modifier user ID, comment, and timestamp.
12. `reviews`: Rating ($1 \le \text{rating} \le 5$), comment, visibility moderation flag. Unique constraint `(product_id, customer_id)` enforcing strictly one review per customer per product with authoritative delivered-order purchase verification.

---

## 4. Headless Admin Account Creation
To provision administrator accounts without UI dependency:
```bash
cd backend
python -m scripts.create_admin
```
Interactive prompts will request:
- Email address (e.g., `admin@stitchstyle.com`)
- Full Name
- Secure password (minimum 8 characters)

---

## 5. Running the Backend

### Local Bare-Metal Execution (Windows / Linux):
```cmd
cd backend
scripts\start_prod.bat
```
Or manually:
```bash
cd backend
alembic upgrade head
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2
```

### Docker Container Deployment:
To spin up both isolated PostgreSQL 16 and the FastAPI application using Docker Compose:
```bash
cd backend
docker-compose up --build -d
```
Inspect logs:
```bash
docker-compose logs -f api
```

---

## 6. Database Backups & Restoration

### Backup
Run the automated backup script:
```cmd
cd backend
scripts\backup_db.bat
```
This generates a timestamped plain SQL dump in `backend/backups/`:
`stitch_style_db_backup_YYYYMMDD_HHMMSS.sql`.

### Restore
To restore from a backup:
```cmd
cd backend
scripts\restore_db.bat backups\stitch_style_db_backup_YYYYMMDD_HHMMSS.sql
```

---

## 7. Flutter Mobile App Execution & Role Routing
1. Run `flutter pub get` to install all dependencies.
2. Run `flutter analyze` to confirm clean static analysis.
3. Launch the app on a connected device, emulator, or Chrome:
   ```bash
   flutter run -d chrome
   # or
   flutter run -d <device_id>
   ```

### User Roles & Experience:
- **Customers:** Log in through `LoginScreen` and are directed to the consumer shopping application (catalog, custom stitching, address selection, order tracking, reviews).
- **Administrators:** Log in through the same unified `LoginScreen` using admin credentials. The app immediately recognizes the `admin` role claim from the JWT and launches the **Flutter Admin Panel** (`AdminDashboardScreen`), granting direct control over Products, Cloudinary Photos, Delivery Settings & Rules, Order Fulfillment, and Review Moderation.
