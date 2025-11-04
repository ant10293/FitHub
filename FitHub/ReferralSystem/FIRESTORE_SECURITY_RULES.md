# Firestore Security Rules - Copy & Paste

## Step 1: Go to Firebase Console
1. Open Firebase Console
2. Select your project
3. Click **Firestore Database** in left sidebar
4. Click **Rules** tab at the top

## Step 2: Replace the Rules

Copy and paste this entire block:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only read/write their own user document
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Anyone authenticated can read referral codes (to check if valid)
    // Only authenticated users can create codes (for influencer self-service)
    match /referralCodes/{codeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if false; // Only admins can update/delete
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

## Step 3: Publish
1. Click **Publish** button
2. Rules will be active immediately

## What These Rules Do

- **`referralCodes`**: Authenticated users can read (to validate codes) and create (for influencer self-service)
- **`users`**: Users can only access their own document
- **`referralClaims`**: Users can create their own claim records
- **`referralPurchases`**: Users can create their own purchase records

## Testing

After updating rules, try your app again. The permission error should be resolved.

