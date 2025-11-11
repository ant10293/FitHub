from __future__ import annotations

import argparse
import logging
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path
from typing import Dict, List, Optional

from dotenv import load_dotenv

from tools.payout_analytics.analytics.metrics import (
    SubscriptionMetrics,
    UserSnapshot,
    compute_subscription_metrics,
    compute_user_metrics,
)
from tools.payout_analytics.analytics.payouts import (
    ReferralCodeSnapshot,
    TransactionRecord,
    build_transaction_records,
    compute_influencer_payouts,
)
from tools.payout_analytics.config import AppConfig, load_config
from tools.payout_analytics.data.appstore_client import AppStoreClient, DecodedTransaction
from tools.payout_analytics.data.firebase_client import FirebaseClient
from tools.payout_analytics.data.stripe_client import StripeClient
from tools.payout_analytics.logging_utils import setup_logging
from tools.payout_analytics.reporting.renderer import render_csv
from tools.payout_analytics.utils import default_window, ensure_utc, utc_now

logger = logging.getLogger(__name__)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="FitHub Affiliate Payout Analytics")
    parser.add_argument("--start", help="Reporting window start (ISO 8601). Defaults to 7 days ago.")
    parser.add_argument("--end", help="Reporting window end (ISO 8601). Defaults to now (UTC).")
    parser.add_argument(
        "--output",
        type=Path,
        help="Optional override for output directory (defaults to Desktop/FitHubPayoutReports).",
    )
    parser.add_argument(
        "--manual",
        action="store_true",
        help="Mark the run as manual (only affects log naming).",
    )
    parser.add_argument(
        "--execute-payouts",
        action="store_true",
        help="Execute Stripe transfers and update payout ledgers (overrides config dry-run).",
    )
    return parser.parse_args()


def determine_window(args: argparse.Namespace) -> tuple[datetime, datetime]:
    if args.start:
        start = ensure_utc(datetime.fromisoformat(args.start.replace("Z", "+00:00")))
    else:
        start, _ = default_window()

    if args.end:
        end = ensure_utc(datetime.fromisoformat(args.end.replace("Z", "+00:00")))
    else:
        _, end = default_window()

    if end <= start:
        raise ValueError("End timestamp must be after start timestamp.")
    return start, end


def collect_user_snapshots(
    auth_users,
    firestore_users,
) -> List[UserSnapshot]:
    firestore_map = {doc.uid: doc.data for doc in firestore_users}
    tz = timezone.utc
    snapshots: List[UserSnapshot] = []

    for auth_user in auth_users:
        creation_dt = datetime.fromtimestamp(
            auth_user.user_metadata.creation_timestamp / 1000, tz=tz
        )
        user_doc = firestore_map.get(auth_user.uid, {})

        subscription_status = user_doc.get("subscriptionStatus", {}) or {}
        referral_purchase_date = user_doc.get("referralPurchaseDate")
        if isinstance(referral_purchase_date, datetime):
            referral_purchase_date = ensure_utc(referral_purchase_date)

        referral_code_claimed_at = user_doc.get("referralCodeClaimedAt")
        if isinstance(referral_code_claimed_at, datetime):
            referral_code_claimed_at = ensure_utc(referral_code_claimed_at)

        snapshots.append(
            UserSnapshot(
                uid=auth_user.uid,
                email=auth_user.email,
                creation_time=creation_dt,
                referral_code=user_doc.get("referralCode"),
                referral_code_claimed_at=referral_code_claimed_at,
                referral_purchase_product_id=user_doc.get("referralPurchaseProductID"),
                referral_purchase_date=referral_purchase_date,
                subscription_status=subscription_status,
                is_referral_purchase=user_doc.get("referralCodeUsedForPurchase", False),
            )
        )
    logger.info("Prepared %d user snapshots.", len(snapshots))
    return snapshots


def collect_referral_codes(documents) -> Dict[str, ReferralCodeSnapshot]:
    codes: Dict[str, ReferralCodeSnapshot] = {}
    for doc in documents:
        data = doc.data
        payout_info = data.get("payout") or {}
        processed_ids = {str(tid) for tid in payout_info.get("processedTransactionIds", [])}
        total_paid_raw = payout_info.get("totalPaid")
        try:
            total_paid = Decimal(str(total_paid_raw)) if total_paid_raw is not None else Decimal("0.00")
        except Exception:
            total_paid = Decimal("0.00")
        payout_currency = payout_info.get("currency")
        stripe_account_id = payout_info.get("accountId") or data.get("stripeAccountId")
        codes[doc.code.upper()] = ReferralCodeSnapshot(
            code=doc.code.upper(),
            influencer_name=data.get("influencerName"),
            influencer_email=data.get("influencerEmail"),
            payout_account_id=stripe_account_id,
            payout_provider=payout_info.get("provider"),
            payout_frequency=(payout_info.get("frequency") or data.get("payoutFrequency")),
            data=data,
            processed_transaction_ids=processed_ids,
            total_paid=total_paid,
            payout_currency=payout_currency,
        )
    logger.info("Loaded %d referral codes.", len(codes))
    return codes


def fetch_transactions_for_users(
    appstore: AppStoreClient,
    user_snapshots: List[UserSnapshot],
) -> Dict[str, List[DecodedTransaction]]:
    transactions: Dict[str, List[DecodedTransaction]] = {}
    for user in user_snapshots:
        original_transaction_id = (user.subscription_status or {}).get("originalTransactionID")
        if not original_transaction_id or str(original_transaction_id).strip() in {"0", ""}:
            logger.debug(
                "Skipping user %s because originalTransactionID is missing or zero (%s).",
                user.uid,
                original_transaction_id,
            )
            continue
        environment = (user.subscription_status or {}).get("environment")
        try:
            user_transactions = appstore.get_transaction_history(
                original_transaction_id,
                environment=environment,
            )
            transactions[user.uid] = user_transactions
        except Exception as exc:  # pragma: no cover - external dependency
            logger.error(
                "Failed to fetch transactions for user %s (originalTransactionId=%s): %s",
                user.uid,
                original_transaction_id,
                exc,
            )
    return transactions


