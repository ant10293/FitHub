# FitHub Affiliate Payout Analytics

Generates a weekly revenue and payout report (CSV format) by combining Firestore referral data with
App Store Server transactions, then (optionally) triggers Stripe Connect transfers to pay affiliates.
Designed to run locally on a Mac but can be scheduled via cron.

## Features

- Pulls user and referral metadata from Firestore using the Firebase Admin SDK
- Fetches full transaction history for each subscriber via the App Store Server API
- Accounts for upgrades/downgrades by using the net price Apple reports for each transaction
- Computes user growth, subscription mix, and affiliate revenue shares (40%)
- Calls the App Store Server API to honour upgrades/downgrades/refunds via net transaction amounts
- Produces a CSV report plus detailed logs for auditability
- (Optional) Sends Stripe transfers to connected accounts and records the ledger in Firestore

## Setup

1. Ensure you have Python 3.11+ installed.
2. Create/activate a virtual environment (recommended).
3. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

4. Create a `.env` file (or edit the existing example) with environment variables:

   ```
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
   APPSTORE_ISSUER_ID=b308138d-b626-40d1-83ef-9e68c5ea09f4
   APPSTORE_KEY_ID=W5S2D6YA8L
   APPSTORE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   APPSTORE_BUNDLE_ID=com.AnthonyC.FitHub
   APPSTORE_APP_APPLE_ID=6749919587
   FITHUB_REPORT_OUTPUT_DIR=~/Desktop/FitHubPayoutReports
   FITHUB_REPORT_CURRENCY=USD
   FITHUB_AFFILIATE_SHARE=0.40
   FITHUB_TIMEZONE=America/Chicago        # optional; defaults to your system timezone
   STRIPE_SECRET_KEY=sk_live_...
   STRIPE_PAYOUT_CURRENCY=USD
   STRIPE_TRANSFER_DESCRIPTION="FitHub affiliate payout"
   FITHUB_STRIPE_DRY_RUN=true
   ```

   > Wrap the private key in double quotes and paste with real line breaks.

5. Run the script (it automatically loads `.env`):

   ```bash
   python -m tools.payout_analytics.main
   ```

   CLI options:
   - `--start` / `--end` – ISO timestamps for the reporting window. Defaults to the last 7 days.
   - `--output` – Override report directory for this run.
   - `--manual` – Flag run as manual (affects log naming only).
   - `--execute-payouts` – Override config and perform live Stripe transfers (and ledger updates).

   To avoid activating the virtual environment manually each time, you can use the helper script:

   ```bash
   tools/run_payout_analytics.sh --start 2025-01-01T00:00:00Z --end 2025-01-08T00:00:00Z
   ```
   (It assumes the venv lives at `tools/venv`.)

Reports are written under `~/Desktop/FitHubPayoutReports/reports/` (configurable) as `.csv` files. Logs
live in the adjacent `logs/` folder. Stripe transfers run in dry-run mode unless you set
`FITHUB_STRIPE_DRY_RUN=false` or pass `--execute-payouts`.

## Notes

- The script currently assumes USD pricing for:
  - Monthly: $3.99
  - Annual: $29.99
  - Lifetime: $89.99
- If Apple omits `price`/`currency` in the transaction payload, these static prices
  are used as a fallback (with a warning in the logs).
- Only transactions attributed to a referral (`referralCodeUsedForPurchase == true`) count
  toward influencer payouts.
- The Firestore `referralCodes/{code}` document keeps a `payout` ledger (processed transactions,
  total paid, per-run history) so re-running the script is idempotent.
- Stripe transfers are skipped when no payout account exists or when the computed payout is
  negative/zero. Outstanding amounts remain in the next run.
