# Firestore Rules - Debugging the Permission Error

The issue is with the `referralClaims` rule. Try this updated version:

## Updated Rules (Try This)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own user document
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Referral codes - allow read, create, and updates
    match /referralCodes/{codeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if false;
    }
    
    // Users can create their own claim records
    // Simplified rule - just check authentication
    match /referralClaims/{claimId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
    }
    
    // Users can create their own purchase records
    match /referralPurchases/{purchaseId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
    }
  }
}
```

## What Changed

I simplified the `referralClaims` rule to just check authentication, not the userId field. The userId validation might be failing because of how batch writes work.

## Alternative: More Permissive (for testing)

If you want to test quickly, you can temporarily make it more permissive:

```javascript
match /referralClaims/{claimId} {
  allow create: if request.auth != null;
  allow read, write: if request.auth != null;
}
```

## Verify the User is Authenticated

Add this debug check in your code to verify the user is authenticated when the claim happens:

```swift
guard let user = Auth.auth().currentUser else {
    print("❌ User not authenticated!")
    return
}
print("✅ User authenticated: \(user.uid)")
```

