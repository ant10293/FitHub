# Firebase Crashlytics Setup Guide

✅ **Package Already Added** - Firebase Crashlytics is already included in your Firebase package.

## Step 1: Add Build Phase Script (REQUIRED - Most Important!)

Crashlytics requires a build script to upload debug symbols (dSYM files) for crash reports.

1. **Select your project** in Xcode navigator
2. **Select your target** (FitHub)
3. **Go to "Build Phases" tab**
4. **Click the "+" button** → **"New Run Script Phase"**
5. **Drag the new script phase** to be **AFTER** "Copy Bundle Resources" (this ensures GoogleService-Info.plist is already copied)
6. **Expand the script phase** and paste this script:

```bash
set -e

# Find and set GoogleService-Info.plist path for Crashlytics
# The script looks for it in the app bundle
GOOGLE_SERVICE_PLIST="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"

# For Archive builds, try alternative location
if [ ! -f "${GOOGLE_SERVICE_PLIST}" ]; then
  GOOGLE_SERVICE_PLIST="${BUILT_PRODUCTS_DIR}/GoogleService-Info.plist"
fi

# Export for Crashlytics script
if [ -f "${GOOGLE_SERVICE_PLIST}" ]; then
  export GOOGLE_SERVICE_PLIST_PATH="${GOOGLE_SERVICE_PLIST}"
  echo "✅ Found GoogleService-Info.plist at: ${GOOGLE_SERVICE_PLIST}"
else
  echo "⚠️ Warning: GoogleService-Info.plist not found at expected locations"
  echo "  Tried: ${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"
  echo "  Tried: ${BUILT_PRODUCTS_DIR}/GoogleService-Info.plist"
fi

# Find and run Crashlytics script
SCRIPT_PATH=""
if [ -f "${PODS_ROOT}/FirebaseCrashlytics/run" ]; then
  SCRIPT_PATH="${PODS_ROOT}/FirebaseCrashlytics/run"
elif [ -f "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run" ]; then
  SCRIPT_PATH="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
else
  echo "❌ error: Firebase Crashlytics run script not found"
  exit 1
fi

echo "✅ Running Crashlytics script: ${SCRIPT_PATH}"
"${SCRIPT_PATH}"
```

7. **Input Files - Finding the Correct Path:**
   
   The script needs Input Files, but the path depends on where your `.xcodeproj` file is located.
   
   **Option 1: If your .xcodeproj is in the same directory as Firebase folder:**
   - Input File: `$(SRCROOT)/Firebase/GoogleService-Info.plist`
   
   **Option 2: If your .xcodeproj is one level up (more common):**
   - Input File: `$(SRCROOT)/FitHub/Firebase/GoogleService-Info.plist`
   
   **How to find the correct path:**
   1. In Xcode, right-click on `GoogleService-Info.plist` in the Project Navigator
   2. Select "Show in Finder"
   3. Note the full path
   4. Compare it to where your `.xcodeproj` file is
   5. Use the relative path from `.xcodeproj` location
   
   **Alternative: Use the file reference directly**
   - Instead of a path, you can drag the `GoogleService-Info.plist` file from Xcode's Project Navigator directly into the Input Files section
   - Xcode will automatically use the correct path
   
   **Output Files:**
   ⚠️ **Leave Output Files EMPTY** - Do NOT add any output files. This causes "duplicate output file" errors.
   
   **To fix the warning about "no outputs":**
   - Uncheck "Based on dependency analysis" checkbox in the Run Script options
   - This tells Xcode it's okay to run the script every build (which is fine for Crashlytics)

**⚠️ IMPORTANT:** Without this build script, crash reports won't have readable stack traces. This is the most critical step!

## Step 2: Enable Crashlytics in Firebase Console

