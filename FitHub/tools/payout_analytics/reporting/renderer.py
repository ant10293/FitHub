from __future__ import annotations

import csv
from datetime import datetime
from decimal import Decimal
from pathlib import Path
from typing import Dict, Iterable, List

from zoneinfo import ZoneInfo

from tools.payout_analytics.analytics.metrics import SubscriptionMetrics
from tools.payout_analytics.analytics.payouts import InfluencerPayout, TransactionRecord


def _format_currency(amount: Decimal, currency: str) -> str:
    return f"{currency} {amount.quantize(Decimal('0.01')):,.2f}"


def render_csv(
    output_path: Path,
    run_id: str,
    start: datetime,
    end: datetime,
    display_timezone: ZoneInfo,
    user_metrics: Dict,
    subscription_metrics: SubscriptionMetrics,
    influencer_payouts: Dict[str, InfluencerPayout],
    transactions: Iterable[TransactionRecord],
    total_revenue: Decimal,
    total_affiliate_payout: Decimal,
    currency: str,
) -> Path:
    fmt = "%Y-%m-%d %I:%M %p %Z"
    window_start = start.astimezone(display_timezone).strftime(fmt)
    window_end = end.astimezone(display_timezone).strftime(fmt)
    generated_at = datetime.now(tz=display_timezone).strftime(fmt)

    if influencer_payouts and all(p.stripe_dry_run for p in influencer_payouts.values()):
        payout_mode = "Dry-Run (no Stripe transfers executed)"
    elif influencer_payouts:
        payout_mode = "Live (Stripe transfers executed where possible)"
    else:
        payout_mode = "No referral payouts calculated"

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)

        # Summary
        writer.writerow(["Section", "Field", "Value"])
        writer.writerow(["Report", "Run ID", run_id])
        writer.writerow(["Report", "Reporting window", f"{window_start} → {window_end}"])
        writer.writerow(["Report", "Generated at", generated_at])
        writer.writerow(["Report", "Stripe mode", payout_mode])
        writer.writerow(["Report", "Total Revenue", _format_currency(total_revenue, currency)])
        writer.writerow(
            ["Report", "Total Affiliate Share", _format_currency(total_affiliate_payout, currency)]
        )
        writer.writerow(["Report", "Influencers with activity", len(influencer_payouts)])
        writer.writerow([])

        # User metrics
        writer.writerow(["User Metrics"])
        writer.writerow(["Metric", "Value"])
        writer.writerow(["Total users", user_metrics["total_users"]])
        writer.writerow(["New users in window", user_metrics["new_users"]])
        writer.writerow(["Total referred users", user_metrics["total_referred_users"]])
        writer.writerow(["New referred users", user_metrics["new_referred_users"]])
        writer.writerow(
            ["Share of new users referred", f"{user_metrics['new_referred_ratio']*100:.1f}%"]
        )
        writer.writerow(
            ["Share of total users referred", f"{user_metrics['total_referred_ratio']*100:.1f}%"]
        )
        writer.writerow([])

        # Subscription metrics
        writer.writerow(["Subscription Metrics"])
        writer.writerow(["Metric", "Count"])
        writer.writerow(["New Monthly Subscribers", subscription_metrics.new_monthly_subscribers])
        writer.writerow(["Total Monthly Subscribers", subscription_metrics.total_monthly_subscribers])
        writer.writerow(["New Yearly Subscribers", subscription_metrics.new_yearly_subscribers])
        writer.writerow(["Total Yearly Subscribers", subscription_metrics.total_yearly_subscribers])
        writer.writerow(["New Lifetime Purchasers", subscription_metrics.new_lifetime_purchasers])
        writer.writerow(
            ["Total Lifetime Purchasers", subscription_metrics.total_lifetime_purchasers]
        )
        writer.writerow([])

        # Influencer payouts
        writer.writerow(["Influencer Payouts"])
        writer.writerow(
            [
                "Referral Code",
                "Influencer",
                "Transactions",
                "Revenue",
                "Payout",
                "Transfer",
                "Notes",
            ]
        )
        if influencer_payouts:
            for code, payout in influencer_payouts.items():
                transfer_label = payout.stripe_transfer_id or (
                    "dry-run" if payout.stripe_dry_run else ""
                )
                note_parts: List[str] = []
                if payout.payout_frequency:
                    note_parts.append(f"Freq: {payout.payout_frequency}")
                note_parts.extend(payout.notes)
                note_text = "; ".join(note_parts)
                writer.writerow(
                    [
                        code,
                        payout.influencer_name or "",
                        payout.transaction_count,
                        _format_currency(payout.total_revenue, currency),
                        _format_currency(payout.total_payout, currency),
                        transfer_label,
                        note_text,
                    ]
                )
        else:
            writer.writerow(["", "", "", "", "", "", "No referral-driven transactions in period"])
        writer.writerow([])

        # Transaction detail
        writer.writerow(["Transaction Detail"])
        writer.writerow(
            [
                "Local Date",
                "User",
                "Referral",
                "Product",
                "Amount",
                "Reason",
                "Environment",
                "Transaction ID",
            ]
        )
        for tx in sorted(transactions, key=lambda t: t.purchase_date):
            local_date = tx.purchase_date.astimezone(display_timezone).strftime(fmt)
            writer.writerow(
                [
                    local_date,
                    tx.user_id,
                    tx.referral_code or "",
                    tx.product_id,
                    f"{tx.price:,.2f} {tx.currency}",
                    tx.transaction_reason or "",
                    tx.environment,
                    tx.transaction_id or "",
                ]
            )

    return output_path


