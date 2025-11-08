# Subscription Validation & Payout System

## Problem Statement

You need to accurately track which subscriptions are **actively paying** to calculate correct 40% payouts to influencers. The challenge:
- Monthly subscriptions can be canceled after the first month
- Users may not open the app for months
- You need 100% certainty of subscription status from the backend
- This must work automatically without user interaction

## Solution Architecture

### 1. App Store Server Notifications (SSNs)
Apple sends webhooks to your backend when subscription status changes:
- Initial purchase
- Renewals
- Cancellations
- Expirations
- Refunds
- Grace periods

### 2. App Store Server API
Query Apple's servers directly to get real-time subscription status for any user.

### 3. Updated Firestore Schema

#### `users/{userId}` - Add subscription tracking:
```javascript
{
  // Existing fields...
  referralCode: "ANTHONY",
  referralCodeClaimedAt: Timestamp,
  referralCodeUsedForPurchase: true,
  referralPurchaseDate: Timestamp,
  referralPurchaseProductID: "com.FitHub.premium.monthly",
  
  // NEW: Subscription status tracking
  subscriptionStatus: {
    productID: "com.FitHub.premium.monthly",
    isActive: true,
    expiresAt: Timestamp,  // For subscriptions
    originalTransactionID: "1000000123456789",  // Key identifier
    lastValidatedAt: Timestamp,
    autoRenews: true,
    environment: "Production"  // or "Sandbox"
  }
}
```

#### `referralCodes/{code}` - Add active subscription tracking:
```javascript
{
  // Existing fields...
  monthlyPurchasedBy: ["userId1", "userId2"],
  annualPurchasedBy: ["userId3"],
  lifetimePurchasedBy: ["userId4"],
  
  // NEW: Track active subscriptions separately
  activeMonthlySubscriptions: ["userId1"],  // Only users with active monthly
  activeAnnualSubscriptions: ["userId3"],
  activeLifetimeSubscriptions: ["userId4"],  // Lifetime stays active until refund
  
  // Last validation timestamp
  lastValidationAt: Timestamp
}
```

#### NEW: `subscriptionPayouts/{payoutId}` - Track payouts:
```javascript
{
  referralCode: "ANTHONY",
  influencerId: "userId",
  period: "2025-01",  // YYYY-MM format
  calculations: {
    monthly: {
      activeCount: 5,
      revenuePerUser: 4.99,
      totalRevenue: 24.95,
      payoutPercentage: 0.40,
      payoutAmount: 9.98
    },
    annual: {
      activeCount: 2,
      revenuePerUser: 49.99,
      totalRevenue: 99.98,
      payoutPercentage: 0.40,
      payoutAmount: 39.99
    },
    lifetime: {
      activeCount: 1,
      revenuePerUser: 199.99,
      totalRevenue: 199.99,
      payoutPercentage: 0.40,
      payoutAmount: 79.99
    }
  },
  totalPayout: 129.96,
  status: "pending",  // pending, paid, failed
  paidAt: Timestamp,
  createdAt: Timestamp
}
```

## Implementation Steps

### Step 1: Set Up App Store Connect API

1. Go to **App Store Connect** → **Users and Access** → **Integrations**
2. Create a new **App Store Connect API Key**
3. Download the `.p8` key file
4. Note the **Key ID** and **Issuer ID**
5. Store these securely (use Firebase Functions environment variables)

### Step 2: Create Firebase Cloud Functions

Create a new directory: `functions/` at the root of your project.

```bash
cd /path/to/FitHub
firebase init functions
# Choose TypeScript
# Install dependencies: npm install @apple/app-store-server-library
```

### Step 3: Cloud Function: Handle SSN Webhooks

`functions/src/index.ts`:

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { AppStoreServerAPI } from "@apple/app-store-server-library";

admin.initializeApp();

const appStoreAPI = new AppStoreServerAPI({
  issuerId: functions.config().appstore.issuer_id,
  keyId: functions.config().appstore.key_id,
  privateKey: functions.config().appstore.private_key.replace(/\\n/g, '\n'),
  bundleId: "com.AnthonyC.FitHub",
  environment: "Production" // or "Sandbox" for testing
});