def main() -> None:
    load_dotenv()
    args = parse_args()
    config: AppConfig = load_config()

    if args.output:
        config.output_dir = args.output.expanduser().resolve()

    start, end = determine_window(args)
    date_folder = start.strftime("%Y-%m-%d")
    run_id = utc_now().strftime("%Y%m%d_%H%M%S_manual" if args.manual else "%Y%m%d_%H%M%S")
    log_path = setup_logging(config.output_dir, run_id, date_folder)
    logger.info("Starting payout analytics run %s. Logs at %s", run_id, log_path)

    logger.info("Reporting window: %s → %s", start.isoformat(), end.isoformat())

    firebase = FirebaseClient(
        credential_path=str(config.firebase_credential_path) if config.firebase_credential_path else None
    )
    auth_users = firebase.list_all_auth_users()
    firestore_users = list(firebase.stream_user_documents())
    referral_codes = collect_referral_codes(firebase.stream_referral_codes())

    user_snapshots = collect_user_snapshots(auth_users, firestore_users)

    appstore_client = AppStoreClient(
        issuer_id=config.issuer_id,
        key_id=config.key_id,
        private_key=config.private_key,
        bundle_id=config.bundle_id,
        app_apple_id=config.app_apple_id,
    )

    transactions_by_user = fetch_transactions_for_users(appstore_client, user_snapshots)

    # Map of user ID to Firestore referral info (we retain raw data for payout decision)
    user_referral_map = {doc.uid: doc.data for doc in firestore_users}

    transaction_records = build_transaction_records(
        transactions_by_user,
        user_referral_map,
        product_prices=config.product_prices,
        start=start,
        end=end,
    )

    total_revenue = sum((record.price for record in transaction_records), Decimal("0.00"))

    influencer_payouts = compute_influencer_payouts(
        transaction_records,
        referral_codes,
        affiliate_share=config.affiliate_share,
    )
    total_affiliate_payout = sum((p.total_payout for p in influencer_payouts.values()), Decimal("0.00"))

    stripe_dry_run = config.stripe_dry_run
    if args.execute_payouts:
        stripe_dry_run = False

    stripe_client = StripeClient(
        secret_key=config.stripe_secret_key,
        currency=config.stripe_currency,
        dry_run=stripe_dry_run,
        transfer_descriptor=config.stripe_transfer_descriptor,
    )

    for code, payout in influencer_payouts.items():
        payout.stripe_dry_run = stripe_client.dry_run

        if not payout.transaction_ids:
            payout.notes.append("No new referral transactions in this window.")
            continue

        if payout.total_payout <= Decimal("0.00"):
            if payout.total_payout < Decimal("0.00"):
                payout.notes.append("Net negative balance (credit carried forward).")
            else:
                payout.notes.append("No positive payout due.")
            continue

        if not payout.payout_account_id:
            note = "Missing payout account ID; manual follow-up required."
            payout.notes.append(note)
            logger.warning("Referral %s has no payout account; skipping transfer.", code)
            continue

        unique_transaction_ids = sorted(set(payout.transaction_ids))
        metadata = {
            "run_id": run_id,
            "referral_code": code,
            "transactions": ",".join(unique_transaction_ids[:20]),
        }
        transfer_result = stripe_client.create_transfer(
            amount=payout.total_payout,
            destination_account=payout.payout_account_id,
            metadata=metadata,
        )
        payout.stripe_transfer_id = transfer_result.transfer_id
        payout.stripe_dry_run = transfer_result.dry_run

        if transfer_result.dry_run:
            payout.notes.append("Dry-run mode: transfer not sent.")
            continue

        if transfer_result.error_message:
            payout.notes.append(f"Stripe error: {transfer_result.error_message}")
            continue

        if not transfer_result.transfer_id:
            payout.notes.append("Stripe transfer failed without ID; see logs.")
            continue

        new_total_paid = payout.existing_total_paid + payout.total_payout
        firebase.record_payout_run(
            referral_code=code,
            run_id=run_id,
            run_amount=payout.total_payout,
            new_total_paid=new_total_paid,
            currency=config.stripe_currency,
            transaction_ids=unique_transaction_ids,
            stripe_transfer_id=transfer_result.transfer_id,
            executed_at=utc_now(),
        )
        payout.existing_total_paid = new_total_paid
        payout.notes.append(f"Stripe transfer {transfer_result.transfer_id} sent.")
        payout.notes.append(
            f"Lifetime paid: {new_total_paid.quantize(Decimal('0.01'))} {config.stripe_currency}"
        )

    user_metrics = compute_user_metrics(user_snapshots, start, end)
    subscription_metrics = compute_subscription_metrics(user_snapshots, transactions_by_user, start, end)

    report_dir = config.output_dir / "reports" / date_folder
    report_dir.mkdir(parents=True, exist_ok=True)
    report_path = report_dir / f"{run_id}.csv"

    render_csv(
        output_path=report_path,
        run_id=run_id,
        start=start,
        end=end,
        display_timezone=config.display_timezone,
        user_metrics=user_metrics,
        subscription_metrics=subscription_metrics,
        influencer_payouts=influencer_payouts,
        transactions=transaction_records,
        total_revenue=total_revenue,
        total_affiliate_payout=total_affiliate_payout,
        currency=config.report_currency,
    )

    logger.info("Report written to %s", report_path)


if __name__ == "__main__":  # pragma: no cover
    main()


