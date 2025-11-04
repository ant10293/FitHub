# Updated Firestore Schema for Subscription Tracking

Since influencers are only compensated when users **purchase subscriptions** (not just sign up), we need to track purchases separately.

## Updated `referralCodes` Collection Structure

Each document should now include these fields:

### Required Fields:
- `code` (string) - The referral code (e.g., "ANTHONY")
- `influencerName` (string) - Name of the influencer
- `influencerEmail` (string) - Email of the influencer
- `notes` (string) - Optional notes
- `isActive` (boolean) - Whether the code is active
- `createdAt` (timestamp) - When the code was created
- `createdBy` (string) - User ID who created it (or "self_service")

### Sign-up Tracking (for analytics):
- `usageCount` (number) - Total sign-ups using this code
- `usedBy` (array of strings) - User IDs who signed up with this code
- `lastUsedAt` (timestamp) - Last time someone signed up

### Purchase Tracking by Type (for compensation) ⭐:
- `purchaseCountMonthly` (number) - Monthly subscriptions purchased
- `monthlyPurchasedBy` (array) - User IDs who purchased monthly
- `purchaseCountAnnual` (number) - Annual subscriptions purchased
- `annualPurchasedBy` (array) - User IDs who purchased annual
- `purchaseCountLifetime` (number) - Lifetime passes purchased
- `lifetimePurchasedBy` (array) - User IDs who purchased lifetime

### Total Purchase Tracking (for convenience):
- `purchaseCount` (number) - Total purchases (sum of all types)
- `purchasedBy` (array) - All user IDs who purchased (any type)
- `lastPurchaseAt` (timestamp) - Last purchase time

## New Collection: `referralPurchases`

This collection tracks individual subscription purchases tied to referral codes.

**Document ID:** `{userId}_{transactionID}`

**Fields:**
- `code` (string) - The referral code used
- `userId` (string) - User who purchased
- `productID` (string) - Which subscription (monthly, yearly, lifetime)
- `transactionID` (string) - StoreKit transaction ID
- `purchasedAt` (timestamp) - When purchase occurred
- `influencerName` (string) - For easy querying

## Updated `users` Collection Fields

When a user purchases a subscription with a referral code, add:

- `referralCodeUsedForPurchase` (boolean) - True if they purchased
- `referralPurchaseDate` (timestamp) - When they purchased
- `referralPurchaseProductID` (string) - Which subscription they bought

## Example Document Structure

### `referralCodes/ANTHONY`:
```json
{
  "code": "ANTHONY",
  "influencerName": "Anthony Cantu",
  "influencerEmail": "anthony@example.com",
  "notes": "Main influencer",
  "isActive": true,
  "createdAt": "2025-01-15T10:00:00Z",
  "createdBy": "self_service",
  "usageCount": 25,        // 25 people signed up
  "usedBy": ["user1", "user2", ...],
  "lastUsedAt": "2025-01-20T15:30:00Z",
  "purchaseCountMonthly": 3,    // 3 monthly subscriptions ⭐
  "monthlyPurchasedBy": ["user1", "user2", "user3"],
  "purchaseCountAnnual": 4,      // 4 annual subscriptions ⭐
  "annualPurchasedBy": ["user4", "user5", "user6", "user7"],
  "purchaseCountLifetime": 1,    // 1 lifetime purchase ⭐
  "lifetimePurchasedBy": ["user8"],
  "purchaseCount": 8,            // Total: 3+4+1 = 8
  "purchasedBy": ["user1", "user2", "user3", "user4", "user5", "user6", "user7", "user8"],
  "lastPurchaseAt": "2025-01-20T16:00:00Z"
}
```

### `referralPurchases/user1_123456789`:
```json
{
  "code": "ANTHONY",
  "userId": "user1",
  "productID": "com.FitHub.premium.yearly",
  "transactionID": "123456789",
  "purchasedAt": "2025-01-20T16:00:00Z",
  "influencerName": "Anthony Cantu"
}
```

## Compensation Calculation

To calculate compensation:
- **Total sign-ups:** `usageCount` (for analytics)
- **Monthly purchases:** `purchaseCountMonthly` ⭐
- **Annual purchases:** `purchaseCountAnnual` ⭐
- **Lifetime purchases:** `purchaseCountLifetime` ⭐
- **Total purchases:** `purchaseCount` (sum of all types)
- **Conversion rate:** `purchaseCount / usageCount * 100`

Example compensation calculation:
```swift
let monthlyCommission = 5.0   // $5 per monthly
let annualCommission = 50.0   // $50 per annual
let lifetimeCommission = 200.0 // $200 per lifetime

let compensation = 
    (monthlyCount * monthlyCommission) +
    (annualCount * annualCommission) +
    (lifetimeCount * lifetimeCommission)
```

## Updated Firestore Document Creation

When creating your first test document in Firebase Console, add these additional fields:

| Field Name | Type | Value |
|------------|------|-------|
| `purchaseCount` | number | `0` |
| `purchasedBy` | array | `[]` (empty) |
| `lastPurchaseAt` | timestamp | (leave empty, will be set on first purchase) |

All other fields remain the same as before.

