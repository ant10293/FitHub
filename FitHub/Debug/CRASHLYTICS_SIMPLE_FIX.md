# Simple Crashlytics Fix - Manual dSYM Upload

Since the automatic upload script is causing issues, here's a simpler approach:

## Option 1: Skip Automatic Upload, Upload Manually (Recommended for Now)

The automatic upload is nice-to-have, but you can upload dSYM files manually after each Archive:

1. **Archive your app** (Product → Archive)
2. **Open Organizer** (Window → Organizer)
3. **Right-click your archive** → "Show in Finder"
4. **Navigate to:** `YourApp.xcarchive/dSYMs/FitHub.app.dSYM`
5. **Upload to Firebase:**
   - Go to: https://console.firebase.google.com/project/fithubv1-d3c91/crashlytics/app/ios:com.AnthonyC.FitHub/symbols
   - Click "Upload dSYM files"
   - Drag and drop the dSYM file

This works perfectly and avoids all the script issues.

## Option 2: Fix the Script - Use Environment Variable

The Crashlytics script might need the file path set differently. Try this script:

```bash
set -e

# Set the GoogleService-Info.plist path for Crashlytics
# The script looks in the app bundle
export GOOGLE_SERVICE_PLIST="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"

# If not found, try root of bundle
if [ ! -f "${GOOGLE_SERVICE_PLIST}" ]; then
  export GOOGLE_SERVICE_PLIST="${BUILT_PRODUCTS_DIR}/GoogleService-Info.plist"
fi

# Debug output
echo "Looking for GoogleService-Info.plist at: ${GOOGLE_SERVICE_PLIST}"
if [ -f "${GOOGLE_SERVICE_PLIST}" ]; then
  echo "✅ Found GoogleService-Info.plist"
else
  echo "❌ GoogleService-Info.plist NOT FOUND"
  echo "Checking bundle contents:"
  ls -la "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/" || true
fi

# Find Crashlytics script
SCRIPT_PATH=""
if [ -f "${PODS_ROOT}/FirebaseCrashlytics/run" ]; then
  SCRIPT_PATH="${PODS_ROOT}/FirebaseCrashlytics/run"
elif [ -f "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run" ]; then
  SCRIPT_PATH="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
else
  echo "❌ Crashlytics script not found"
  exit 1
fi

# Run with explicit path
"${SCRIPT_PATH}"
```

## Option 3: Check Script Phase Order

Make absolutely sure:
1. **"Copy Bundle Resources"** comes BEFORE your "Run Script" phase
2. Drag the Run Script phase to be AFTER Copy Bundle Resources
3. The script needs the file to already be in the bundle

## Option 4: Debug Script - See What's Actually Happening

Replace your current script with this debug version to see what's wrong:

```bash
set -e

echo "=== Crashlytics Debug Info ==="
echo "BUILT_PRODUCTS_DIR: ${BUILT_PRODUCTS_DIR}"
echo "UNLOCALIZED_RESOURCES_FOLDER_PATH: ${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
echo ""

# Check if bundle exists
if [ -d "${BUILT_PRODUCTS_DIR}" ]; then
  echo "✅ BUILT_PRODUCTS_DIR exists"
  echo "Contents:"
  ls -la "${BUILT_PRODUCTS_DIR}" | head -10
else
  echo "❌ BUILT_PRODUCTS_DIR does NOT exist"
fi

echo ""
echo "Searching for GoogleService-Info.plist:"
find "${BUILT_PRODUCTS_DIR}" -name "GoogleService-Info.plist" 2>/dev/null || echo "NOT FOUND in bundle"

echo ""
echo "Expected location: ${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"
if [ -f "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist" ]; then
  echo "✅ File found at expected location"
else
  echo "❌ File NOT at expected location"
fi

echo ""
echo "=== End Debug ==="

# Try to run Crashlytics script anyway
SCRIPT_PATH=""
if [ -f "${PODS_ROOT}/FirebaseCrashlytics/run" ]; then
  SCRIPT_PATH="${PODS_ROOT}/FirebaseCrashlytics/run"
elif [ -f "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run" ]; then
  SCRIPT_PATH="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
fi

if [ -n "${SCRIPT_PATH}" ]; then
  echo "Running Crashlytics script: ${SCRIPT_PATH}"
  "${SCRIPT_PATH}"
else
  echo "❌ Crashlytics script not found"
  exit 1
fi
```

**Run this and check the build log** - it will tell you exactly where the file is (or isn't).

## My Recommendation

For now, **use Option 1 (manual upload)**. It's:
- ✅ Guaranteed to work
- ✅ No script configuration issues
- ✅ Only takes 30 seconds after each Archive
- ✅ You can fix the automatic upload later

The automatic upload is convenient but not critical - manual upload works just as well.

