# Referral System Testing Guide

This guide will help you test the complete referral flow from link click to purchase tracking.

## Complete Flow Overview

1. **User clicks referral link** → Code stored in UserDefaults
2. **User signs in** → Code claimed in Firestore (`users/{userId}`)
3. **User purchases subscription** → Purchase tracked in Firestore (`referralCodes/{code}`)

## Testing Steps

### Step 1: Create a Test Referral Code

1. Open Firebase Console → Firestore Database
2. Create a test referral code document:
   - Collection: `referralCodes`
   - Document ID: `TESTCODE` (or any code)
   - Fields:
     ```json
     {
       "code": "TESTCODE",
       "influencerName": "Test Influencer",
       "influencerEmail": "test@example.com",
       "isActive": true,
       "createdAt": [timestamp],
       "usedBy": [],
       "monthlyPurchasedBy": [],
       "annualPurchasedBy": [],
       "lifetimePurchasedBy": []
     }
     ```

### Step 2: Test Universal Link (Fresh Install)

**Option A: Test on a device without the app installed**
1. Open Safari on your iPhone
2. Navigate to: `https://fithubv1-d3c91.web.app/r/TESTCODE`
3. You should see the landing page
4. The referral code should be stored in localStorage (visible in browser console)

**Option B: Test with app installed (Recommended)**
1. Build and install your app on a device via Xcode
2. Delete the app (to simulate fresh install)
3. Open Safari on the device
4. Navigate to: `https://fithubv1-d3c91.web.app/r/TESTCODE`
5. The app should open automatically (if universal links are working)
6. Check Xcode console for: `✅ Successfully handled referral URL`

### Step 3: Verify Code is Stored

1. Open Xcode console
2. Look for logs from `ReferralURLHandler`:
   - Should see code being extracted and stored
3. Or add temporary debug code to check UserDefaults:
   ```swift
   print("Pending code: \(UserDefaults.standard.string(forKey: "pendingReferralCode") ?? "none")")
   ```

### Step 4: Test Sign-In and Code Claiming

1. In your app, tap "Sign in with Apple"
2. Complete sign-in
3. Check Xcode console for:
   - `✅ Successfully claimed referral code: TESTCODE`
4. Verify in Firestore:
   - Go to `users/{userId}` document
   - Should have:
     - `referralCode: "TESTCODE"`
     - `referralCodeClaimedAt: [timestamp]`
     - `referralSource: "sign_in"`
   - Go to `referralCodes/TESTCODE`
   - `usedBy` array should contain your user ID
   - `lastUsedAt` should be set

### Step 5: Test Purchase Tracking

1. In your app, navigate to subscription page
2. Select a subscription (monthly, yearly, or lifetime)
3. Complete the purchase (use StoreKit Testing if not in production)
4. Check Xcode console for:
   - `✅ Successfully tracked monthly purchase for referral code: TESTCODE`
   - Or `annual` or `lifetime` depending on what you purchased
5. Verify in Firestore:
   - Go to `referralCodes/TESTCODE`
   - Check the appropriate array:
     - `monthlyPurchasedBy` for monthly
     - `annualPurchasedBy` for yearly
     - `lifetimePurchasedBy` for lifetime
   - Should contain your user ID
   - `lastPurchaseAt` should be set
   - Go to `referralPurchases` collection
   - Should have a document with ID: `{userId}_{transactionID}`
   - Contains purchase details

### Step 6: Verify Compensation Tracking

In Firestore, check `referralCodes/TESTCODE`:
- `monthlyPurchasedBy.count` = number of monthly purchases
- `annualPurchasedBy.count` = number of annual purchases
- `lifetimePurchasedBy.count` = number of lifetime purchases

These counts are what you'll use for compensation!

## Debug Console Logs to Watch For

### Successful Flow:
```
✅ Successfully handled referral URL
✅ Successfully claimed referral code: TESTCODE
✅ Successfully tracked monthly purchase for referral code: TESTCODE
```

### Error Cases:
```
⚠️ Invalid referral code format: [code]
⚠️ Referral code not found: [code]
⚠️ Referral code is inactive: [code]
ℹ️ User already has referral code: [code]
ℹ️ User has no referral code, skipping purchase tracking
```

## Testing with StoreKit Testing

If your app isn't in production yet, use StoreKit Testing:

1. In Xcode: Product → Scheme → Edit Scheme
2. Run → Options → StoreKit Configuration
3. Select a StoreKit configuration file (create one if needed)
4. This allows testing purchases without real transactions

## Quick Verification Checklist

- [ ] Universal link opens app (or shows landing page)
- [ ] Code stored in UserDefaults after link click
- [ ] Code claimed in Firestore after sign-in
- [ ] User document has `referralCode` field
- [ ] Referral code document has user in `usedBy` array
- [ ] Purchase tracked after subscription purchase
- [ ] User ID in appropriate `*PurchasedBy` array
- [ ] Purchase record created in `referralPurchases` collection

## Troubleshooting

### Universal Link Not Opening App
- Check entitlements file has correct domain
- Rebuild app after changing entitlements
- Delete and reinstall app (iOS caches association files)
- Wait a few minutes for iOS to validate

### Code Not Being Claimed
- Check user is signed in
- Check code exists in Firestore
- Check code is active (`isActive: true`)
- Check Xcode console for error messages

### Purchase Not Being Tracked
- Check user is signed in
- Check user has `referralCode` in Firestore
- Check Xcode console for error messages
- Verify `ReferralPurchaseTracker` is being called (already in `PremiumStore.buy()`)

## Testing Multiple Scenarios

1. **Same user, multiple purchases**: Should only track once per transaction ID (idempotent)
2. **Multiple users, same code**: Each should be tracked separately
3. **User without referral code**: Should skip tracking (no error)
4. **Invalid code**: Should handle gracefully

