#!/bin/bash
# Script to diagnose entitlements modification issues

echo "=== Entitlements File Diagnostics ==="
echo ""

ENTITLEMENTS_FILE="FitHub/FitHub.entitlements"

if [ ! -f "$ENTITLEMENTS_FILE" ]; then
    echo "❌ Entitlements file not found: $ENTITLEMENTS_FILE"
    exit 1
fi

echo "1. File Info:"
ls -la@ "$ENTITLEMENTS_FILE"
echo ""

echo "2. Extended Attributes:"
xattr -l "$ENTITLEMENTS_FILE" 2>&1
echo ""

echo "3. File Hash (before):"
md5 "$ENTITLEMENTS_FILE"
echo ""

echo "4. File Permissions:"
stat -f "%Sp %N" "$ENTITLEMENTS_FILE"
echo ""

echo "5. PLIST Validation:"
plutil -lint "$ENTITLEMENTS_FILE"
echo ""

echo "6. File Format Check:"
file "$ENTITLEMENTS_FILE"
echo ""

echo "7. Checking for file watchers/sync services..."
if [ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ]; then
    if [[ "$(pwd)" == *"iCloud"* ]] || [[ "$(pwd)" == *"Mobile Documents"* ]]; then
        echo "⚠️  WARNING: Project appears to be in iCloud Drive - this can cause file modification issues!"
    fi
fi

if command -v dropbox &> /dev/null; then
    echo "⚠️  Dropbox is installed - check if project folder is synced"
fi

echo ""
echo "8. Xcode Build Settings:"
cd "$(dirname "$(dirname "$ENTITLEMENTS_FILE")")"
if [ -f "FitHub.xcodeproj/project.pbxproj" ]; then
    echo "   CODE_SIGN_ENTITLEMENTS:"
    grep "CODE_SIGN_ENTITLEMENTS" FitHub.xcodeproj/project.pbxproj | head -2
    echo "   CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION:"
    grep "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION" FitHub.xcodeproj/project.pbxproj | head -2
    echo "   CODE_SIGN_INJECT_BASE_ENTITLEMENTS:"
    grep "CODE_SIGN_INJECT_BASE_ENTITLEMENTS" FitHub.xcodeproj/project.pbxproj | head -2
fi

echo ""
echo "=== Recommendations ==="
echo "If the error persists:"
echo "1. Clean DerivedData: rm -rf ~/Library/Developer/Xcode/DerivedData/FitHub-*"
echo "2. Clean build folder in Xcode: Product > Clean Build Folder (Shift+Cmd+K)"
echo "3. Remove extended attributes: xattr -c $ENTITLEMENTS_FILE"
echo "4. Check if project is in iCloud/Dropbox sync folder"
echo "5. Try disabling CODE_SIGN_INJECT_BASE_ENTITLEMENTS if enabled"

