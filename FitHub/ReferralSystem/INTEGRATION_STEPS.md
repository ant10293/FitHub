# Quick Integration Steps

## Step 1: Add Files to Xcode

1. Add `Views/Influencer/InfluencerRegistrationView.swift` to your project
2. Make sure `ReferralSystem/AdminScript_GenerateCodes.swift` is in your project
3. Make sure `ReferralSystem/ReferralCodeGenerator.swift` is in your project

## Step 2: Add to Menu (Recommended)

In `Views/MenuView.swift`, add a new section:

```swift
Section(header: Text("Partner")) {
    NavigationLink(destination: LazyDestination {
        InfluencerRegistrationView()
    }) {
        Label("Become an Influencer", systemImage: "person.2")
    }
}
```

Place it after the Premium section or wherever makes sense.

## Step 3: Update Firestore Security Rules

Go to Firebase Console → Firestore → Rules and update:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /referralCodes/{codeId} {
      // Allow anyone to read codes (to check if valid)
      allow read: if request.auth != null;
      // Allow authenticated users to create codes
      allow create: if request.auth != null;
      // Only admins can update/delete (via admin SDK)
      allow update, delete: if false;
    }
    match /referralClaims/{claimId} {
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null;
    }
  }
}
```

**OR** if you want to allow unauthenticated users (guests) to create codes:

```javascript
match /referralCodes/{codeId} {
  allow read: if true; // Public read
  allow create: if true; // Anyone can create
  allow update, delete: if false;
}
```

## Step 4: Test It

1. Build and run your app
2. Navigate to Menu → Become an Influencer
3. Enter test information
4. Generate a code
5. Verify it appears in Firestore

## Step 5: Share with Influencers

Send them instructions:

```
Hi [Name]!

Thanks for being a FitHub influencer! Here's how to get your referral code:

1. Download FitHub from the App Store
2. Open the app
3. Go to Menu (bottom tab bar) → Become an Influencer
4. Enter your full name and email (optional)
5. Tap "Generate My Referral Code"
6. Copy and share your code with your audience!

Your code will automatically track signups. Let me know if you need help!
```

## That's It!

Influencers can now generate their own codes. You can monitor them in Firestore.

