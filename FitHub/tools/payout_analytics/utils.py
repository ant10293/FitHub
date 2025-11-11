from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from decimal import Decimal


UTC = timezone.utc


def utc_now() -> datetime:
    return datetime.now(tz=UTC)


def parse_iso8601(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(UTC)


def ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt.astimezone(UTC)


def default_window(days: int = 7) -> tuple[datetime, datetime]:
    end = utc_now()
    start = end - timedelta(days=days)
    return start, end


def decimal_from_micros(amount: int, exponent: int = 6) -> Decimal:
    """
    Helper for Apple price fields that are returned as integer micro-units.
    """
    quantizer = Decimal(10) ** -exponent
    return (Decimal(amount) * quantizer).quantize(quantizer)


