# Firestore Document Setup - With Purchase Tracking

## Creating Your First `referralCodes` Document

When creating the document in Firebase Console, add ALL these fields:

### Document ID
- Enter: `ANTHONY` (or your test code, uppercase)

### Required Fields (Add one by one):

#### 1. `code` (string)
- Field: `code`
- Type: `string`
- Value: `ANTHONY`

#### 2. `influencerName` (string)
- Field: `influencerName`
- Type: `string`
- Value: `Anthony Cantu`

#### 3. `influencerEmail` (string)
- Field: `influencerEmail`
- Type: `string`
- Value: `anthony@example.com` (or leave empty `""`)

#### 4. `notes` (string)
- Field: `notes`
- Type: `string`
- Value: `Test influencer` (or leave empty `""`)

#### 5. `isActive` (boolean)
- Field: `isActive`
- Type: `boolean`
- Value: `true` (toggle checkbox)

#### 6. `createdAt` (timestamp)
- Field: `createdAt`
- Type: `timestamp`
- Value: Click to set current time

#### 7. `createdBy` (string)
- Field: `createdBy`
- Type: `string`
- Value: `self_service` (or the user ID if created by a user)

### Sign-up Tracking Fields:

#### 8. `usageCount` (number)
- Field: `usageCount`
- Type: `number`
- Value: `0`

#### 9. `usedBy` (array)
- Field: `usedBy`
- Type: `array`
- Value: Leave empty (it will show `[]`)

#### 10. `lastUsedAt` (timestamp)
- Field: `lastUsedAt`
- Type: `timestamp`
- Value: Leave empty (optional, will be set on first sign-up)

### Purchase Tracking Fields (NEW - for compensation):

#### 11. `purchaseCount` (number) ⭐
- Field: `purchaseCount`
- Type: `number`
- Value: `0`
- **This is what matters for compensation!**

#### 12. `purchasedBy` (array) ⭐
- Field: `purchasedBy`
- Type: `array`
- Value: Leave empty (it will show `[]`)
- **Tracks which users purchased subscriptions**

#### 13. `lastPurchaseAt` (timestamp) ⭐
- Field: `lastPurchaseAt`
- Type: `timestamp`
- Value: Leave empty (optional, will be set on first purchase)

## Complete Field List Summary

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
| **`purchaseCount`** | **number** | **`0`** | **⭐ Purchases (for compensation)** |
| **`purchasedBy`** | **array** | **`[]`** | **⭐ Users who purchased** |
| **`lastPurchaseAt`** | **timestamp** | **(empty)** | **⭐ Last purchase time** |

## What Gets Updated When

- **On Sign-up:** `usageCount` increments, `usedBy` adds user, `lastUsedAt` updates
- **On Purchase:** `purchaseCount` increments, `purchasedBy` adds user, `lastPurchaseAt` updates ⭐

## Compensation Calculation

When you want to pay influencers:
- Check `purchaseCount` (not `usageCount`)
- This is the number of users who purchased subscriptions
- Only these count for compensation

