# Fixing dSYM Upload Issue

## Problem
dSYM files are being generated (Debug Information Format is correct) but not being uploaded automatically to Crashlytics.

## Solution Steps

### 1. Verify Build Script is Running

**Check the build log:**
1. Build your project (Product → Build or Archive)
2. Open the Report Navigator (⌘9 or View → Navigators → Reports)
3. Select your latest build
4. Search for "Crashlytics" or "dSYM" in the log
5. Look for any errors or warnings

**What to look for:**
- ✅ Good: "Uploading dSYM" or "Crashlytics" messages
- ❌ Bad: No mention of Crashlytics at all
- ❌ Bad: "Could not find run script" errors

### 2. Test the Script Path Manually

The script path might be incorrect. Try this more robust version in your Run Script phase:

```bash
# More robust script that handles different package locations
set -e

SCRIPT_PATH=""

# Try CocoaPods path first (if you ever used CocoaPods)
if [ -f "${PODS_ROOT}/FirebaseCrashlytics/run" ]; then
  SCRIPT_PATH="${PODS_ROOT}/FirebaseCrashlytics/run"
  echo "Found Crashlytics script at: ${SCRIPT_PATH}"
# Try Swift Package Manager path
elif [ -f "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run" ]; then
  SCRIPT_PATH="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
  echo "Found Crashlytics script at: ${SCRIPT_PATH}"
# Try alternative SPM path
elif [ -f "${SRCROOT}/../SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run" ]; then
  SCRIPT_PATH="${SRCROOT}/../SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
  echo "Found Crashlytics script at: ${SCRIPT_PATH}"
else
  echo "error: Firebase Crashlytics run script not found"
  echo "Searched in:"
  echo "  - ${PODS_ROOT}/FirebaseCrashlytics/run"
  echo "  - ${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
  echo "  - ${SRCROOT}/../SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
  exit 1
fi

# Run the script
"${SCRIPT_PATH}"
```

### 3. Check Script Phase Order

Make sure your Run Script phase is:
- ✅ **After** "Copy Bundle Resources"
- ✅ **Before** "Embed Frameworks" (if you have it)

### 4. Verify Input Files

Your Input Files should be:
- `$(BUILT_PRODUCTS_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist`
- `$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)`
- `$(BUILT_PRODUCTS_DIR)/$(EXECUTABLE_PATH)`

### 5. Check Script Options

In your Run Script phase:
- ✅ "Based on dependency analysis" should be **UNCHECKED**
- ✅ "Show environment variables in build log" can be checked (helps debug)

### 6. Manual Upload (Immediate Fix)

To process your current crashes right now:

**Find your dSYM:**
```bash
# For Debug builds:
~/Library/Developer/Xcode/DerivedData/FitHub-*/Build/Products/Debug-iphoneos/FitHub.app.dSYM

# For Archive builds:
# Right-click archive in Organizer → Show in Finder
# Navigate to: YourApp.xcarchive/dSYMs/FitHub.app.dSYM
```

**Upload via Firebase Console:**
1. Go to: https://console.firebase.google.com/project/fithubv1-d3c91/crashlytics/app/ios:com.AnthonyC.FitHub/symbols
2. Click "Upload dSYM files"
3. Drag and drop your `FitHub.app.dSYM` file
4. Wait 2-5 minutes for processing

**Or use Firebase CLI:**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Upload dSYM (replace path with your actual dSYM location)
firebase crashlytics:symbols:upload \
  --app=ios:com.AnthonyC.FitHub \
  ~/Library/Developer/Xcode/DerivedData/FitHub-*/Build/Products/Debug-iphoneos/FitHub.app.dSYM
```

### 7. Test with Archive Build

The script typically only uploads dSYMs for **Archive** builds:

1. Product → Archive
2. Wait for archive to complete
3. Check build log for "Uploading dSYM" messages
4. Don't distribute the archive yet - just let it upload

### 8. Verify GoogleService-Info.plist Location

The script needs to find `GoogleService-Info.plist`. Make sure:
- It's in your target's "Copy Bundle Resources" build phase
- It's in the `Firebase/` folder in your project
- The file is actually being copied to the app bundle

### 9. Check Build Log for Errors

After building, check for these specific errors:
- "Could not get GOOGLE_APP_ID" → GoogleService-Info.plist not found
- "Could not find run script" → Script path is wrong
- "Permission denied" → Script doesn't have execute permissions

### 10. Alternative: Use Firebase CLI in Script

If the automatic upload keeps failing, you can modify the script to use Firebase CLI:

```bash
# Check if Firebase CLI is available
if command -v firebase &> /dev/null; then
  # Find dSYM
  DSYM_PATH="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
  if [ -d "${DSYM_PATH}" ]; then
    echo "Uploading dSYM via Firebase CLI..."
    firebase crashlytics:symbols:upload --app=ios:com.AnthonyC.FitHub "${DSYM_PATH}"
  fi
else
  echo "Firebase CLI not found, using default script..."
  # Fall back to default script
  "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
fi
```

## Most Common Issues

1. **Script path wrong** → Use the robust script above
2. **Script not running on Debug builds** → Only runs on Archive (this is normal)
3. **GoogleService-Info.plist not found** → Check it's in Copy Bundle Resources
4. **Script phase order wrong** → Should be after Copy Bundle Resources

## Quick Test

1. Replace your script with the robust version above
2. Do an Archive build (Product → Archive)
3. Check the build log for "Found Crashlytics script" message
4. Look for upload confirmation

If you still see issues, the build log will tell you exactly what's wrong.


































































