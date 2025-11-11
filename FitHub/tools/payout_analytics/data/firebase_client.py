from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict, Iterable, List, Optional

import firebase_admin
from firebase_admin import auth, credentials, firestore
from firebase_admin.firestore import ArrayUnion


logger = logging.getLogger(__name__)


@dataclass
class FirestoreUserDocument:
    uid: str
    data: Dict


@dataclass
class ReferralCodeDocument:
    code: str
    data: Dict


class FirebaseClient:
    def __init__(self, credential_path: Optional[str] = None) -> None:
        if not firebase_admin._apps:
            if credential_path:
                cred = credentials.Certificate(credential_path)
                firebase_admin.initialize_app(cred)
                logger.info("Initialized Firebase app with service account at %s", credential_path)
            else:
                firebase_admin.initialize_app()
                logger.info("Initialized Firebase app using default credentials.")
        else:
            logger.debug("Firebase app already initialized; reusing existing instance.")

        self._firestore = firestore.client()

    # --------------------------------------------------------------------- #
    # Authentication helpers
    # --------------------------------------------------------------------- #
    def list_all_auth_users(self) -> List[auth.UserRecord]:
        """
        Retrieve all Firebase Auth users.
        """
        users: List[auth.UserRecord] = []
        page = auth.list_users()
        while page:
            users.extend(page.users)
            logger.debug("Fetched %d auth users (total so far: %d)", len(page.users), len(users))
            page = page.get_next_page()
        logger.info("Loaded %d Firebase Auth users.", len(users))
        return users

    # --------------------------------------------------------------------- #
    # Firestore helpers
    # --------------------------------------------------------------------- #
    def stream_user_documents(self) -> Iterable[FirestoreUserDocument]:
        users_ref = self._firestore.collection("users")
        for doc in users_ref.stream():
            yield FirestoreUserDocument(uid=doc.id, data=doc.to_dict() or {})

    def stream_referral_codes(self) -> Iterable[ReferralCodeDocument]:
        codes_ref = self._firestore.collection("referralCodes")
        for doc in codes_ref.stream():
            yield ReferralCodeDocument(code=doc.id, data=doc.to_dict() or {})

    def record_payout_run(
        self,
        referral_code: str,
        run_id: str,
        run_amount: Decimal,
        new_total_paid: Decimal,
        currency: str,
        transaction_ids: List[str],
        stripe_transfer_id: Optional[str],
        executed_at: datetime,
    ) -> None:
        """
        Append payout metadata to the referral code document so future runs know which
        transactions have already been paid.
        """
        code = referral_code.upper()
        doc_ref = self._firestore.collection("referralCodes").document(code)

        payout_record = {
            "runId": run_id,
            "amount": str(run_amount.quantize(Decimal("0.01"))),
            "currency": currency,
            "transactionIds": transaction_ids,
            "stripeTransferId": stripe_transfer_id,
            "executedAt": executed_at,
        }

        update_payload: Dict[str, Any] = {
            "payout.lastRunAt": firestore.SERVER_TIMESTAMP,
            "payout.totalPaid": str(new_total_paid.quantize(Decimal("0.01"))),
            "payout.currency": currency,
            "payout.runs": ArrayUnion([payout_record]),
        }

        if transaction_ids:
            update_payload["payout.processedTransactionIds"] = ArrayUnion(transaction_ids)

        doc_ref.set({"payout": {}}, merge=True)
        doc_ref.update(update_payload)
        logger.info(
            "Recorded payout run %s for referral code %s (amount=%s %s, transactions=%d).",
            run_id,
            code,
            run_amount,
            currency,
            len(transaction_ids),
        )


