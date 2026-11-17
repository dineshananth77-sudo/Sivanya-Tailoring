import time
from collections import defaultdict
from threading import Lock
from fastapi import Request

from app.exceptions import AppException


class InMemoryRateLimiter:
    """Sliding-window in-memory rate limiter per client IP or key."""

    def __init__(self):
        self._records = defaultdict(list)
        self._lock = Lock()

    def check(self, key: str, max_requests: int, window_seconds: int) -> None:
        now = time.time()
        window_start = now - window_seconds

        with self._lock:
            # Purge expired records
            valid_timestamps = [t for t in self._records[key] if t > window_start]
            if len(valid_timestamps) >= max_requests:
                retry_after = int(window_seconds - (now - valid_timestamps[0]))
                raise AppException(
                    code="RATE_LIMIT_EXCEEDED",
                    message=f"Too many requests. Please try again in {max(1, retry_after)} seconds.",
                    status_code=429,
                    details={"retry_after_seconds": max(1, retry_after)}
                )

            valid_timestamps.append(now)
            self._records[key] = valid_timestamps

    def reset_for_key(self, key: str) -> None:
        """Helper to clear rate limit state (useful in tests)."""
        with self._lock:
            self._records.pop(key, None)


limiter = InMemoryRateLimiter()


def rate_limit(max_requests: int, window_seconds: int, scope: str = "general"):
    """FastAPI route dependency that enforces rate limits per client IP."""
    async def dependency(request: Request):
        client_ip = request.client.host if request.client else "unknown"
        key = f"{scope}:{client_ip}"
        limiter.check(key=key, max_requests=max_requests, window_seconds=window_seconds)
    return dependency