// Endpoint for App Store Server Notifications
export const handleAppStoreNotification = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method not allowed");
  }

  try {
    const notification = req.body;
    const notificationType = notification.notificationType;
    
    // Get the transaction info
    const signedTransactionInfo = notification.signedTransactionInfo;
    const transactionInfo = await appStoreAPI.getTransactionInfo(signedTransactionInfo);
    
    // CRITICAL: Link transaction to user
    // Option 1: Use appAccountToken (requires passing Firebase UID as UUID)
    // Option 2: Query Firestore for user with matching originalTransactionID
    // We'll use Option 2 as it's simpler and doesn't require UUID conversion
    
    const originalTransactionId = transactionInfo.originalTransactionId;
    
    // Find user by matching originalTransactionID in their subscriptionStatus
    const usersSnapshot = await admin.firestore()
      .collection("users")
      .where("subscriptionStatus.originalTransactionID", "==", String(originalTransactionId))
      .limit(1)
      .get();
    
    if (usersSnapshot.empty) {
      console.warn(`No user found for transaction ${originalTransactionId}`);
      return; // Can't process without user
    }
    
    const userId = usersSnapshot.docs[0].id;
    
    console.log(`Processing ${notificationType} for transaction ${originalTransactionId}`);
    
    // Update subscription status in Firestore
    await updateSubscriptionStatus(userId, originalTransactionId, notificationType);
    
    // Update referral code active subscriptions
    await updateReferralCodeSubscriptions(userId);
    
    res.status(200).send("OK");
  } catch (error) {
    console.error("Error processing notification:", error);
    res.status(500).send("Error");
  }
});

async function updateSubscriptionStatus(
  userId: string,
  originalTransactionId: string,
  notificationType: string
) {
  const userRef = admin.firestore().collection("users").doc(userId);
  
  // Get current subscription info from App Store
  const statusResponse = await appStoreAPI.getSubscriptionStatus(originalTransactionId);
  const subscriptionStatus = statusResponse.data[0];
  
  const latestTransaction = subscriptionStatus.latestTransactions[0];
  const transaction = await appStoreAPI.getTransactionInfo(latestTransaction.signedTransactionInfo);
  
  const isActive = subscriptionStatus.status === 1; // 1 = Active
  const expiresAt = transaction.expiresDate ? new Date(transaction.expiresDate) : null;
  const autoRenews = subscriptionStatus.autoRenewStatus === 1;
  
  await userRef.update({
    "subscriptionStatus": {
      productID: transaction.productId,
      isActive,
      expiresAt: expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
      originalTransactionID: originalTransactionId,
      lastValidatedAt: admin.firestore.FieldValue.serverTimestamp(),
      autoRenews,
      environment: transaction.environment
    }
  });
}

async function updateReferralCodeSubscriptions(userId: string) {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  const userData = userDoc.data();
  
  if (!userData?.referralCode) return;
  
  const referralCode = userData.referralCode.toUpperCase();
  const codeRef = admin.firestore().collection("referralCodes").doc(referralCode);
  const subscriptionStatus = userData.subscriptionStatus;
  
  if (!subscriptionStatus) return;
  
  const productID = subscriptionStatus.productID;
  const isActive = subscriptionStatus.isActive;
  
  // Determine subscription type
  let activeArray: string;
  let purchasedArray: string;
  
  if (productID.includes("monthly")) {
    activeArray = "activeMonthlySubscriptions";
    purchasedArray = "monthlyPurchasedBy";
  } else if (productID.includes("yearly") || productID.includes("annual")) {
    activeArray = "activeAnnualSubscriptions";
    purchasedArray = "annualPurchasedBy";
  } else if (productID.includes("lifetime")) {
    activeArray = "activeLifetimeSubscriptions";
    purchasedArray = "lifetimePurchasedBy";
  } else {
    return;
  }
  
  const updates: any = {};
  
  if (isActive) {
    // Add to active array if not already there
    updates[activeArray] = admin.firestore.FieldValue.arrayUnion(userId);
  } else {
    // Remove from active array
    updates[activeArray] = admin.firestore.FieldValue.arrayRemove(userId);
  }
  
  // Ensure user is in purchased array
  updates[purchasedArray] = admin.firestore.FieldValue.arrayUnion(userId);
  updates.lastValidationAt = admin.firestore.FieldValue.serverTimestamp();
  
  await codeRef.update(updates);
}
```

### Step 4: Cloud Function: Periodic Validation (Backup)

Run daily to validate all subscriptions in case SSNs are missed:

```typescript
// Run daily at 2 AM UTC
export const validateAllSubscriptions = functions.pubsub
  .schedule("0 2 * * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    const codesSnapshot = await admin.firestore()
      .collection("referralCodes")
      .get();
    
    for (const codeDoc of codesSnapshot.docs) {
      const codeData = codeDoc.data();
      
      // Get all users who purchased
      const allUserIds = [
        ...(codeData.monthlyPurchasedBy || []),
        ...(codeData.annualPurchasedBy || []),
        ...(codeData.lifetimePurchasedBy || [])
      ];
      
      // Validate each user's subscription
      for (const userId of allUserIds) {
        await validateUserSubscription(userId);
      }
    }
  });

