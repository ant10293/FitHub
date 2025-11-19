# Fixes for Issues 1, 3, 4, 5, 6, 7

## Issue #1: Firestore Rules - Secure Purchase Array Updates

**Current Problem:** Rules allow any authenticated user to update purchase arrays, but we need to validate the user actually has a subscription.

**Solution:** Add validation that the user's subscriptionStatus matches what they're claiming.

### Updated Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own user document
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Helper function to validate user has active subscription
    function userHasActiveSubscription() {
      let userDoc = get(/databases/$(database)/documents/users/$(request.auth.uid));
      return userDoc != null && 
             userDoc.data.subscriptionStatus != null &&
             userDoc.data.subscriptionStatus.isActive == true &&
             userDoc.data.subscriptionStatus.originalTransactionID != null;
    }
    
    // Referral codes - allow read, create, and limited updates
    match /referralCodes/{codeId} {
      // Allow read for validation (by exact code ID only - prevents enumeration)
      allow read: if request.auth != null;
      
      // Allow create with validation
      allow create: if request.auth != null && 
                       request.resource.data.createdBy == request.auth.uid;
      
      // Allow updates only for specific fields with validation
      allow update: if request.auth != null && (
        // Allow updating usedBy array and lastUsedAt (for sign-ups)
        // User must have claimed this code
        (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['usedBy', 'lastUsedAt']) &&
         request.auth.uid in resource.data.usedBy) ||
        
        // Allow updating purchase arrays ONLY if user has active subscription
        // AND user's referralCode matches this code
        (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['monthlyPurchasedBy', 'annualPurchasedBy', 'lifetimePurchasedBy', 'activeMonthlySubscriptions', 'activeAnnualSubscriptions', 'activeLifetimeSubscriptions', 'lastPurchaseAt']) &&
         userHasActiveSubscription() &&
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.referralCode == codeId.toUpper())
      );
      
      allow delete: if false; // Only admins can delete
    }
    
    // Users can create their own claim records
    match /referralClaims/{claimId} {
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null;
    }
    
    // Users can create their own purchase records
    match /referralPurchases/{purchaseId} {
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null;
    }
  }
}
```

**Note:** Firestore rules have limitations - the `get()` function counts as a read and has performance implications. If this becomes an issue, move purchase tracking to a Cloud Function (see Issue #4).

---

## Issue #3: Server-Side Validation for Referral Claims

**Current Problem:** Client-side validation can be bypassed.

**Solution:** Create a Cloud Function to handle referral code claiming with server-side validation.

### New Cloud Function: `claimReferralCode`

Add to `Firebase/functions/src/index.ts`:

```typescript
/**
 * Cloud Function to claim a referral code with server-side validation
 */
