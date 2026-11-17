from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError, InvalidHashError, VerificationError
import logging

logger = logging.getLogger("stitch_style.security.password")

# Argon2id hasher configured per OWASP password storage recommendations
_hasher = PasswordHasher(
    time_cost=3,        # 3 iterations
    memory_cost=65536,  # 64 MiB
    parallelism=4,      # 4 lanes/threads
    hash_len=32,        # 32 bytes output
)


def hash_password(password: str) -> str:
    """Hashes a plaintext password using Argon2id with random salt."""
    if not password or len(password) < 8:
        raise ValueError("Password must be at least 8 characters.")
    return _hasher.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies a plaintext password against an Argon2id hash."""
    if not plain_password or not hashed_password:
        return False
    try:
        return _hasher.verify(hashed_password, plain_password)
    except (VerifyMismatchError, InvalidHashError, VerificationError):
        return False
    except Exception as e:
        logger.error(f"Unexpected error during password verification: {e}")
        return False


def needs_rehash(hashed_password: str) -> bool:
    """Checks if password hash parameters are outdated."""
    try:
        return _hasher.check_needs_rehash(hashed_password)
    except Exception:
        return False
