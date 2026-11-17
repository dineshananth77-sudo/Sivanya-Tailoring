import hashlib
import secrets


def generate_secure_token(byte_length: int = 48) -> str:
    """Generates a high-entropy URL-safe random string for refresh tokens."""
    return secrets.token_urlsafe(byte_length)


def hash_token(raw_token: str) -> str:
    """Computes SHA-256 hash of a raw token string for safe database storage."""
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
