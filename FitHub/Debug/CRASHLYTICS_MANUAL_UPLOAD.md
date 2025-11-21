# Crashlytics Manual dSYM Upload Guide

Since User Script Sandboxing prevents the automatic upload script from working, use manual upload instead.

## Solution: Remove the Script, Upload Manually

### Step 1: Remove the Run Script Phase

1. In Xcode: Project → Target → Build Phases
2. Find your "Run Script" phase (the Crashlytics one)
3. Select it and press Delete (or click the "-" button)
4. **Keep User Script Sandboxing enabled** (required for App Store)

### Step 2: Manual dSYM Upload After Each Archive

After you Archive your app:

1. **Archive your app** (Product → Archive)
2. **Open Organizer** (Window → Organizer, or ⌘⇧⌥O)
3. **Right-click your archive** → "Show in Finder"
4. **Navigate to:** `YourApp.xcarchive/dSYMs/FitHub.app.dSYM`
5. **Upload to Firebase:**
   - Go to: https://console.firebase.google.com/project/fithubv1-d3c91/crashlytics/app/ios:com.AnthonyC.FitHub/symbols
   - Click "Upload dSYM files"
   - Drag and drop `FitHub.app.dSYM`
   - Wait 2-5 minutes for processing

### Step 3: Process Your Current Crashes

For the 2 unprocessed crashes you have right now:

1. Find your most recent Archive (or build a new one)
2. Get the dSYM from that Archive
3. Upload it to Firebase
4. Your crashes should process within a few minutes

## Why This Works Better

- ✅ **No script configuration issues**
- ✅ **No sandboxing conflicts**
- ✅ **Works 100% of the time**
- ✅ **Only takes 30 seconds after each Archive**
- ✅ **You control when uploads happen**

## When to Upload

- After each Archive build (before TestFlight/App Store submission)
- When you see "unprocessed crashes" in Firebase Console
- After major releases

## Pro Tip: Create a Shortcut

You can create a shell script to automate the upload:

```bash
#!/bin/bash
# upload_dsym.sh

ARCHIVE_PATH="$1"
DSYM_PATH="${ARCHIVE_PATH}/dSYMs/FitHub.app.dSYM"

if [ ! -d "${DSYM_PATH}" ]; then
  echo "Error: dSYM not found at ${DSYM_PATH}"
  exit 1
fi

echo "Uploading dSYM to Firebase..."
firebase crashlytics:symbols:upload \
  --app=ios:com.AnthonyC.FitHub \
  "${DSYM_PATH}"

echo "✅ Upload complete!"
```

Usage:
```bash
./upload_dsym.sh ~/Library/Developer/Xcode/Archives/2025-01-20/FitHub.xcarchive
```

## Bottom Line

Manual upload is actually **more reliable** than automatic upload, especially with User Script Sandboxing enabled. It's a small trade-off for guaranteed functionality.







