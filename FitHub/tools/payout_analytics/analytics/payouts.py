from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal
from typing import Dict, Iterable, List, Optional

from tools.payout_analytics.data.appstore_client import DecodedTransaction


logger = logging.getLogger(__name__)


@dataclass
class ReferralCodeSnapshot:
    code: str
    influencer_name: Optional[str]
    influencer_email: Optional[str]
    payout_account_id: Optional[str]
    payout_provider: Optional[str]
    payout_frequency: Optional[str]
    data: Dict
    processed_transaction_ids: set = field(default_factory=set)
    total_paid: Decimal = Decimal("0.00")
    payout_currency: Optional[str] = None


@dataclass
class TransactionRecord:
    user_id: str
    referral_code: Optional[str]
    product_id: str
    purchase_date: datetime
    price: Decimal
    currency: str
    transaction_reason: Optional[str]
    original_transaction_id: str
    environment: str
    transaction_id: Optional[str]


@dataclass
class InfluencerPayout:
    referral_code: str
    influencer_name: Optional[str]
    influencer_email: Optional[str]
    payout_account_id: Optional[str]
    payout_provider: Optional[str]
    payout_frequency: Optional[str]
    total_revenue: Decimal = Decimal("0.00")
    total_payout: Decimal = Decimal("0.00")
    transaction_count: int = 0
    transaction_ids: List[str] = field(default_factory=list)
    existing_total_paid: Decimal = Decimal("0.00")
    currency: str = "USD"
    stripe_transfer_id: Optional[str] = None
    stripe_dry_run: bool = True
    notes: List[str] = field(default_factory=list)


def build_transaction_records(
    user_transactions: Dict[str, List[DecodedTransaction]],
    user_referrals: Dict[str, Dict],
    product_prices: Dict[str, Decimal],
    start: datetime,
    end: datetime,
) -> List[TransactionRecord]:
    records: List[TransactionRecord] = []

    for uid, txs in user_transactions.items():
        referral_data = user_referrals.get(uid, {})
        referral_code = referral_data.get("referralCode")
        referral_used = referral_data.get("referralCodeUsedForPurchase", False)

        # Skip if transaction outside reporting window or price unavailable
        for tx in txs:
            if not tx.purchase_date:
                continue
            if not (start <= tx.purchase_date <= end):
                continue

            expected_price = product_prices.get(tx.product_id)
            price_value: Optional[Decimal] = None
            if tx.price is not None:
                price_value = Decimal(str(tx.price))
                if expected_price:
                    if price_value != expected_price:
                        ratio = price_value / expected_price
                        if Decimal("99") <= ratio <= Decimal("101"):
                            price_value = (price_value / Decimal("100")).quantize(Decimal("0.01"))
                        elif Decimal("999") <= ratio <= Decimal("1001"):
                            price_value = (price_value / Decimal("1000")).quantize(Decimal("0.01"))
                        elif Decimal("9999") <= ratio <= Decimal("10001"):
                            price_value = (price_value / Decimal("10000")).quantize(Decimal("0.01"))
                elif price_value >= Decimal("1000"):
                    price_value = (price_value / Decimal("1000")).quantize(Decimal("0.01"))
            else:
                price_value = expected_price
                if price_value is not None:
                    logger.warning(
                        "Transaction %s missing price; falling back to static price for product %s",
                        tx.transaction_id,
                        tx.product_id,
                    )

            if price_value is None:
                logger.warning(
                    "Skipping transaction %s (product %s) because price is unavailable",
                    tx.transaction_id,
                    tx.product_id,
                )
                continue

            # Only count toward payouts if the purchase was attributed to a referral
            code_for_payout = referral_code if referral_used else None

            records.append(
                TransactionRecord(
                    user_id=uid,
                    referral_code=code_for_payout,
                    product_id=tx.product_id,
                    purchase_date=tx.purchase_date,
                    price=price_value,
                    currency=tx.currency or "USD",
                    transaction_reason=tx.transaction_reason,
                    original_transaction_id=tx.original_transaction_id,
                    environment=tx.environment,
                    transaction_id=getattr(tx, "transaction_id", None) or tx.original_transaction_id,
                )
            )

    logger.info("Built %d transaction records within reporting window.", len(records))
    return records


NEGATIVE_REASONS = {"REFUND", "DOWNGRADE", "REVERSAL", "CHARGEBACK"}


def compute_influencer_payouts(
    transactions: Iterable[TransactionRecord],
    referral_codes: Dict[str, ReferralCodeSnapshot],
    affiliate_share: Decimal,
) -> Dict[str, InfluencerPayout]:
    payouts: Dict[str, InfluencerPayout] = {}
    for record in transactions:
        if not record.referral_code:
            continue

        referral_info = referral_codes.get(record.referral_code)
        processed_ids = referral_info.processed_transaction_ids if referral_info else set()
        if record.transaction_id and record.transaction_id in processed_ids:
            logger.debug(
                "Skipping transaction %s for referral %s because it has already been processed.",
                record.transaction_id,
                record.referral_code,
            )
            continue

        current = payouts.get(record.referral_code)
        revenue = record.price
        reason = (record.transaction_reason or "").upper()
        if revenue > 0 and reason in NEGATIVE_REASONS:
            revenue = -revenue

        payout_amount = (revenue * affiliate_share).quantize(Decimal("0.01"))

        if current is None:
            payouts[record.referral_code] = InfluencerPayout(
                referral_code=record.referral_code,
                influencer_name=referral_info.influencer_name if referral_info else None,
                influencer_email=referral_info.influencer_email if referral_info else None,
                payout_account_id=referral_info.payout_account_id if referral_info else None,
                payout_provider=referral_info.payout_provider if referral_info else None,
                payout_frequency=referral_info.payout_frequency if referral_info else None,
                total_revenue=revenue,
                total_payout=payout_amount,
                transaction_count=1,
                transaction_ids=[record.transaction_id] if record.transaction_id else [],
                existing_total_paid=referral_info.total_paid if referral_info else Decimal("0.00"),
                currency=referral_info.payout_currency or record.currency,
            )
        else:
            current.total_revenue += revenue
            current.total_payout += payout_amount
            current.transaction_count += 1
            if record.transaction_id:
                current.transaction_ids.append(record.transaction_id)

    return payouts


