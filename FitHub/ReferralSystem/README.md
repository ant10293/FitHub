# Influencer Referral System Setup Guide

This guide will help you set up an influencer referral system for your FitHub app using Firebase.

## Overview

The system tracks which influencer referral code a user signed up with by:
1. Capturing referral codes from URLs (already implemented in `ReferralURLHandler.swift`)
2. Storing the code temporarily in UserDefaults
3. Claiming the code in Firestore after successful authentication
4. Tracking referral statistics in Firebase

## Firestore Database Structure

You'll need to create the following collections in Firestore:

### 1. `referralCodes` Collection
Each document represents a referral code for an influencer:

```
referralCodes/
  {CODE}/
    - code: string (e.g., "ANTHONY")
    - influencerName: string (e.g., "Anthony Cantu")
    - influencerEmail: string (optional)
    - notes: string (optional)
    - isActive: boolean (default: true)
    - createdAt: timestamp
    - usageCount: number (starts at 0)
    - usedBy: array of user IDs
    - lastUsedAt: timestamp (optional)
```

### 2. `users` Collection
Each user document will store their referral information:

```
users/
  {userId}/
    - referralCode: string (the code they used)
    - referralCodeClaimedAt: timestamp
    - referralSource: string (e.g., "universal_link", "manual")
    - claimedReferralCodes: array of strings (for tracking)
    - ... (your other user fields)
```

### 3. `referralClaims` Collection (Optional - for analytics)
Each document tracks a referral claim event:

```
referralClaims/
  {claimId}/
    - code: string
    - userId: string
    - source: string
    - claimedAt: timestamp
    - influencerName: string
```

## Setup Instructions

### Step 1: Update ReferralAttributor

Replace your existing `ReferralAttributor.swift` with the code from `ReferralAttributor_Updated.swift`.

**Important:** Make sure you import FirebaseFirestore:
```swift
import FirebaseFirestore
```

### Step 2: Add ReferralCodeGenerator

Add the `ReferralCodeGenerator.swift` file to your project. This utility helps generate and validate codes.

### Step 3: Call claimIfNeeded After Sign-In

In your `AuthService.swift` or wherever you handle successful authentication, call the referral attributor:

```swift
// After successful sign-in in AuthService.signIn
Auth.auth().signIn(with: credential) { (authResult, error) in
    // ... your existing code ...
    
    // After setting userData.profile.userId
    Task {
        await ReferralAttributor().claimIfNeeded(source: "sign_in")
    }
    
    completion(.success(()))
}
```

Or in your `WelcomeView.swift` after successful sign-in:

```swift
authService.signIn(with: result, into: userData) { res in
    switch res {
    case .success:
        Task {
            await ReferralAttributor().claimIfNeeded(source: "sign_in")
        }
        handleNavigation()
    case .failure(let err):
        print("Sign-in failed:", err)
    }
}
```

### Step 4: Create Referral Codes in Firestore

You have two options:

#### Option A: Manual Creation via Firebase Console
1. Go to Firebase Console → Firestore Database
2. Create a collection called `referralCodes`
3. Add a document with ID = your code (e.g., "ANTHONY")
4. Add the following fields:
   - `code`: "ANTHONY" (string)
   - `influencerName`: "Anthony Cantu" (string)
   - `influencerEmail`: "anthony@example.com" (string, optional)
   - `notes`: "Main influencer" (string, optional)
   - `isActive`: true (boolean)
   - `createdAt`: [Current timestamp] (timestamp)
   - `usageCount`: 0 (number)
   - `usedBy`: [] (array)

#### Option B: Use Admin Script
1. Create a simple Swift script or add a function to your admin dashboard
2. Use the `ReferralCodeAdmin` class from `AdminScript_GenerateCodes.swift`
3. Example:
```swift
let admin = ReferralCodeAdmin()
try await admin.createReferralCode(
    code: "ANTHONY",
    influencerName: "Anthony Cantu",
    influencerEmail: "anthony@example.com"
)
```

### Step 5: Set Up Firestore Security Rules

Add these rules to secure your Firestore database:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only read/write their own user document
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Anyone can read referral codes (to check if valid)
    // Only admins can write
    match /referralCodes/{codeId} {
      allow read: if request.auth != null;
      allow write: if false; // Only via admin SDK or cloud functions
    }
    
    // Users can create their own claim records
    match /referralClaims/{claimId} {
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null;
    }
  }
}
```

### Step 6: (Optional) Set Up Cloud Functions

If you prefer server-side validation, deploy the cloud function from `CloudFunction_claimReferral.js`:

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize functions: `firebase init functions`
4. Copy the function code to `functions/index.js`
5. Deploy: `firebase deploy --only functions`

Then keep your original `ReferralAttributor.swift` that calls the cloud function.

## Testing

1. **Test URL Parsing:**
   - Open your app with a URL like: `fithub://r/ANTHONY` or `https://yourdomain.com/r/ANTHONY`
   - Verify the code is stored in UserDefaults

2. **Test Code Claiming:**
   - Sign in with a test account
   - Check Firestore to verify:
     - User document has `referralCode` field
     - Referral code document has incremented `usageCount`
     - A claim record exists in `referralClaims`

3. **Test Invalid Codes:**
   - Try signing in with a non-existent code
   - Verify it fails gracefully

## Analytics Queries

Once set up, you can query referral data:

```swift
// Get all users who used a specific code
let usersSnapshot = try await db.collection("users")
    .whereField("referralCode", isEqualTo: "ANTHONY")
    .getDocuments()

// Get usage stats for a code
let codeDoc = try await db.collection("referralCodes")
    .document("ANTHONY")
    .getDocument()
let usageCount = codeDoc.data()?["usageCount"] as? Int ?? 0

// Get top influencers
let codesSnapshot = try await db.collection("referralCodes")
    .order(by: "usageCount", descending: true)
    .limit(to: 10)
    .getDocuments()
```

## Important Notes

1. **Code Format:** Codes are automatically uppercased and sanitized (A-Z, 0-9 only)
2. **Idempotency:** The system prevents users from claiming multiple codes or claiming the same code twice
3. **First Code Wins:** If a user already has a referral code, new claims are ignored
4. **User Document:** Make sure your user documents are created in Firestore. The code assumes they exist or will create them on first claim.

## Troubleshooting

- **Code not being claimed:** Check that `claimIfNeeded()` is called after authentication
- **Code not found:** Verify the code exists in Firestore with correct casing
- **Permission errors:** Check Firestore security rules
- **Duplicate claims:** The system should prevent this, but verify the logic

## Next Steps

1. Set up analytics dashboard to track referral performance
2. Consider adding rewards/commission logic for influencers
3. Add referral code validation UI in your app
4. Set up email notifications when codes are used

