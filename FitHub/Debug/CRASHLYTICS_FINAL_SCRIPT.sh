#!/bin/bash
set -e

# The file IS found (your debug showed "File found at expected location")
# The "Operation not permitted" is just from ls, not from accessing the file
# So we can proceed with the Crashlytics script

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

# Verify GoogleService-Info.plist exists (silent check to avoid permission errors)
GOOGLE_SERVICE_PLIST="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"
if [ ! -f "${GOOGLE_SERVICE_PLIST}" ]; then
  # Try alternative location
  GOOGLE_SERVICE_PLIST="${BUILT_PRODUCTS_DIR}/GoogleService-Info.plist"
fi

if [ -f "${GOOGLE_SERVICE_PLIST}" ]; then
  echo "✅ GoogleService-Info.plist found, running Crashlytics script..."
  "${SCRIPT_PATH}"
else
  echo "⚠️ Warning: GoogleService-Info.plist not found, but continuing..."
  # Still try to run - the script might find it another way
  "${SCRIPT_PATH}" || echo "⚠️ Crashlytics script failed"
fi
























































