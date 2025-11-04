# Firestore Document Setup - With Separate Subscription Type Tracking

## Creating Your First `referralCodes` Document

Since compensation is different for monthly, annual, and lifetime subscriptions, we track each separately.

### Document ID
- Enter: `ANTHONY` (or your test code, uppercase)

### Required Fields (Add one by one):

#### Basic Information:
1. `code` (string) - `ANTHONY`
2. `influencerName` (string) - `Anthony Cantu`
3. `influencerEmail` (string) - `anthony@example.com` (or empty)
4. `notes` (string) - `Test influencer` (or empty)
5. `isActive` (boolean) - `true`
6. `createdAt` (timestamp) - Current time
7. `createdBy` (string) - `self_service`

#### Sign-up Tracking (for analytics):
8. `usageCount` (number) - `0`
9. `usedBy` (array) - `[]`
10. `lastUsedAt` (timestamp) - (empty, optional)

#### Purchase Tracking by Type (for compensation) ⭐:

**Monthly Subscriptions:**
11. `purchaseCountMonthly` (number) - `0` ⭐
12. `monthlyPurchasedBy` (array) - `[]` ⭐

**Annual Subscriptions:**
13. `purchaseCountAnnual` (number) - `0` ⭐
14. `annualPurchasedBy` (array) - `[]` ⭐

**Lifetime Passes:**
15. `purchaseCountLifetime` (number) - `0` ⭐
16. `lifetimePurchasedBy` (array) - `[]` ⭐

**Total (for convenience):**
17. `purchaseCount` (number) - `0` (sum of all types)
18. `purchasedBy` (array) - `[]` (all users who purchased any type)
19. `lastPurchaseAt` (timestamp) - (empty, optional)

## Complete Field List

| Field Name | Type | Initial Value | Purpose |
|------------|------|---------------|---------|
| `code` | string | `ANTHONY` | The referral code |
| `influencerName` | string | `Anthony Cantu` | Influencer's name |
| `influencerEmail` | string | `anthony@example.com` | Contact email |
| `notes` | string | `Test influencer` | Optional notes |
| `isActive` | boolean | `true` | Is code active? |
| `createdAt` | timestamp | Current time | When created |
| `createdBy` | string | `self_service` | Who created it |
| `usageCount` | number | `0` | Total sign-ups |
| `usedBy` | array | `[]` | User IDs who signed up |
| `lastUsedAt` | timestamp | (empty) | Last sign-up time |
| **`purchaseCountMonthly`** | **number** | **`0`** | **⭐ Monthly subscriptions** |
| **`monthlyPurchasedBy`** | **array** | **`[]`** | **⭐ Users who bought monthly** |
| **`purchaseCountAnnual`** | **number** | **`0`** | **⭐ Annual subscriptions** |
| **`annualPurchasedBy`** | **array** | **`[]`** | **⭐ Users who bought annual** |
| **`purchaseCountLifetime`** | **number** | **`0`** | **⭐ Lifetime passes** |
| **`lifetimePurchasedBy`** | **array** | **`[]`** | **⭐ Users who bought lifetime** |
| `purchaseCount` | number | `0` | Total purchases (all types) |
| `purchasedBy` | array | `[]` | All users who purchased |
| `lastPurchaseAt` | timestamp | (empty) | Last purchase time |

## Compensation Calculation Example

```swift
// Get referral code stats
let codeDoc = try await db.collection("referralCodes").document("ANTHONY").getDocument()
let data = codeDoc.data()

let monthly = data["purchaseCountMonthly"] as? Int ?? 0
let annual = data["purchaseCountAnnual"] as? Int ?? 0
let lifetime = data["purchaseCountLifetime"] as? Int ?? 0

// Calculate compensation (example rates)
let monthlyCommission = 5.0  // $5 per monthly subscription
let annualCommission = 50.0  // $50 per annual subscription
let lifetimeCommission = 200.0  // $200 per lifetime purchase

let totalCompensation = 
    (Double(monthly) * monthlyCommission) +
    (Double(annual) * annualCommission) +
    (Double(lifetime) * lifetimeCommission)
```

## What Gets Updated When

**On Sign-up:**
- `usageCount` increments
- `usedBy` adds user ID
- `lastUsedAt` updates

**On Monthly Purchase:**
- `purchaseCountMonthly` increments ⭐
- `monthlyPurchasedBy` adds user ID ⭐
- `purchaseCount` increments (total)
- `purchasedBy` adds user ID (total)

**On Annual Purchase:**
- `purchaseCountAnnual` increments ⭐
- `annualPurchasedBy` adds user ID ⭐
- `purchaseCount` increments (total)
- `purchasedBy` adds user ID (total)

**On Lifetime Purchase:**
- `purchaseCountLifetime` increments ⭐
- `lifetimePurchasedBy` adds user ID ⭐
- `purchaseCount` increments (total)
- `purchasedBy` adds user ID (total)

## Quick Setup Checklist

When creating your document in Firebase Console, make sure you add:
- ✅ All basic fields (code, name, email, etc.)
- ✅ `purchaseCountMonthly` = 0
- ✅ `monthlyPurchasedBy` = []
- ✅ `purchaseCountAnnual` = 0
- ✅ `annualPurchasedBy` = []
- ✅ `purchaseCountLifetime` = 0
- ✅ `lifetimePurchasedBy` = []
- ✅ `purchaseCount` = 0 (total)
- ✅ `purchasedBy` = [] (total)

