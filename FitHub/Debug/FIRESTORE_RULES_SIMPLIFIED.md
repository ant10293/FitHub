# Simplified Firestore Security Rules

## Updated Rules (No Analytics Collections)

Copy and paste this into Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only read/write their own user document
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Referral codes - allow read, create, and updates
    match /referralCodes/{codeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if false; // Only admins can delete
    }
  }
}
```

## What We Removed

- ❌ `referralClaims` collection - not needed, all data in `users` and `referralCodes`
- ❌ `referralPurchases` collection - not needed, all data in `users` and `referralCodes`

## What We Kept

- ✅ `users` collection - stores which referral code each user claimed
- ✅ `referralCodes` collection - stores sign-ups and purchases for compensation

## Collections You'll Have

1. **`referralCodes`** - One document per referral code with:
   - `usedBy` array - user IDs who signed up
   - `monthlyPurchasedBy` array - user IDs who purchased monthly
   - `annualPurchasedBy` array - user IDs who purchased annual
   - `lifetimePurchasedBy` array - user IDs who purchased lifetime
   - Counts = array lengths

2. **`users`** - One document per user with:
   - `referralCode` - which code they claimed
   - `referralCodeClaimedAt` - when they claimed it
   - `referralCodeUsedForPurchase` - whether they purchased
   - `referralPurchaseProductID` - which product they purchased

That's it! Simple and clean. 🎉