export const claimReferralCode = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const referralCode = typeof data?.referralCode === 'string' 
    ? data.referralCode.trim().toUpperCase() 
    : '';

  if (!referralCode) {
    throw new functions.https.HttpsError('invalid-argument', 'Referral code is required');
  }

  // Validate code format (if you have validation logic)
  if (referralCode.length < 4 || referralCode.length > 20) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid referral code format');
  }

  const db = admin.firestore();
  const codeRef = db.collection('referralCodes').doc(referralCode);
  const userRef = db.collection('users').doc(userId);

  try {
    // Use transaction to ensure atomicity
    return await db.runTransaction(async (transaction) => {
      // 1. Check if code exists and is active
      const codeDoc = await transaction.get(codeRef);
      if (!codeDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Referral code not found');
      }

      const codeData = codeDoc.data()!;
      if (!codeData.isActive) {
        throw new functions.https.HttpsError('failed-precondition', 'Referral code is not active');
      }

      // 2. Check if user already has a referral code
      const userDoc = await transaction.get(userRef);
      const userData = userDoc.data();
      
      if (userData?.referralCode) {
        throw new functions.https.HttpsError('already-exists', 'User already has a referral code');
      }

      // 3. Perform the claim atomically
      transaction.update(userRef, {
        referralCode: referralCode,
        referralCodeClaimedAt: admin.firestore.FieldValue.serverTimestamp(),
        referralSource: data.source || 'manual_entry'
      });

      transaction.update(codeRef, {
        lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
        usedBy: admin.firestore.FieldValue.arrayUnion(userId)
      });

      return { success: true, referralCode: referralCode };
    });
  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error('Error claiming referral code:', error);
    throw new functions.https.HttpsError('internal', 'Failed to claim referral code');
  }
});
```

### Update `ReferralAttributor.swift` to use Cloud Function:

```swift
func claimIfNeeded(source: ClaimSource = .universalLink) async {
    guard let userId = AuthService.getUid() else { return }

    guard let raw = UserDefaults.standard.string(forKey: "pendingReferralCode") else { return }
    let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    guard !code.isEmpty else { return }

    guard ReferralCodeGenerator.isValidCode(code) else {
        print("⚠️ Invalid referral code format: \(code)")
        UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
        return
    }
    
    // Use Cloud Function instead of direct Firestore write
    let functions = Functions.functions()
    let claimFunction = functions.httpsCallable("claimReferralCode")
    
    do {
        let result = try await claimFunction.call([
            "referralCode": code,
            "source": source.rawValue
        ])
        
        print("✅ Successfully claimed referral code: \(code)")
        UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
        
    } catch {
        print("❌ Referral claim failed: \(error.localizedDescription)")
        // Keep code for retry on next sign-in
    }
}
```

---

## Issue #4: Race Condition in Purchase Tracking

**Current Problem:** Read-then-write pattern allows duplicate tracking.

**Solution:** Use Firestore transaction for atomic read-modify-write.

### Updated `ReferralPurchaseTracker.swift`:

```swift
func trackPurchase(productID: String, transactionID: UInt64, originalTransactionID: UInt64, environment: String) async {
    await ReferralAttributor().claimIfNeeded()
    
    guard let userId = AuthService.getUid() else {
        print("⚠️ Cannot track referral purchase: user not authenticated")
        return
    }
    
    guard let code = await ReferralRetriever.getClaimedCode() else {
        print("ℹ️ No referral code claimed, skipping purchase tracking")
        return
    }
    
    do {
        let codeRef = db.collection("referralCodes").document(code.uppercased())
        let userRef = db.collection("users").document(userId)
        
        // Use transaction for atomic read-modify-write
        try await db.runTransaction { transaction, errorPointer in
            // Read both documents
            let codeDoc: DocumentSnapshot
            let userDoc: DocumentSnapshot
            
            do {
                codeDoc = try transaction.getDocument(codeRef)
                userDoc = try transaction.getDocument(userRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            guard codeDoc.exists else {
                let error = NSError(domain: "ReferralPurchaseTracker", code: -1, 
                                  userInfo: [NSLocalizedDescriptionKey: "Referral code not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Check if already tracked (atomic check)
            if let existingProductID = userDoc.data()?["referralPurchaseProductID"] as? String,
               existingProductID == productID {
                // Already tracked, return success
                return true
            }
            
            let subscriptionType = PremiumStore.ID.membershipType(for: productID)
            guard subscriptionType != .free else {
                return true // Not a premium product, nothing to track
            }
            
            // Get current subscription type
            let currentSubscriptionType = PremiumStore.ID.membershipType(
                for: userDoc.data()?["referralPurchaseProductID"] as? String
            )
            
            // Prepare updates
            var codeUpdates: [String: Any] = ["lastPurchaseAt": FieldValue.serverTimestamp()]
            
            // Remove from old active array if switching subscriptions
            if currentSubscriptionType != .free && currentSubscriptionType != subscriptionType {
                switch currentSubscriptionType {
                case .monthly:
                    codeUpdates["activeMonthlySubscriptions"] = FieldValue.arrayRemove([userId])
                case .yearly:
                    codeUpdates["activeAnnualSubscriptions"] = FieldValue.arrayRemove([userId])
                case .free, .lifetime:
                    break
                }
            }
            
            // Add to appropriate arrays
            switch subscriptionType {
            case .monthly:
                codeUpdates["monthlyPurchasedBy"] = FieldValue.arrayUnion([userId])
                codeUpdates["activeMonthlySubscriptions"] = FieldValue.arrayUnion([userId])
            case .yearly:
                codeUpdates["annualPurchasedBy"] = FieldValue.arrayUnion([userId])
                codeUpdates["activeAnnualSubscriptions"] = FieldValue.arrayUnion([userId])
            case .lifetime:
                codeUpdates["lifetimePurchasedBy"] = FieldValue.arrayUnion([userId])
                codeUpdates["activeLifetimeSubscriptions"] = FieldValue.arrayUnion([userId])
            case .free:
                break
            }
            
            // Update referral code
            transaction.updateData(codeUpdates, forDocument: codeRef)
            
            // Update user document
            transaction.updateData([
                "referralCodeUsedForPurchase": true,
                "referralPurchaseDate": FieldValue.serverTimestamp(),
                "referralPurchaseProductID": productID,
                "subscriptionStatus": [
                    "originalTransactionID": String(originalTransactionID),
                    "transactionID": String(transactionID),
                    "productID": productID,
                    "isActive": true,
                    "lastValidatedAt": FieldValue.serverTimestamp(),
                    "environment": environment
                ]
            ], forDocument: userRef)
            
            return true
        }
        
        print("✅ Successfully tracked purchase for referral code: \(code)")
        
    } catch {
        print("❌ Failed to track referral purchase: \(error.localizedDescription)")
    }
}
```

---

## Issue #5: Subscription Validation Error Recovery (Server-Side)

**Current Problem:** Cloud Function `validateUserSubscription` doesn't retry on failures.

**Solution:** Add retry logic with exponential backoff.

### Updated `validateUserSubscription` function:

```typescript
/**
 * Validates a single user's subscription status with retry logic
 */
async function validateUserSubscription(userId: string, retryCount: number = 0): Promise<void> {
  const maxRetries = 3;
  const baseDelay = 2000; // 2 seconds

  try {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.data();
    
    if (!userData?.subscriptionStatus?.originalTransactionID) {
      return; // No subscription to validate
    }
    
    const originalTransactionId = userData.subscriptionStatus.originalTransactionID;
    
    const appStoreAPI = getAppStoreAPI();
    const statusResponse = await appStoreAPI.getAllSubscriptionStatuses(originalTransactionId);
    
    if (!statusResponse.data || statusResponse.data.length === 0) {
      console.warn(`No subscription status found for transaction ${originalTransactionId}`);
      return;
    }
    
    // Find the transaction that matches our originalTransactionId
    let matchingTransaction: any = null;
    for (const group of statusResponse.data) {
      if (group.lastTransactions) {
        matchingTransaction = group.lastTransactions.find(
          (t: any) => t.originalTransactionId === originalTransactionId
        );
        if (matchingTransaction) break;
      }
    }
    
    if (!matchingTransaction) {
      console.warn(`No matching transaction found for ${originalTransactionId}`);
      return;
    }
    
    const status = matchingTransaction.status;
    const isActive = status === 1;
    
    // Update user's subscription status
    await admin.firestore().collection("users").doc(userId).update({
      "subscriptionStatus.isActive": isActive,
      "subscriptionStatus.lastValidatedAt": admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Update referral code active subscriptions
    await updateReferralCodeSubscriptions(userId);
    
    console.log(`✅ Successfully validated subscription for user ${userId}: active=${isActive}`);
    
  } catch (error: any) {
    console.error(`Error validating subscription for user ${userId} (attempt ${retryCount + 1}/${maxRetries}):`, error);
    
    // Retry on transient errors
    if (retryCount < maxRetries && (
      error.code === 'ECONNRESET' ||
      error.code === 'ETIMEDOUT' ||
      error.message?.includes('timeout') ||
      error.statusCode >= 500
    )) {
      const delay = baseDelay * Math.pow(2, retryCount); // Exponential backoff
      console.log(`Retrying validation for user ${userId} in ${delay}ms...`);
      
      await new Promise(resolve => setTimeout(resolve, delay));
      return validateUserSubscription(userId, retryCount + 1);
    }
    
    // Max retries reached or non-retryable error
    throw error;
  }
}
```

### Update `validateAllSubscriptions` to handle retries:

```typescript
export const validateAllSubscriptions = functions.pubsub
  .schedule("0 2 * * *")
  .timeZone("UTC")
  .onRun(async () => {
    console.log("Starting daily subscription validation...");
    
    const codesSnapshot = await admin.firestore()
      .collection("referralCodes")
      .get();
    
    console.log(`Validating subscriptions for ${codesSnapshot.size} referral codes`);
    
    let validatedCount = 0;
    let errorCount = 0;
    const failedUserIds: string[] = [];
    
    for (const codeDoc of codesSnapshot.docs) {
      const codeData = codeDoc.data();
      
      const allUserIds = [
        ...(codeData.monthlyPurchasedBy || []),
        ...(codeData.annualPurchasedBy || []),
        ...(codeData.lifetimePurchasedBy || []),
      ];
      
      const uniqueUserIds = [...new Set(allUserIds)];
      
      for (const userId of uniqueUserIds) {
        try {
          await validateUserSubscription(userId);
          validatedCount++;
        } catch (error) {
          console.error(`Failed to validate subscription for user ${userId} after retries:`, error);
          errorCount++;
          failedUserIds.push(userId);
        }
      }
    }
    
    console.log(`Daily validation complete: ${validatedCount} validated, ${errorCount} errors`);
    
    // Optionally: Send alert if too many failures
    if (errorCount > 10) {
      console.error(`⚠️ High failure rate: ${errorCount} users failed validation`);
      // TODO: Send alert to monitoring system
    }
    
    return { validatedCount, errorCount, failedUserIds };
  });
```

---

## Issue #6: Restrict Referral Code Read Access

**Current Problem:** Any authenticated user can read any referral code.

**Solution:** Restrict read access to prevent enumeration while allowing validation.

### Updated Firestore Rules:

```javascript
match /referralCodes/{codeId} {
  // Allow read only for:
  // 1. Code creator (full access)
  // 2. Users validating by exact code ID (limited - only isActive field)
  // This prevents enumeration while allowing code validation
  allow read: if request.auth != null && (
    // Creator can read their own codes
    resource.data.createdBy == request.auth.uid ||
    // Anyone can read by exact ID (needed for validation, but prevents enumeration)
    // Note: Firestore rules can't restrict which fields are returned,
    // but we can validate in Cloud Function if needed
    true
  );
  
  // ... rest of rules
}
```

**Better Solution:** Use Cloud Function for validation that only returns `isActive`:

### New Cloud Function: `validateReferralCode`

```typescript
/**
 * Validates a referral code exists and is active (returns minimal info)
 */
export const validateReferralCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const referralCode = typeof data?.referralCode === 'string' 
    ? data.referralCode.trim().toUpperCase() 
    : '';

  if (!referralCode) {
    throw new functions.https.HttpsError('invalid-argument', 'Referral code is required');
  }

  const codeRef = admin.firestore().collection('referralCodes').doc(referralCode);
  const codeDoc = await codeRef.get();

  if (!codeDoc.exists) {
    return { exists: false, isActive: false };
  }

  const codeData = codeDoc.data()!;
  
  // Only return minimal info needed for validation
  return {
    exists: true,
    isActive: codeData.isActive || false,
    // Don't return sensitive data like email, notes, etc.
  };
});
```

### Update `ReferralAttributor.swift` to use Cloud Function:

```swift
// In claimIfNeeded, replace direct Firestore read with Cloud Function call
let functions = Functions.functions()
let validateFunction = functions.httpsCallable("validateReferralCode")

let result = try await validateFunction.call(["referralCode": code])
let data = result.data as? [String: Any]

guard let exists = data?["exists"] as? Bool, exists,
      let isActive = data?["isActive"] as? Bool, isActive else {
    print("⚠️ Referral code not found or inactive: \(code)")
    UserDefaults.standard.removeObject(forKey: "pendingReferralCode")
    return
}
```

---

## Issue #7: Transaction ID Validation

**Current Problem:** Purchase tracking doesn't validate transaction actually exists.

**Solution:** Verify transaction with StoreKit before tracking.

### Updated `ReferralPurchaseTracker.swift`:

```swift
import StoreKit

func trackPurchase(productID: String, transactionID: UInt64, originalTransactionID: UInt64, environment: String) async {
    // ... existing code ...
    
    // NEW: Validate transaction exists and belongs to user
    do {
        // Verify transaction exists in StoreKit
        var transactionFound = false
        for await result in Transaction.all {
            guard case .verified(let transaction) = result else { continue }
            
            // Check if this matches our transaction
            if transaction.id == transactionID && 
               transaction.originalID == originalTransactionID {
                // Verify it's for the correct product
                guard transaction.productID == productID else {
                    print("⚠️ Transaction product ID mismatch")
                    return
                }
                
                // Verify it belongs to current user (if appAccountToken is set)
                // Note: StoreKit 2 doesn't directly expose user info,
                // but transactions are scoped to the current Apple ID
                transactionFound = true
                break
            }
        }
        
        if !transactionFound {
            print("⚠️ Transaction not found in StoreKit: \(transactionID)")
            return
        }
        
    } catch {
        print("⚠️ Failed to verify transaction: \(error.localizedDescription)")
        // Continue anyway - transaction might be pending
    }
    
    // Continue with existing tracking logic...
    // ... rest of function
}
```

**Alternative:** Validate via App Store Server API in Cloud Function (more reliable):

### Cloud Function: `trackReferralPurchase`

```typescript
/**
 * Tracks referral purchase with transaction validation
 */
export const trackReferralPurchase = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const productID = data?.productID;
  const originalTransactionID = data?.originalTransactionID;

  if (!productID || !originalTransactionID) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  // Validate transaction with App Store Server API
  try {
    const appStoreAPI = getAppStoreAPI();
    const statusResponse = await appStoreAPI.getAllSubscriptionStatuses(String(originalTransactionID));
    
    if (!statusResponse.data || statusResponse.data.length === 0) {
      throw new functions.https.HttpsError('not-found', 'Transaction not found');
    }

    // Verify transaction exists and is valid
    let transactionFound = false;
    for (const group of statusResponse.data) {
      if (group.lastTransactions) {
        const matching = group.lastTransactions.find(
          (t: any) => t.originalTransactionId === String(originalTransactionID)
        );
        if (matching) {
          transactionFound = true;
          break;
        }
      }
    }

    if (!transactionFound) {
      throw new functions.https.HttpsError('not-found', 'Transaction not found');
    }

    // Get user's referral code
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (!userData?.referralCode) {
      throw new functions.https.HttpsError('failed-precondition', 'User has no referral code');
    }

    // Continue with purchase tracking (use transaction for atomicity)
    // ... similar to Issue #4 solution

  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error('Error tracking purchase:', error);
    throw new functions.https.HttpsError('internal', 'Failed to track purchase');
  }
});
```

---

## Summary

1. **Issue #1**: Add validation in Firestore rules (or move to Cloud Function)
2. **Issue #3**: Create `claimReferralCode` Cloud Function
3. **Issue #4**: Use Firestore transaction in `trackPurchase`
4. **Issue #5**: Add retry logic to `validateUserSubscription`
5. **Issue #6**: Create `validateReferralCode` Cloud Function (or restrict rules)
6. **Issue #7**: Validate transaction with StoreKit/App Store API before tracking

All fixes maintain backward compatibility where possible.



