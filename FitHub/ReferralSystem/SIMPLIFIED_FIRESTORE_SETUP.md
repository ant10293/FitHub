# Simplified Firestore Document Setup

## Streamlined Field List (No Redundant Counts)

Since we can count arrays when needed, we only need the arrays themselves.

### Document ID
- Enter: `ANTHONY` (or your test code, uppercase)

### Required Fields:

#### Basic Information:
1. `code` (string) - `ANTHONY`
2. `influencerName` (string) - `Anthony Cantu`
3. `influencerEmail` (string) - `anthony@example.com` (or empty)
4. `notes` (string) - `Test influencer` (or empty)
5. `isActive` (boolean) - `true`
6. `createdAt` (timestamp) - Current time
7. `createdBy` (string) - `self_service`

#### Sign-up Tracking:
8. `usedBy` (array) - `[]` - User IDs who signed up
9. `lastUsedAt` (timestamp) - (empty, optional)

#### Purchase Tracking (for compensation):
10. `monthlyPurchasedBy` (array) - `[]` - Users who purchased monthly ⭐
11. `annualPurchasedBy` (array) - `[]` - Users who purchased annual ⭐
12. `lifetimePurchasedBy` (array) - `[]` - Users who purchased lifetime ⭐
13. `lastPurchaseAt` (timestamp) - (empty, optional)

## That's It! Just 13 Fields

## How to Get Counts (When Needed)

```swift
let codeDoc = try await db.collection("referralCodes").document("ANTHONY").getDocument()
let data = codeDoc.data()

// Count sign-ups
let signUpCount = (data["usedBy"] as? [String] ?? []).count

// Count purchases by type
let monthlyCount = (data["monthlyPurchasedBy"] as? [String] ?? []).count
let annualCount = (data["annualPurchasedBy"] as? [String] ?? []).count
let lifetimeCount = (data["lifetimePurchasedBy"] as? [String] ?? []).count

// Get all purchasers (combine arrays if needed)
let monthlyPurchasers = data["monthlyPurchasedBy"] as? [String] ?? []
let annualPurchasers = data["annualPurchasedBy"] as? [String] ?? []
let lifetimePurchasers = data["lifetimePurchasedBy"] as? [String] ?? []
let allPurchasers = Set(monthlyPurchasers + annualPurchasers + lifetimePurchasers)
let totalPurchases = allPurchasers.count

// Calculate compensation
let monthlyCommission = 5.0
let annualCommission = 50.0
let lifetimeCommission = 200.0

let compensation = 
    (Double(monthlyCount) * monthlyCommission) +
    (Double(annualCount) * annualCommission) +
    (Double(lifetimeCount) * lifetimeCommission)
```

## Important Note

**Note:** If the same user can purchase multiple subscriptions (e.g., renewals), the arrays will only contain unique user IDs. If you need to track multiple purchases by the same user, you should query the `referralPurchases` collection instead, which has one record per purchase transaction.

For most compensation models, counting unique users per type is sufficient, but if you need per-transaction counts, use the `referralPurchases` collection.

