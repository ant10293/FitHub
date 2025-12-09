# Setting Up Products in App Store Connect for TestFlight/Production

## Overview

TestFlight builds automatically use products from App Store Connect (not StoreKit config files). You need to create your subscription products in App Store Connect.

## Your Product IDs (from your code):

- `com.FitHub.premium.monthly` - Monthly subscription
- `com.FitHub.premium.yearly` - Annual subscription
- `com.FitHub.premium.lifetime` - One-time purchase

## Step 1: Create In-App Purchases in App Store Connect

1. Go to **App Store Connect** → **My Apps** → Select your app
2. Click on **Features** tab (at the top)
3. Click **In-App Purchases** in the left sidebar
4. Click **+** to create a new in-app purchase

## Step 2: Create Monthly Subscription

1. Select **Auto-Renewable Subscription**
2. Click **Create**
3. Fill in:
   - **Reference Name**: FitHub Premium Monthly
   - **Product ID**: `com.FitHub.premium.monthly` (must match exactly)
   - **Subscription Group**: Create a new group (e.g., "FitHub Premium")
   - **Subscription Duration**: 1 Month
   - **Price**: Set your price (e.g., $4.99/month)
   - **Display Name**: Monthly Premium
   - **Description**: Describe what users get with monthly premium
4. Click **Save**
5. Click **Create** to create the subscription

## Step 3: Create Annual Subscription

1. Click **+** again
2. Select **Auto-Renewable Subscription**
3. Click **Create**
4. Fill in:
   - **Reference Name**: FitHub Premium Annual
   - **Product ID**: `com.FitHub.premium.yearly` (must match exactly)
   - **Subscription Group**: Same group as monthly ("FitHub Premium")
   - **Subscription Duration**: 1 Year
   - **Price**: Set your price (e.g., $49.99/year)
   - **Display Name**: Annual Premium
   - **Description**: Describe what users get with annual premium
5. Click **Save**
6. Click **Create**

**Important**: Both monthly and yearly must be in the **same subscription group** so users can switch between them.

## Step 4: Create Lifetime Purchase

1. Click **+** again
2. Select **Non-Consumable** (one-time purchase)
3. Click **Create**
4. Fill in:
   - **Reference Name**: FitHub Premium Lifetime
   - **Product ID**: `com.FitHub.premium.lifetime` (must match exactly)
   - **Price**: Set your price (e.g., $199.99)
   - **Display Name**: Lifetime Premium
   - **Description**: Describe what users get with lifetime premium
5. Click **Save**
6. Click **Create**

## Step 5: Submit for Review (if needed)

- For **sandbox testing only**: You can test immediately without submitting
- For **production**: You'll need to submit the in-app purchases for review along with your app

## Step 6: Test in TestFlight

1. Install your app from TestFlight
2. Products should load automatically from App Store Connect
3. Make a purchase with your sandbox test account
4. Verify:
   - Products show correct prices
   - Purchases work
   - Environment shows as "Sandbox" in Firestore
   - Webhooks are received

## Important Notes

### Product IDs Must Match Exactly
- Your code uses: `com.FitHub.premium.monthly`
- App Store Connect must use: `com.FitHub.premium.monthly`
- **Case-sensitive** and must match exactly!

### Subscription Groups
- Monthly and yearly subscriptions must be in the **same group**
- This allows users to upgrade/downgrade between them
- Lifetime is a separate non-consumable (not in a group)

### Bundle ID
- Your app's bundle ID must match: `com.AnthonyC.FitHub` (from your GoogleService-Info.plist)
- Products are associated with your app's bundle ID

### TestFlight vs Production
- **TestFlight**: Uses sandbox environment automatically
- **Production**: Uses production environment (after App Store release)
- Your code already handles both via `transaction.environment.rawValue`

## Troubleshooting

### Products not loading in TestFlight
- Verify product IDs match exactly (case-sensitive)
- Check that products are in "Ready to Submit" or "Approved" status
- Make sure your app's bundle ID matches
- Wait a few minutes after creating products (they need to propagate)

### "Product not available" errors
- Verify product IDs are correct
- Check subscription group is set up correctly
- Ensure products are associated with your app
- For sandbox testing, products should work immediately

### Wrong prices showing
- Update prices in App Store Connect
- Wait a few minutes for changes to propagate
- Prices are cached, so may take a moment to update

## Summary

✅ **No StoreKit config file needed** for TestFlight/Production
✅ Products load automatically from App Store Connect
✅ Create products with exact product IDs from your code
✅ Test with sandbox accounts in TestFlight
✅ Your code already handles sandbox vs production correctly