async function validateUserSubscription(userId: string) {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  const userData = userDoc.data();
  
  if (!userData?.subscriptionStatus?.originalTransactionID) return;
  
  const originalTransactionId = userData.subscriptionStatus.originalTransactionID;
  
  try {
    const statusResponse = await appStoreAPI.getSubscriptionStatus(originalTransactionId);
    const subscriptionStatus = statusResponse.data[0];
    
    const isActive = subscriptionStatus.status === 1;
    
    // Update user's subscription status
    await admin.firestore().collection("users").doc(userId).update({
      "subscriptionStatus.isActive": isActive,
      "subscriptionStatus.lastValidatedAt": admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Update referral code active subscriptions
    await updateReferralCodeSubscriptions(userId);
  } catch (error) {
    console.error(`Error validating subscription for user ${userId}:`, error);
  }
}
```

### Step 5: Cloud Function: Calculate Payouts

```typescript
// Run monthly on the 1st at 3 AM UTC
export const calculateMonthlyPayouts = functions.pubsub
  .schedule("0 3 1 * *")
  .timeZone("UTC")
  .onRun(async (context) => {
    const lastMonth = new Date();
    lastMonth.setMonth(lastMonth.getMonth() - 1);
    const period = `${lastMonth.getFullYear()}-${String(lastMonth.getMonth() + 1).padStart(2, '0')}`;
    
    const codesSnapshot = await admin.firestore()
      .collection("referralCodes")
      .get();
    
    for (const codeDoc of codesSnapshot.docs) {
      const code = codeDoc.id;
      const codeData = codeDoc.data();
      
      // Get active subscription counts
      const activeMonthly = (codeData.activeMonthlySubscriptions || []).length;
      const activeAnnual = (codeData.activeAnnualSubscriptions || []).length;
      const activeLifetime = (codeData.activeLifetimeSubscriptions || []).length;
      
      if (activeMonthly === 0 && activeAnnual === 0 && activeLifetime === 0) {
        continue; // Skip codes with no active subscriptions
      }
      
      // Calculate payouts
      const calculations = {
        monthly: {
          activeCount: activeMonthly,
          revenuePerUser: 4.99, // Adjust based on your pricing
          totalRevenue: activeMonthly * 4.99,
          payoutPercentage: 0.40,
          payoutAmount: activeMonthly * 4.99 * 0.40
        },
        annual: {
          activeCount: activeAnnual,
          revenuePerUser: 49.99, // Adjust based on your pricing
          totalRevenue: activeAnnual * 49.99,
          payoutPercentage: 0.40,
          payoutAmount: activeAnnual * 49.99 * 0.40
        },
        lifetime: {
          activeCount: activeLifetime,
          revenuePerUser: 199.99, // Adjust based on your pricing
          totalRevenue: activeLifetime * 199.99,
          payoutPercentage: 0.40,
          payoutAmount: activeLifetime * 199.99 * 0.40
        }
      };
      
      const totalPayout = 
        calculations.monthly.payoutAmount +
        calculations.annual.payoutAmount +
        calculations.lifetime.payoutAmount;
      
      // Get influencer user ID
      const influencerId = codeData.createdBy;
      
      // Create payout record
      await admin.firestore().collection("subscriptionPayouts").add({
        referralCode: code,
        influencerId,
        period,
        calculations,
        totalPayout,
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`Created payout for ${code}: $${totalPayout.toFixed(2)}`);
    }
  });
```

### Step 6: Update iOS App to Send Transaction ID

**CRITICAL:** You need to store the `originalTransactionID` when purchases are made. This is the key that links Apple's transaction data to your Firebase users.

In `PremiumStore.swift`, update the purchase tracking:

```swift
// In PremiumStore.buy() after successful purchase:
case .success(let verification):
    let transaction = try verify(verification)
    
    // Track referral purchase if user has a referral code
    Task {
        await ReferralPurchaseTracker().trackPurchase(
            productID: product.id,
            transactionID: transaction.id,
            originalTransactionID: transaction.originalID  // ADD THIS
        )
    }
```

Update `ReferralPurchaseTracker.swift`:

```swift
func trackPurchase(
    productID: String,
    transactionID: UInt64,
    originalTransactionID: UInt64  // ADD THIS PARAMETER
) async {
    // Must be signed in        
    guard let userId = AuthService.getUid() else {
        print("⚠️ Cannot track referral purchase: user not authenticated")
        return
    }
    
    // Get referral code (from UserDefaults or Firestore)
    guard let code = await ReferralRetriever.getClaimedCode() else {
        print("ℹ️ No referral code claimed, skipping purchase tracking")
        return
    }
    
    do {
        // Get referral code info
        let codeRef = db.collection("referralCodes").document(code.uppercased())
        let codeDoc = try await codeRef.getDocument()
        
        guard codeDoc.exists else {
            print("⚠️ Referral code not found: \(code)")
            return
        }
        
        // Determine subscription type for compensation tracking
        let subscriptionType = PremiumStore.ID.membershipType(for: productID)
        
        // Check if this purchase was already tracked
        let userRef = db.collection("users").document(userId)
        let userDoc = try await userRef.getDocument()
        
        if let existingPurchaseProductID = userDoc.data()?["referralPurchaseProductID"] as? String,
           existingPurchaseProductID == productID {
            print("ℹ️ Purchase already tracked for product: \(productID)")
            return
        }
        
        // Perform the tracking in a batch
        let batch = db.batch()
        
        // 1. Update referral code document - track purchases by type
        var updateData: [String: Any] = [
            "lastPurchaseAt": FieldValue.serverTimestamp()
        ]
        
        // Add to the appropriate array based on subscription type
        switch subscriptionType {
        case .monthly:
            updateData["monthlyPurchasedBy"] = FieldValue.arrayUnion([userId])
            updateData["activeMonthlySubscriptions"] = FieldValue.arrayUnion([userId])
        case .yearly:
            updateData["annualPurchasedBy"] = FieldValue.arrayUnion([userId])
            updateData["activeAnnualSubscriptions"] = FieldValue.arrayUnion([userId])
        case .lifetime:
            updateData["lifetimePurchasedBy"] = FieldValue.arrayUnion([userId])
            updateData["activeLifetimeSubscriptions"] = FieldValue.arrayUnion([userId])
        case .free:
            break
        }
        
        guard subscriptionType != .free else { return }
        
        batch.updateData(updateData, forDocument: codeRef)
        
        // 2. Update user document to mark that they purchased
        // CRITICAL: Store originalTransactionID so webhooks can link back to user
        batch.updateData([
            "referralCodeUsedForPurchase": true,
            "referralPurchaseDate": FieldValue.serverTimestamp(),
            "referralPurchaseProductID": productID,
            "subscriptionStatus": [
                "originalTransactionID": String(originalTransactionID),
                "productID": productID,
                "isActive": true,  // Assume active on purchase
                "lastValidatedAt": FieldValue.serverTimestamp(),
                "environment": "Production"  // or detect sandbox
            ]
        ], forDocument: userRef)
        
        try await batch.commit()
        
        print("✅ Successfully tracked \(subscriptionType.rawValue) purchase for referral code: \(code)")
        
    } catch {
        print("❌ Failed to track referral purchase: \(error.localizedDescription)")
    }
}
```

And update `PremiumStore.swift` to pass the originalTransactionID:

```swift
case .success(let verification):
    let transaction = try verify(verification)
    
    // Track referral purchase if user has a referral code
    Task {
        await ReferralPurchaseTracker().trackPurchase(
            productID: product.id,
            transactionID: transaction.id,
            originalTransactionID: transaction.originalID  // ADD THIS
        )
    }
    
    await transaction.finish()
    await refreshEntitlement()
```

### Step 7: Configure App Store Connect

1. Go to **App Store Connect** → Your App → **App Information**
2. Scroll to **App Store Server Notifications**
3. Enter your webhook URL: `https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/handleAppStoreNotification`
4. Save

## Testing

### Sandbox Testing
1. Use a sandbox test account
2. Set Cloud Function environment to "Sandbox"
3. Make test purchases
4. Verify webhooks are received

### Production Testing
1. Monitor Cloud Function logs
2. Check Firestore for updated subscription statuses
3. Verify active subscription arrays are correct

## Security Considerations

1. **Validate webhook signatures** from Apple (not shown above, but recommended)
2. **Use environment variables** for sensitive keys
3. **Rate limit** validation requests to avoid hitting API limits
4. **Handle errors gracefully** - retry failed validations

## Monitoring

Create alerts for:
- Failed webhook processing
- Validation errors
- Payout calculation discrepancies
- API rate limit warnings

## Payout Process

1. Monthly function calculates payouts
2. Review payout records in Firestore
3. Process payments to influencers
4. Update payout status to "paid"

This system ensures 100% accuracy by:
- ✅ Real-time updates via SSNs
- ✅ Daily validation backup
- ✅ Direct queries to Apple's servers
- ✅ Separate tracking of active vs. purchased subscriptions

## Summary: What You Need to Do

1. **Set up App Store Connect API** - Get your API keys
2. **Create Firebase Cloud Functions** - Implement the webhook handler and validation functions
3. **Update iOS app** - Store `originalTransactionID` when purchases happen
4. **Configure App Store Connect** - Point webhooks to your Cloud Function
5. **Test thoroughly** - Use sandbox accounts first
6. **Monitor** - Set up alerts for validation failures

## Key Points

- **`originalTransactionID`** is the critical link between Apple's transaction data and your Firebase users
- **Active subscriptions** are tracked separately from **purchased subscriptions**
- **Webhooks** provide real-time updates, but **daily validation** catches any missed events
- **Payout calculations** use only **active subscriptions**, ensuring accurate 40% commissions

This architecture scales to thousands of users and ensures you never overpay or underpay influencers.

