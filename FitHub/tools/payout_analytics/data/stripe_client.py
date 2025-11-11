from __future__ import annotations

import logging
from dataclasses import dataclass
from decimal import Decimal
from typing import Any, Dict, Optional

import stripe
try:
    from stripe import _error as stripe_error  # stripe>=13.x
except ImportError:
    import stripe.error as stripe_error  # stripe<=2.x


logger = logging.getLogger(__name__)


@dataclass
class StripeTransferResult:
    amount: Decimal
    currency: str
    destination: str
    transfer_id: Optional[str]
    dry_run: bool
    response: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None


class StripeClient:
    def __init__(
        self,
        secret_key: Optional[str],
        currency: str,
        dry_run: bool = True,
        transfer_descriptor: Optional[str] = None,
    ) -> None:
        self.currency = currency.lower()
        self.dry_run = dry_run
        self.transfer_descriptor = transfer_descriptor

        if secret_key:
            stripe.api_key = secret_key
            logger.info("Stripe client initialised (dry_run=%s).", dry_run)
        else:
            logger.warning("Stripe secret key not provided; running in dry-run mode.")
            self.dry_run = True

    @staticmethod
    def _to_cents(amount: Decimal) -> int:
        return int((amount * Decimal("100")).quantize(Decimal("1")))

    def create_transfer(
        self,
        amount: Decimal,
        destination_account: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> StripeTransferResult:
        """
        Create a transfer to a connected account. When dry_run is True,
        no Stripe API call is made and a simulated result is returned.
        """
        if amount <= Decimal("0.00"):
            logger.info(
                "Skipping Stripe transfer to %s because amount is %s.",
                destination_account,
                amount,
            )
            return StripeTransferResult(
                amount=amount,
                currency=self.currency,
                destination=destination_account,
                transfer_id=None,
                dry_run=True,
                response=None,
            )

        cents = self._to_cents(amount)
        metadata = metadata or {}
        metadata.setdefault("platform", "FitHub")

        logger.info(
            "Preparing Stripe transfer: %s %s to account %s (dry_run=%s).",
            amount,
            self.currency,
            destination_account,
            self.dry_run,
        )

        if self.dry_run:
            return StripeTransferResult(
                amount=amount,
                currency=self.currency,
                destination=destination_account,
                transfer_id=None,
                dry_run=True,
                response={"status": "dry_run"},
            )

        try:
            response = stripe.Transfer.create(
                amount=cents,
                currency=self.currency,
                destination=destination_account,
                description=self.transfer_descriptor,
                metadata=metadata,
            )
            transfer_id = response.get("id")
            logger.info(
                "Stripe transfer %s created for account %s (%s %s).",
                transfer_id,
                destination_account,
                amount,
                self.currency,
            )
            return StripeTransferResult(
                amount=amount,
                currency=self.currency,
                destination=destination_account,
                transfer_id=transfer_id,
                dry_run=False,
                response=response,
            )
        except stripe_error.StripeError as exc:  # pragma: no cover - Stripe API
            logger.error(
                "Stripe transfer failed for account %s (%s %s): %s",
                destination_account,
                amount,
                self.currency,
                exc,
            )
            return StripeTransferResult(
                amount=amount,
                currency=self.currency,
                destination=destination_account,
                transfer_id=None,
                dry_run=True,
                response=None,
                error_message=str(exc),
            )
        except Exception as exc:  # pragma: no cover - defensive
            logger.error(
                "Unexpected error creating Stripe transfer for account %s (%s %s): %s",
                destination_account,
                amount,
                self.currency,
                exc,
            )
            return StripeTransferResult(
                amount=amount,
                currency=self.currency,
                destination=destination_account,
                transfer_id=None,
                dry_run=True,
                response=None,
                error_message=str(exc),
            )



