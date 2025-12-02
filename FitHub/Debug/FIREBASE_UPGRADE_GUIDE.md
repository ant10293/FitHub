# Firebase iOS SDK Upgrade Guide

## Overview
This guide covers upgrading Firebase iOS SDK to resolve conflicts with GoogleSignIn-iOS. Your project uses the following Firebase modules:
- FirebaseCore
- FirebaseAuth
- FirebaseFirestore
- FirebaseFunctions
- FirebaseCrashlytics

## Current Setup
- Firebase is fully configured and working
- GoogleSignIn is conditionally imported (`#if canImport(GoogleSignIn)`)
- Using Swift Package Manager (no Podfile found)

## Upgrade Steps

### Step 1: Check Current Versions
1. Open your Xcode project
2. Go to **File → Packages → Show Package Dependencies** (or **File → Packages → Update to Latest Package Versions**)
3. Note the current Firebase version in the Package Dependencies panel

### Step 2: Update Firebase via Swift Package Manager

#### Option A: Update in Xcode (Recommended)
1. In Xcode, select your project in the navigator
2. Select your target
3. Go to the **Package Dependencies** tab
4. Find the Firebase package
5. Click the **Update to Latest Package Versions** button, OR
6. Right-click on Firebase → **Update Package**
7. Xcode will resolve dependencies automatically

#### Option B: Update Package.swift (if using Swift Package Manager)
If you have a `Package.swift` file, update the dependency:
```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0") // Update version
]
```

### Step 3: Verify GoogleSignIn Compatibility
After updating Firebase, ensure GoogleSignIn-iOS is compatible:
1. Check that GoogleSignIn-iOS version is compatible with the new Firebase version
2. Latest compatible versions (as of 2025):
   - Firebase iOS SDK: 11.0.0+ or 12.0.0+
   - GoogleSignIn-iOS: 7.0.0+ (should work with Firebase 11+)

### Step 4: Clean Build
1. In Xcode: **Product → Clean Build Folder** (Shift+Cmd+K)
2. Close Xcode
3. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
4. Reopen Xcode and rebuild

## Breaking Changes to Watch For

### 1. Minimum iOS Version
- **Firebase 11.0.0+**: Requires iOS 13.0+
- **Firebase 12.0.0+**: Requires iOS 15.0+
- **Action**: Verify your project's deployment target matches

### 2. Swift API Changes (Firebase 10.0+)
- Swift extension SDKs have been merged into main modules
- Your current imports should still work, but be aware:
  - `FirebaseAuth` → Still valid
  - `FirebaseFirestore` → Still valid
  - `FirebaseFunctions` → Still valid
  - `FirebaseCrashlytics` → Still valid

### 3. Dynamic Links (if used)
- **Firebase 12.0.0+**: Dynamic Links has been removed
- **Your project**: No Dynamic Links usage detected ✅

### 4. GoogleSignIn Integration
- Firebase Auth with Google Sign-In should work seamlessly
- Your conditional import (`#if canImport(GoogleSignIn)`) is correct
- No code changes needed for basic Google Sign-In integration

## Testing Checklist

After upgrading, test the following:

### Authentication
- [ ] Anonymous sign-in (`AuthService.signInAnonymously`)
- [ ] Apple Sign-In (`AuthService.signInWithApple`)
- [ ] Email/Password sign-in (`AuthService.signInWithEmail`)
- [ ] Email registration (`AuthService.registerWithEmail`)
- [ ] Sign out (`AuthService.signOut`)
- [ ] Account deletion (`AuthService.deleteCurrentAccount`)

### Firestore Operations
- [ ] Read operations (user data, referral codes)
- [ ] Write operations (user profile updates)
- [ ] Delete operations (referral code deletion)

### Cloud Functions
- [ ] Function calls from `ReferralPurchaseTracker`
- [ ] Function calls from `ReferralAttributor`
- [ ] Function calls from `EmailAuthView`

### Crashlytics
- [ ] Error logging (`CrashlyticsHelper.logError`)
- [ ] Custom keys (`CrashlyticsHelper.setUserID`, etc.)
- [ ] Non-fatal error recording (`CrashlyticsHelper.recordError`)

### Google Sign-In (if enabled)
- [ ] Google Sign-In flow (if implemented)
- [ ] Integration with Firebase Auth

## Troubleshooting

### Build Errors After Upgrade

#### "Module 'FirebaseX' not found"
- **Solution**: Clean build folder and rebuild
- Check that all Firebase modules are properly linked in target settings

#### "Duplicate symbol" errors
- **Solution**: Remove any duplicate Firebase imports
- Ensure you're not importing both `Firebase` and individual modules unnecessarily

#### GoogleSignIn conflicts
- **Solution**: Update GoogleSignIn-iOS to latest version
- Ensure both packages are using compatible dependency versions

### Runtime Errors

#### "FirebaseApp.configure() failed"
- **Solution**: Verify `GoogleService-Info.plist` is in the correct location
- Check that the file is added to your target's "Copy Bundle Resources"

#### Auth errors
- **Solution**: Verify Firebase project configuration
- Check that authentication methods are enabled in Firebase Console

## Rollback Plan

If issues occur, you can rollback:

1. In Xcode Package Dependencies, right-click Firebase
2. Select **Update Package** → **Up to Next Major Version**
3. Or manually specify a previous version
4. Clean and rebuild

## Recommended Versions (2025)

- **Firebase iOS SDK**: 11.0.0 or 12.0.0 (latest stable)
- **GoogleSignIn-iOS**: 7.0.0+ (compatible with Firebase 11+)

## Files That May Need Review

After upgrade, review these files for any deprecation warnings:
- `Classes/AuthService.swift` - Firebase Auth usage
- `Classes/CrashlyticsHelper.swift` - Crashlytics API
- `ReferralSystems/ReferralPurchaseTracker.swift` - Functions calls
- `ReferralSystems/ReferralAttributor.swift` - Functions calls
- `Views/Authentication/EmailAuthView.swift` - Functions calls

## Additional Resources

- [Firebase iOS Release Notes](https://firebase.google.com/support/release-notes/ios)
- [Firebase iOS Migration Guide](https://firebase.google.com/docs/ios/swift-migration)
- [GoogleSignIn-iOS Compatibility](https://github.com/google/GoogleSignIn-iOS)

## Notes

- Your current Firebase setup is well-structured with proper error handling
- The conditional GoogleSignIn import pattern is correct
- No major code changes should be required for basic upgrade
- Focus on testing authentication and Firestore operations after upgrade





































