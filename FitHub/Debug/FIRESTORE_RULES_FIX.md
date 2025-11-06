# Firestore Security Rules - Updated for Referral System

## Quick Fix

Go to Firebase Console → Firestore Database → Rules tab and replace with this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own user document
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Referral codes - allow read and update (for adding users to usedBy array)
    match /referralCodes/{codeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      // Allow update so users can add themselves to usedBy array
      allow update: if request.auth != null && 
                       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['usedBy', 'lastUsedAt']);
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

## What Changed

The key fix is allowing **updates** to `referralCodes` but only for specific fields:
- `usedBy` - so users can add themselves when claiming a code
- `lastUsedAt` - timestamp when code was used

This prevents users from modifying other fields like `influencerName` or `isActive`.

## Step-by-Step

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project (`fithubv1-d3c91`)
3. Click **Firestore Database** in left sidebar
4. Click **Rules** tab at the top
5. Delete all existing rules
6. Paste the rules above
7. Click **Publish**
8. Rules are active immediately

## Testing

After updating rules:
1. Try signing in again
2. Check Xcode console for `✅ Successfully claimed referral code`
3. Verify in Firestore:
   - `users/{userId}` has `referralCode` field
   - `referralCodes/{code}` has user ID in `usedBy` array
   - `referralClaims` collection has a new document

