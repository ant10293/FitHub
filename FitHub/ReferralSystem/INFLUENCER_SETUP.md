# Influencer Self-Service Setup Guide

This guide explains how to set up the influencer self-service system where influencers can generate their own referral codes within the app.

## Overview

Instead of manually creating codes, influencers can:
1. Download the app
2. Navigate to the Influencer Registration view
3. Enter their information
4. Generate their own referral code automatically
5. Share the code with their audience

## Setup Steps

### Step 1: Add the Influencer View to Your App

The `InfluencerRegistrationView.swift` file has been created. You need to add it to your Xcode project and make it accessible.

### Step 2: Add Navigation to the View

You have several options for how influencers can access this view:

#### Option A: Add to Menu (Recommended)
Add a menu item in `MenuView.swift`:

```swift
Section(header: Text("Partner")) {
    NavigationLink(destination: LazyDestination {
        InfluencerRegistrationView()
    }) {
        Label("Become an Influencer", systemImage: "person.2")
    }
}
```

#### Option B: Add to Settings
Add it to your `SettingsView.swift` if you have one.

#### Option C: Special URL Scheme / Deep Link
Create a special deep link for influencers:

1. Update `ReferralURLHandler.swift` to handle influencer registration:
```swift
// In ReferralURLHandler.swift, add:
static func handleInfluencerRegistration(_ url: URL) -> Bool {
    if url.pathComponents.contains("influencer") || 
       url.queryItems?.contains(where: { $0.name == "influencer" }) == true {
        // Store flag to show influencer view
        UserDefaults.standard.set(true, forKey: "showInfluencerRegistration")
        return true
    }
    return false
}
```

2. In your app initialization, check for this flag and show the view:
```swift
if UserDefaults.standard.bool(forKey: "showInfluencerRegistration") {
    // Present InfluencerRegistrationView
    UserDefaults.standard.removeObject(forKey: "showInfluencerRegistration")
}
```

### Step 3: Update Firestore Security Rules

Allow authenticated (or even unauthenticated) users to create referral codes:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /referralCodes/{codeId} {
      // Anyone can read codes (to check if valid)
      allow read: if request.auth != null;
      
      // Allow users to create their own codes
      allow create: if request.auth != null && 
                       request.resource.data.createdBy == request.auth.uid;
      
      // Only admins can update/delete (via admin SDK)
      allow update, delete: if false;
    }
  }
}
```

**OR** if you want to allow unauthenticated users to create codes (for influencers who haven't signed in):

```javascript
match /referralCodes/{codeId} {
  allow read: if true; // Public read
  allow create: if true; // Anyone can create
  allow update, delete: if false; // Only admins
}
```

### Step 4: Test the Flow

1. Open the app
2. Navigate to Influencer Registration (via menu or deep link)
3. Enter influencer information
4. Generate a code
5. Verify it appears in Firestore

## How to Share with Influencers

### Option 1: Direct App Link + Instructions
When reaching out to influencers, provide:

```
Hi [Name],

I'd love to have you as a FitHub influencer! Here's how to get your referral code:

1. Download FitHub: [App Store Link]
2. Open the app
3. Go to Menu → Become an Influencer
4. Enter your name and email
5. Tap "Generate My Referral Code"
6. Share your code with your audience!

Your code will automatically track signups from your audience.

Let me know if you have any questions!
```

### Option 2: Special Deep Link
Create a special link that opens the influencer registration directly:

```
fithub://influencer
or
https://yourdomain.com/influencer
```

### Option 3: QR Code
Generate a QR code that links to the App Store + instructions, or uses a deep link.

## Features

✅ **Auto-generates codes from names** - "John Doe" → "JOHNDOE"  
✅ **Handles duplicates** - Automatically retries if code exists  
✅ **Shows code immediately** - Influencer can copy/share right away  
✅ **Tracks creator** - Stores who created the code in Firestore  
✅ **Works with or without authentication** - Can allow guest users  

## Security Considerations

1. **Prevent Abuse:**
   - Consider rate limiting (max 1 code per user/email)
   - Add captcha if needed
   - Monitor for suspicious activity

2. **Code Validation:**
   - Codes are automatically validated (A-Z, 0-9, 4-10 chars)
   - Duplicate checking prevents conflicts

3. **Admin Controls:**
   - You can deactivate codes via Firebase Console
   - Monitor usage in Firestore
   - Track who created each code

## Monitoring

Check Firestore to see:
- All created codes in `referralCodes` collection
- Who created each code (`createdBy` field)
- Usage statistics (`usageCount`, `usedBy` array)

## Future Enhancements

- Add influencer dashboard to view stats
- Send email notifications when code is used
- Add code expiration dates
- Require admin approval before activation
- Add influencer verification/authentication

