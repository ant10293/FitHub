from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, Iterable, List, Optional, Set

from decimal import Decimal

from tools.payout_analytics.data.appstore_client import DecodedTransaction


logger = logging.getLogger(__name__)


PRODUCT_MONTHLY = "com.FitHub.premium.monthly"
PRODUCT_YEARLY = "com.FitHub.premium.yearly"
PRODUCT_LIFETIME = "com.FitHub.premium.lifetime"


@dataclass
class UserSnapshot:
    uid: str
    email: Optional[str]
    creation_time: datetime
    referral_code: Optional[str]
    referral_code_claimed_at: Optional[datetime]
    referral_purchase_product_id: Optional[str]
    referral_purchase_date: Optional[datetime]
    subscription_status: Dict
    is_referral_purchase: bool


def compute_user_metrics(
    users: Iterable[UserSnapshot],
    start: datetime,
    end: datetime,
) -> Dict:
    users_list = list(users)
    total_users = len(users_list)

    new_users = [u for u in users_list if start <= u.creation_time <= end]
    referred_users = [u for u in users_list if u.referral_code]
    new_referred_users = [u for u in new_users if u.referral_code]

    logger.info("User metrics: total=%d, new=%d", total_users, len(new_users))

    return {
        "total_users": total_users,
        "new_users": len(new_users),
        "total_referred_users": len(referred_users),
        "new_referred_users": len(new_referred_users),
        "new_referred_ratio": (len(new_referred_users) / len(new_users)) if new_users else 0.0,
        "total_referred_ratio": (len(referred_users) / total_users) if total_users else 0.0,
        "new_users_detail": new_users,
    }


@dataclass
class SubscriptionMetrics:
    new_monthly_subscribers: int
    total_monthly_subscribers: int
    new_yearly_subscribers: int
    total_yearly_subscribers: int
    new_lifetime_purchasers: int
    total_lifetime_purchasers: int
    referred_proportions: Dict[str, float]


def compute_subscription_metrics(
    users: Iterable[UserSnapshot],
    transactions: Dict[str, List[DecodedTransaction]],
    start: datetime,
    end: datetime,
) -> SubscriptionMetrics:
    """
    Determine new vs total subscribers for each product type within the reporting window.
    """
    user_map = {u.uid: u for u in users}

    new_counts = {
        PRODUCT_MONTHLY: set(),
        PRODUCT_YEARLY: set(),
        PRODUCT_LIFETIME: set(),
    }
    first_purchase_dates: Dict[str, Dict[str, datetime]] = {
        PRODUCT_MONTHLY: {},
        PRODUCT_YEARLY: {},
        PRODUCT_LIFETIME: {},
    }
    active_now: Dict[str, Set[str]] = {
        PRODUCT_MONTHLY: set(),
        PRODUCT_YEARLY: set(),
        PRODUCT_LIFETIME: set(),
    }

    for uid, tx_list in transactions.items():
        # Sort by purchase date ascending for deterministic results
        tx_list_sorted = sorted(
            [tx for tx in tx_list if tx.purchase_date is not None],
            key=lambda t: t.purchase_date,
        )

        latest_by_product: Dict[str, DecodedTransaction] = {}

        for tx in tx_list_sorted:
            product = tx.product_id
            if product not in first_purchase_dates:
                continue

            if tx.purchase_date is None:
                continue

            # First purchase date per product
            if uid not in first_purchase_dates[product]:
                first_purchase_dates[product][uid] = tx.purchase_date

            # Track latest transaction per product
            latest = latest_by_product.get(product)
            if latest is None or (tx.purchase_date and tx.purchase_date > latest.purchase_date):
                latest_by_product[product] = tx

            # If first purchase falls inside the window, mark as new subscriber
            if start <= tx.purchase_date <= end and first_purchase_dates[product][uid] == tx.purchase_date:
                new_counts[product].add(uid)

        # Determine active product as of end date
        for product, tx in latest_by_product.items():
            if product == PRODUCT_LIFETIME:
                active_now[product].add(uid)
                continue

            if tx.expires_date and tx.expires_date >= end:
                active_now[product].add(uid)

    # Calculate referred proportions
    referred_proportions: Dict[str, float] = {}
    for product in (PRODUCT_MONTHLY, PRODUCT_YEARLY, PRODUCT_LIFETIME):
        new_referred = sum(
            1 for uid in new_counts[product] if user_map.get(uid) and user_map[uid].referral_code
        )
        total_referred = sum(
            1 for uid in active_now[product] if user_map.get(uid) and user_map[uid].referral_code
        )

        referred_proportions[f"new_{product}_ratio"] = (
            new_referred / len(new_counts[product]) if new_counts[product] else 0.0
        )
        referred_proportions[f"total_{product}_ratio"] = (
            total_referred / len(active_now[product]) if active_now[product] else 0.0
        )

    return SubscriptionMetrics(
        new_monthly_subscribers=len(new_counts[PRODUCT_MONTHLY]),
        total_monthly_subscribers=len(active_now[PRODUCT_MONTHLY]),
        new_yearly_subscribers=len(new_counts[PRODUCT_YEARLY]),
        total_yearly_subscribers=len(active_now[PRODUCT_YEARLY]),
        new_lifetime_purchasers=len(new_counts[PRODUCT_LIFETIME]),
        total_lifetime_purchasers=len(active_now[PRODUCT_LIFETIME]),
        referred_proportions=referred_proportions,
    )


