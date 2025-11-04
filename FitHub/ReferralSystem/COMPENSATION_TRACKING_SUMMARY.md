# Compensation Tracking Summary

## What Changed

Since influencers are only compensated when users **purchase subscriptions** (not just sign up), the system now tracks:

1. **Sign-ups** (for analytics) - `usageCount` in `referralCodes`
2. **Purchases** (for compensation) ⭐ - `purchaseCount` in `referralCodes`

## Updated Document Fields

When creating your `referralCodes` document, you now need to add **3 additional fields**:

### New Fields (for compensation):
- `purchaseCount` (number) - Starts at `0`
- `purchasedBy` (array) - Starts as empty array `[]`
- `lastPurchaseAt` (timestamp) - Leave empty initially

### Existing Fields (for analytics):
- `usageCount` (number) - Total sign-ups
- `usedBy` (array) - User IDs who signed up
- `lastUsedAt` (timestamp) - Last sign-up time

## How It Works

1. **User signs up with referral code:**
   - `usageCount` increments
   - `usedBy` array adds the user ID
   - (This is for analytics only)

2. **User purchases subscription:**
   - `purchaseCount` increments ⭐
   - `purchasedBy` array adds the user ID ⭐
   - A record is created in `referralPurchases` collection
   - (This is what counts for compensation)

## Files Created/Updated

### New Files:
1. **`ReferralPurchaseTracker.swift`** - Tracks subscription purchases
2. **`UPDATED_FIRESTORE_SCHEMA.md`** - Complete schema documentation
3. **`FIRESTORE_DOCUMENT_SETUP.md`** - Step-by-step document creation guide

### Updated Files:
1. **`PremiumStore.swift`** - Now calls `ReferralPurchaseTracker` after successful purchase

## What You Need to Do

### 1. Update Your Firestore Document
Add these 3 fields to your `referralCodes/ANTHONY` document:
- `purchaseCount`: `0`
- `purchasedBy`: `[]`
- `lastPurchaseAt`: (leave empty)

See `FIRESTORE_DOCUMENT_SETUP.md` for complete instructions.

### 2. Add ReferralPurchaseTracker to Your Project
- Add `ReferralSystem/ReferralPurchaseTracker.swift` to Xcode
- It's already integrated into `PremiumStore.swift`

### 3. Test It
1. Sign up a test user with a referral code
2. Verify `usageCount` increments in Firestore
3. Have that user purchase a subscription
4. Verify `purchaseCount` increments in Firestore
5. Check `referralPurchases` collection for the purchase record

## Compensation Calculation

When you're ready to pay influencers:

```swift
// Get referral code stats
let codeDoc = try await db.collection("referralCodes").document("ANTHONY").getDocument()
let data = codeDoc.data()

let signUps = data["usageCount"] as? Int ?? 0        // Total sign-ups
let purchases = data["purchaseCount"] as? Int ?? 0   // ⭐ Compensated purchases
let conversionRate = signUps > 0 ? (purchases / signUps * 100) : 0

// Compensation = purchases * commission_per_purchase
```

## Important Notes

- **Sign-ups ≠ Compensation:** Only `purchaseCount` matters for payment
- **Idempotent:** Purchases are tracked once per transaction (won't double-count)
- **Automatic:** Tracking happens automatically when users purchase via `PremiumStore`
- **Queryable:** You can query `referralPurchases` collection for detailed purchase history