1. **Go to [Firebase Console](https://console.firebase.google.com)**
2. **Select your project** (`fithubv1-d3c91`)
3. **Navigate to:** Build → Crashlytics (in left sidebar)
4. **Click "Get started"** if you haven't enabled it yet
5. **Follow the setup wizard** (should be mostly done since you already have Firebase configured)

## Step 3: Test Crashlytics (Optional but Recommended)

Add a test crash button to verify it's working. You can add this temporarily to a debug view:

```swift
import FirebaseCrashlytics

// In a debug/settings view:
Button("Test Crash") {
    Crashlytics.crashlytics().log("Testing crash report")
    fatalError("Test crash for Crashlytics")
}
```

**⚠️ IMPORTANT:** Remove this before shipping to production!

## Step 4: Add Custom Logging (Recommended)

You can add custom logs and user information to crash reports:

### Custom Logs
```swift
import FirebaseCrashlytics

// Log important events
Crashlytics.crashlytics().log("User started workout")
Crashlytics.crashlytics().log("Subscription validation failed: \(error.localizedDescription)")
```

### User Identification
```swift
// In your AuthService after successful sign-in:
if let user = Auth.auth().currentUser {
    Crashlytics.crashlytics().setUserID(user.uid)
    Crashlytics.crashlytics().setCustomValue(user.email ?? "no-email", forKey: "user_email")
}
```

### Custom Keys
```swift
// Add context to crash reports
Crashlytics.crashlytics().setCustomValue(ctx.store.membershipType.rawValue, forKey: "membership_type")
Crashlytics.crashlytics().setCustomValue(ctx.userData.setup.setupState.rawValue, forKey: "setup_state")
```

## Step 5: Handle Non-Fatal Errors

You can record non-fatal errors that don't crash the app:

```swift
import FirebaseCrashlytics

do {
    // Some operation that might fail
    try someRiskyOperation()
} catch {
    // Record error without crashing
    Crashlytics.crashlytics().record(error: error)
    
    // Or with custom context
    let nsError = error as NSError
    Crashlytics.crashlytics().record(
        error: nsError,
        userInfo: [
            "operation": "subscription_validation",
            "user_id": AuthService.getUid() ?? "unknown"
        ]
    )
}
```

## Integration Points for FitHub

### 1. AuthService - User Identification
Add to `AuthService.swift` after successful sign-in:

```swift
import FirebaseCrashlytics

// In signInWithApple, signInWithEmail, etc. after successful auth:
if let user = Auth.auth().currentUser {
    Crashlytics.crashlytics().setUserID(user.uid)
}
```

### 2. PremiumStore - Subscription Errors
Add to `PremiumStore.swift` in error handling:

```swift
import FirebaseCrashlytics

// In refreshEntitlementWithRetryInternal catch block:
catch {
    Crashlytics.crashlytics().log("Entitlement refresh failed: \(error.localizedDescription)")
    Crashlytics.crashlytics().setCustomValue(membershipType.rawValue, forKey: "last_known_membership")
    // ... existing error handling
}
```

### 3. AppContext - Setup State
Add to `AppContext.swift`:

```swift
import FirebaseCrashlytics

// In init() or after data loads:
Crashlytics.crashlytics().setCustomValue(userData.setup.setupState.rawValue, forKey: "setup_state")
Crashlytics.crashlytics().setCustomValue(store.membershipType.rawValue, forKey: "membership_type")
```

## Verification

1. **Build and run** your app
2. **Trigger a test crash** (if you added the test button)
3. **Wait 5-10 minutes** for the crash report to appear in Firebase Console
4. **Check Firebase Console → Crashlytics** to see the crash report

## Troubleshooting

### Script Not Found Error
- Make sure the build script path is correct
- Check that FirebaseCrashlytics package is properly added
- Try the alternative script path provided above

### No Crash Reports Appearing
- Make sure you're running a **Release** or **Archive** build (Debug builds may not upload)
- Check that `GoogleService-Info.plist` is in your target
- Verify the build script is running (check build log)
- Wait 10-15 minutes for reports to appear

### dSYM Upload Issues - "Unprocessed Crashes" Error

If you see "This app has X unprocessed crashes. Upload dSYM file to process them" in Firebase Console:

**1. Check dSYM Generation Settings:**
   - In Xcode: Project → Target → Build Settings
   - Search for "Debug Information Format"
   - Make sure it's set to **"DWARF with dSYM File"** (not just "DWARF")
   - This should be set for both Debug and Release configurations

**2. Verify Build Script is Running:**
   - Build your project
   - Check the build log (View → Navigators → Reports, then select your latest build)
   - Look for "Uploading dSYM" or "Crashlytics" messages
   - If you don't see these, the script isn't running

**3. Manual dSYM Upload (Temporary Fix):**

   If the automatic upload isn't working, you can upload manually:

   **Option A: Using Firebase CLI (Recommended)**
   ```bash
   # Install Firebase CLI if you haven't
   npm install -g firebase-tools
   
   # Login
   firebase login
   
   # Navigate to your project
   cd /Users/anthonycantu/Desktop/iOS/FitHub/FitHub
   
   # Find your dSYM file (usually in DerivedData)
   # Path format: ~/Library/Developer/Xcode/DerivedData/FitHub-*/Build/Products/Debug-iphoneos/FitHub.app.dSYM
   
   # Upload dSYM
   firebase crashlytics:symbols:upload --app=ios:com.AnthonyC.FitHub /path/to/FitHub.app.dSYM
   ```

   **Option B: Using Xcode Organizer**
   - Archive your app (Product → Archive)
   - Open Organizer (Window → Organizer)
   - Right-click on your archive → "Show in Finder"
   - Navigate to: `YourApp.xcarchive/dSYMs/`
   - Find `FitHub.app.dSYM`
   - Use Firebase Console to upload: [Firebase Console → Crashlytics → dSYM Files](https://console.firebase.google.com/project/fithubv1-d3c91/crashlytics/app/ios:com.AnthonyC.FitHub/symbols)

**4. Fix Build Script Path:**
   
   If the script path is wrong, try this more robust version:
   ```bash
   # Find the script automatically
   SCRIPT_PATH=""
   if [ -f "${PODS_ROOT}/FirebaseCrashlytics/run" ]; then
     SCRIPT_PATH="${PODS_ROOT}/FirebaseCrashlytics/run"
   elif [ -f "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run" ]; then
     SCRIPT_PATH="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
   else
     echo "error: Firebase Crashlytics run script not found"
     exit 1
   fi
   
   "${SCRIPT_PATH}"
   ```

**5. Check Build Script Execution:**
   - Make sure the script phase is **after** "Copy Bundle Resources"
   - Verify "Based on dependency analysis" is **unchecked** (so it runs every build)
   - Check that the script has proper permissions (should be automatic)

**6. For Archive Builds:**
   - dSYM upload typically only happens for **Archive** builds, not regular Debug builds
   - Try: Product → Archive
   - After archiving, the script should automatically upload dSYM files
   - Check the archive build log for upload confirmation

## Best Practices

1. **Don't log sensitive data** (passwords, tokens, etc.)
2. **Use custom keys** to add context without logging sensitive info
3. **Set user ID** after authentication for better crash tracking
4. **Log important state changes** (subscription changes, setup completion, etc.)
5. **Record non-fatal errors** for operations that fail but don't crash

## Next Steps

After setup, consider:
- Adding Crashlytics logging to critical error paths
- Setting up alerts in Firebase Console for new crashes
- Reviewing crash reports regularly before releases
- Adding user identification after sign-in flows

