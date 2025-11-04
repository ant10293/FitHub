# Quick Start Guide - Referral System Integration

## 🚀 Fastest Path to Implementation

### Step 1: Add Files to Your Project
1. Add `ReferralCodeGenerator.swift` to your Xcode project
2. Replace `Services/ReferralAttributor.swift` with the updated version from `ReferralAttributor_Updated.swift`
   - Make sure to import `FirebaseFirestore` if not already imported

### Step 2: Integrate Claim Call
Add this to your sign-in success handler (likely in `WelcomeView.swift`):

**Find this code:**
```swift
authService.signIn(with: result, into: userData) { res in
    switch res {
    case .success:
        handleNavigation()
    case .failure(let err):
        print("Sign-in failed:", err)
    }
}
```

**Update to:**
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

### Step 3: Create Firestore Collections

Go to Firebase Console → Firestore Database and create:

#### Collection: `referralCodes`
Add your first influencer code manually:

**Document ID:** `ANTHONY` (or your code)
**Fields:**
- `code` (string): `ANTHONY`
- `influencerName` (string): `Anthony Cantu`
- `influencerEmail` (string): `anthony@example.com` (optional)
- `notes` (string): `Main influencer` (optional)
- `isActive` (boolean): `true`
- `createdAt` (timestamp): `[current time]`
- `usageCount` (number): `0`
- `usedBy` (array): `[]`

### Step 4: Test It

1. Create a test URL: `fithub://r/ANTHONY` (or your App URL scheme)
2. Open the URL on your device
3. Sign in with a test account
4. Check Firestore:
   - `users/{userId}` should have `referralCode: "ANTHONY"`
   - `referralCodes/ANTHONY` should have `usageCount: 1`

## 📝 Adding More Influencer Codes

### Option 1: Use Programmatic Script (Recommended)
**Easiest way:** Use `AddReferralCodes.swift`

1. Open `AddReferralCodes.swift`
2. Edit the `influencers` array with your influencer names and emails:
   ```swift
   let influencers: [(name: String, email: String?, notes: String?)] = [
       ("Anthony Cantu", "anthony@example.com", "Main influencer"),
       ("John Doe", "john@example.com", "Fitness influencer"),
       // Add more...
   ]
   ```
3. Add this file to your Xcode project
4. Temporarily call it once in your app (e.g., in `FitHubApp.swift` or `AppContext.swift`):
   ```swift
   Task {
       await addAllReferralCodes()
   }
   ```
5. Run your app once - it will auto-generate codes from names
6. Remove the call after codes are created
7. Codes are automatically generated from names (e.g., "Anthony Cantu" → "ANTHONYC")

### Option 2: Firebase Console (Manual)
For quick one-off additions:
1. Go to Firestore → `referralCodes` collection
2. Click "Add document"
3. Document ID = code (e.g., "JOHN")
4. Add the same fields as above

## 🔒 Security Rules

Add to Firestore Rules (Firebase Console → Firestore → Rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /referralCodes/{codeId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /referralClaims/{claimId} {
      allow create: if request.auth != null && 
                       request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null;
    }
  }
}
```

## ✅ Verification Checklist

- [ ] `ReferralAttributor_Updated.swift` replaces `Services/ReferralAttributor.swift`
- [ ] `ReferralCodeGenerator.swift` added to project
- [ ] `claimIfNeeded()` called after successful sign-in
- [ ] Firestore collection `referralCodes` created
- [ ] At least one test code added to Firestore
- [ ] Security rules updated
- [ ] Tested with a referral URL and sign-in

## 🎯 That's It!

Your referral system is now active. Users who sign up with a referral code will have it tracked in Firebase.

