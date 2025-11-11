from __future__ import annotations

import os
from dataclasses import dataclass, field
from decimal import Decimal
from pathlib import Path
from typing import Dict, Optional

from datetime import datetime
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


DEFAULT_OUTPUT_DIR = Path.home() / "Desktop" / "FitHubPayoutReports"


@dataclass
class AppConfig:
    issuer_id: str
    key_id: str
    private_key: str
    bundle_id: str
    app_apple_id: Optional[str]
    firebase_credential_path: Optional[Path]
    output_dir: Path
    report_currency: str
    affiliate_share: Decimal
    stripe_secret_key: Optional[str]
    stripe_currency: str
    stripe_transfer_descriptor: Optional[str]
    stripe_dry_run: bool
    display_timezone: ZoneInfo
    product_prices: Dict[str, Decimal] = field(default_factory=dict)


def _get_env(name: str, default: Optional[str] = None, required: bool = False) -> Optional[str]:
    value = os.getenv(name, default)
    if required and (value is None or value.strip() == ""):
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def load_config() -> AppConfig:
    """
    Load configuration from environment variables.
    Expected environment variables:
      - APPSTORE_ISSUER_ID
      - APPSTORE_KEY_ID
      - APPSTORE_PRIVATE_KEY (with literal \\n for line breaks)
      - APPSTORE_BUNDLE_ID
      - APPSTORE_APP_APPLE_ID (optional)
      - GOOGLE_APPLICATION_CREDENTIALS (service account JSON)
      - FITHUB_REPORT_OUTPUT_DIR (optional override)
    """
    issuer_id = _get_env("APPSTORE_ISSUER_ID", required=True)
    key_id = _get_env("APPSTORE_KEY_ID", required=True)
    private_key_raw = _get_env("APPSTORE_PRIVATE_KEY", required=True)
    bundle_id = _get_env("APPSTORE_BUNDLE_ID", required=True)
    app_apple_id = _get_env("APPSTORE_APP_APPLE_ID")

    # Replace escaped newlines so jwt library can parse the key
    private_key = private_key_raw.replace("\\n", "\n").strip()

    firebase_credential_env = _get_env("GOOGLE_APPLICATION_CREDENTIALS")
    firebase_credential_path = (
        Path(firebase_credential_env).expanduser().resolve() if firebase_credential_env else None
    )

    output_dir_env = _get_env("FITHUB_REPORT_OUTPUT_DIR")
    output_dir = Path(output_dir_env).expanduser().resolve() if output_dir_env else DEFAULT_OUTPUT_DIR

    report_currency = _get_env("FITHUB_REPORT_CURRENCY", "USD")
    affiliate_share = Decimal(_get_env("FITHUB_AFFILIATE_SHARE", "0.40"))

    stripe_secret_key = _get_env("STRIPE_SECRET_KEY")
    stripe_currency = _get_env("STRIPE_PAYOUT_CURRENCY", report_currency).upper()
    stripe_transfer_descriptor = _get_env("STRIPE_TRANSFER_DESCRIPTION")
    stripe_dry_run = _get_env("FITHUB_STRIPE_DRY_RUN", "true").lower() in {"true", "1", "yes"}

    tz_env = _get_env("FITHUB_TIMEZONE")
    if tz_env:
        try:
            display_timezone = ZoneInfo(tz_env)
        except ZoneInfoNotFoundError as exc:
            raise RuntimeError(f"Invalid timezone specified in FITHUB_TIMEZONE: {tz_env}") from exc
    else:
        display_timezone = datetime.now().astimezone().tzinfo or ZoneInfo("UTC")

    # Hard-coded prices provided by Anthony (USD)
    product_prices = {
        "com.FitHub.premium.monthly": Decimal("3.99"),
        "com.FitHub.premium.yearly": Decimal("29.99"),
        "com.FitHub.premium.lifetime": Decimal("89.99"),
    }

    return AppConfig(
        issuer_id=issuer_id,
        key_id=key_id,
        private_key=private_key,
        bundle_id=bundle_id,
        app_apple_id=app_apple_id,
        firebase_credential_path=firebase_credential_path,
        output_dir=output_dir,
        report_currency=report_currency,
        affiliate_share=affiliate_share,
        stripe_secret_key=stripe_secret_key,
        stripe_currency=stripe_currency,
        stripe_transfer_descriptor=stripe_transfer_descriptor,
        stripe_dry_run=stripe_dry_run,
        display_timezone=display_timezone,
        product_prices=product_prices,
    )


