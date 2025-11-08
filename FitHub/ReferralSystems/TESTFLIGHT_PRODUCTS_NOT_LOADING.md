# Troubleshooting: Products Not Loading in TestFlight

## The Issue

Products are being requested from Apple's API (visible in logs), but some/all may not be returned.

## Common Causes

### 1. Lifetime Product Still Missing Required Fields

Even though it shows "Ready to Submit", the lifetime non-consumable might need:
- **Pricing** set for all regions (or at least your region)
- **Screenshot** (sometimes required even for sandbox)
- **Review Information** filled out
- **App Store Review Screenshot** (if required)

### 2. Products Not Fully Propagated

Apple's systems can take time to propagate new products. Try:
- Wait 15-30 minutes after creating/updating products
- Force quit and restart the TestFlight app
- Reinstall the app from TestFlight

### 3. Check Product Status

In App Store Connect → Features → In-App Purchases:
- Click on "Lifetime Pass"
- Check if there are any yellow warnings or missing required fields
- Make sure pricing is set

### 4. Verify in Console

Check your app's console output when opening the subscription screen:
- Look for `errorMessage` from `PremiumStore`
- Check if `products` array is empty or has fewer than 3 items
- Look for any StoreKit errors

## Quick Test

1. Open your app from TestFlight
2. Navigate to subscription screen
3. Check Xcode console for:
   - `Failed to load products: [error message]`
   - Or count how many products loaded: `products.count`

This will tell us if it's:
- All products failing to load (API issue)
- Only lifetime failing (product setup issue)
- Products loading but not displaying (UI issue)

