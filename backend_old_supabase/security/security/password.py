from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError, VerificationError

# Create password hasher
password_hasher = PasswordHasher()


# Hash a password
def hash_password(password: str) -> str:
    return password_hasher.hash(password)


# Verify a password
def verify_password(password: str, stored_hash: str) -> bool:
    try:
        return password_hasher.verify(stored_hash, password)

    except (VerifyMismatchError, VerificationError):
        return False