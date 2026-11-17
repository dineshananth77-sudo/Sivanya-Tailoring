import argparse
import getpass
import os
import re
import secrets
import string
import sys

# Ensure backend root is in search path
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from app.database import get_db_context
from app.models.user import User, UserRole
from app.repositories.user_repo import UserRepository
from app.security.password import hash_password


def generate_strong_password(length: int = 24) -> str:
    """Generates a high-entropy password with uppercase, lowercase, digits, and special characters."""
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*()-_=+[]{}|;:,.<>?"
    while True:
        password = ''.join(secrets.choice(alphabet) for _ in range(length))
        if (any(c.islower() for c in password)
                and any(c.isupper() for c in password)
                and any(c.isdigit() for c in password)
                and any(c in "!@#$%^&*()-_=+[]{}|;:,.<>?" for c in password)):
            return password


def is_valid_email(email: str) -> bool:
    pattern = r"^[^@]+@[^@]+\.[^@]+$"
    return bool(re.match(pattern, email.strip()))


def create_or_update_admin(email: str, full_name: str, password: str, phone: str | None = None) -> User:
    with get_db_context() as db:
        existing = UserRepository.get_by_email(db, email)
        password_hash = hash_password(password)

        if existing:
            existing.full_name = full_name.strip()
            existing.password_hash = password_hash
            existing.role = UserRole.ADMIN.value
            existing.is_active = True
            if phone:
                existing.phone = phone.strip()
            db.flush()
            print(f"[SUCCESS] Existing user '{email}' promoted to Admin role with new password.")
            return existing
        else:
            admin_user = UserRepository.create_user(
                db=db,
                email=email,
                password_hash=password_hash,
                full_name=full_name,
                phone=phone,
                role=UserRole.ADMIN.value,
                is_active=True
            )
            print(f"[SUCCESS] New Admin user '{email}' created successfully.")
            return admin_user


def main():
    parser = argparse.ArgumentParser(
        description="Provision or update an Administrator account for Stitch & Style."
    )
    parser.add_argument("--email", required=True, help="Administrator email address")
    parser.add_argument("--name", default="System Administrator", help="Administrator full name")
    parser.add_argument("--phone", default=None, help="Administrator phone number (optional)")
    parser.add_argument("--generate-password", action="store_true", help="Auto-generate a strong password and print once")
    parser.add_argument("--password", default=None, help="Directly specify password (e.g. for non-interactive test provisioning)")

    args = parser.parse_args()
    email = args.email.strip().lower()

    if not is_valid_email(email):
        print(f"[ERROR] Invalid email address: '{email}'")
        sys.exit(1)

    if args.generate_password:
        password = generate_strong_password()
        print("\n=======================================================")
        print("  GENERATED ADMIN CREDENTIALS (SAVE SECURELY)")
        print(f"  Email:    {email}")
        print(f"  Password: {password}")
        print("  Note: This password will NOT be displayed again.")
        print("=======================================================\n")
    elif args.password:
        password = args.password
    else:
        password = getpass.getpass("Enter Admin Password: ")
        if len(password) < 8:
            print("[ERROR] Password must be at least 8 characters.")
            sys.exit(1)
        confirm = getpass.getpass("Confirm Admin Password: ")
        if password != confirm:
            print("[ERROR] Passwords do not match.")
            sys.exit(1)

    if len(password) < 8:
        print("[ERROR] Password must be at least 8 characters.")
        sys.exit(1)

    create_or_update_admin(
        email=email,
        full_name=args.name,
        password=password,
        phone=args.phone
    )


if __name__ == "__main__":
    main()
