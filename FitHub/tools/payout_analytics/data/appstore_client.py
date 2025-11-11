from __future__ import annotations

import logging
import base64
from dataclasses import dataclass
from datetime import datetime, timezone
from types import SimpleNamespace
from typing import Dict, List, Optional

try:  # Newer library (v2+)
    from app_store_server_library import (
        AppStoreServerAPIClient,
        Environment,
        SignedDataVerifier,
        TransactionHistoryRequest,
    )
    from app_store_server_library.models import TransactionHistoryResponse

    APPSTORE_LIBRARY = "modern"
except ImportError:  # Fallback to legacy library (<=1.6.0)
    from appstoreserverlibrary.api_client import AppStoreServerAPIClient
    from appstoreserverlibrary.models.Environment import Environment
    from appstoreserverlibrary.models.TransactionHistoryRequest import TransactionHistoryRequest
    from appstoreserverlibrary.models.HistoryResponse import HistoryResponse as TransactionHistoryResponse
    from appstoreserverlibrary.signed_data_verifier import SignedDataVerifier

    APPSTORE_LIBRARY = "legacy"

from tools.payout_analytics.utils import ensure_utc


APPLE_ROOT_CERTIFICATES = [
    base64.b64decode(
        "MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBSb290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtfTjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySrMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gAMGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM6BgD56KyKA=="
    )
]


logger = logging.getLogger(__name__)


ENVIRONMENT_ALIASES = {
    None: Environment.PRODUCTION,
    "": Environment.PRODUCTION,
    "PRODUCTION": Environment.PRODUCTION,
    "Production": Environment.PRODUCTION,
    "Sandbox": Environment.SANDBOX,
    "SANDBOX": Environment.SANDBOX,
    "XCODE": Environment.SANDBOX,
}


@dataclass
class DecodedTransaction:
    original_transaction_id: str
    transaction_id: str
    product_id: str
    purchase_date: Optional[datetime]
    expires_date: Optional[datetime]
    currency: Optional[str]
    price: Optional[float]
    transaction_reason: Optional[str]
    environment: str
    data: Dict


class AppStoreClient:
    def __init__(
        self,
        issuer_id: str,
        key_id: str,
        private_key: str,
        bundle_id: str,
        app_apple_id: Optional[str] = None,
    ) -> None:
        self.bundle_id = bundle_id
        self.app_apple_id = app_apple_id

        private_key = private_key.strip()
        signing_key_bytes = private_key.encode("utf-8")
        self._clients = {
            Environment.PRODUCTION: AppStoreServerAPIClient(
                signing_key_bytes, key_id, issuer_id, bundle_id, Environment.PRODUCTION
            ),
            Environment.SANDBOX: AppStoreServerAPIClient(
                signing_key_bytes, key_id, issuer_id, bundle_id, Environment.SANDBOX
            ),
        }
        self._verifiers = {
            Environment.PRODUCTION: SignedDataVerifier(
                APPLE_ROOT_CERTIFICATES, True, Environment.PRODUCTION, bundle_id, app_apple_id
            ),
            Environment.SANDBOX: SignedDataVerifier(
                APPLE_ROOT_CERTIFICATES, True, Environment.SANDBOX, bundle_id, None
            ),
        }

    def _resolve_environment(self, value: Optional[str]) -> Environment:
        env = ENVIRONMENT_ALIASES.get(value, Environment.PRODUCTION)
        return env

    def get_transaction_history(
        self,
        original_transaction_id: str,
        environment: Optional[str] = None,
    ) -> List[DecodedTransaction]:
        env = self._resolve_environment(environment)
        client = self._clients[env]
        env_value = getattr(env, "value", env)
        verifier = self._verifiers[env]

        request = TransactionHistoryRequest()
        sort_attr = getattr(TransactionHistoryRequest, "Sort", None)
        if sort_attr and hasattr(sort_attr, "ASCENDING"):
            request.sort = sort_attr.ASCENDING
        else:
            request.sort = SimpleNamespace(value="ASCENDING")

        if APPSTORE_LIBRARY == "legacy":
            response: TransactionHistoryResponse = client.get_transaction_history(
                original_transaction_id, None, request
            )
        else:
            response = client.get_transaction_history(original_transaction_id, request)

        def _get(payload, key, default=None):
            if isinstance(payload, dict):
                return payload.get(key, default)
            return getattr(payload, key, default)

        transactions: List[DecodedTransaction] = []
        signed_transactions = response.signedTransactions or []
        decode_transaction = getattr(verifier, "verify_and_decode_transaction", None)
        if decode_transaction is None:
            decode_transaction = verifier.verify_and_decode_signed_transaction
        for signed_info in signed_transactions:
            try:
                decoded = decode_transaction(signed_info)
            except Exception as err:  # pragma: no cover - defensive
                logger.error(
                    "Failed to decode transaction for originalTransactionId=%s: %s",
                    original_transaction_id,
                    err,
                )
                continue

            purchase_date_ms = _get(decoded, "purchaseDate")
            expires_date_ms = _get(decoded, "expiresDate")

            purchase_date = ensure_utc(datetime.fromtimestamp(purchase_date_ms / 1000, tz=timezone.utc)) if purchase_date_ms else None  # type: ignore[assignment]
            expires_date = (
                ensure_utc(datetime.fromtimestamp(expires_date_ms / 1000, tz=timezone.utc))
                if expires_date_ms
                else None
            )

            transactions.append(
                DecodedTransaction(
                    original_transaction_id=_get(decoded, "originalTransactionId"),
                    transaction_id=_get(decoded, "transactionId"),
                    product_id=_get(decoded, "productId"),
                    purchase_date=purchase_date,
                    expires_date=expires_date,
                    currency=_get(decoded, "currency"),
                    price=_get(decoded, "price"),
                    transaction_reason=_get(decoded, "transactionReason"),
                    environment=_get(decoded, "environment", env_value),
                    data=decoded,
                )
            )

        logger.info(
            "Fetched %d transactions for originalTransactionId=%s (%s environment)",
            len(transactions),
            original_transaction_id,
            env_value,
        )
        return transactions

    def get_subscription_statuses(
        self, original_transaction_id: str, environment: Optional[str] = None
    ):
        env = self._resolve_environment(environment)
        client = self._clients[env]
        response = client.get_all_subscription_statuses(original_transaction_id)
        return response


