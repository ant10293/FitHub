#!/bin/bash
# Comprehensive fix for "entitlements were modified during the build" error

set -e

echo "🔧 Fixing entitlements modification issue..."
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

ENTITLEMENTS_FILE="FitHub/FitHub.entitlements"

# Step 1: Remove all extended attributes
echo "1. Removing extended attributes..."
xattr -c "$ENTITLEMENTS_FILE" 2>/dev/null || true
echo "   ✓ Extended attributes removed"

# Step 2: Normalize the plist file
echo "2. Normalizing plist format..."
plutil -convert binary1 "$ENTITLEMENTS_FILE" 2>/dev/null || true
plutil -convert xml1 "$ENTITLEMENTS_FILE" 2>/dev/null || true
echo "   ✓ File normalized"

# Step 3: Ensure proper permissions
echo "3. Setting file permissions..."
chmod 644 "$ENTITLEMENTS_FILE"
echo "   ✓ Permissions set"

# Step 4: Clean DerivedData (but preserve SourcePackages to avoid breaking SPM)
echo "4. Cleaning DerivedData (preserving SourcePackages)..."
DERIVED_DATA_DIRS=$(find ~/Library/Developer/Xcode/DerivedData -name "FitHub-*" -type d -maxdepth 1 2>/dev/null || true)
if [ -n "$DERIVED_DATA_DIRS" ]; then
    echo "$DERIVED_DATA_DIRS" | while read -r dir; do
        if [ -d "$dir" ]; then
            # Remove everything except SourcePackages
            find "$dir" -mindepth 1 -maxdepth 1 ! -name "SourcePackages" -exec rm -rf {} + 2>/dev/null || true
            echo "   Cleaned: $dir (preserved SourcePackages)"
        fi
    done
    echo "   ✓ DerivedData cleaned (SourcePackages preserved)"
else
    echo "   ℹ️  No DerivedData found to clean"
fi

# Step 5: Verify file
echo "5. Verifying entitlements file..."
if plutil -lint "$ENTITLEMENTS_FILE" > /dev/null 2>&1; then
    echo "   ✓ File is valid"
else
    echo "   ❌ File validation failed!"
    exit 1
fi

echo ""
echo "✅ Fix complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Product > Clean Build Folder (Shift+Cmd+K)"
echo "3. Try building again"
echo ""
echo "If the issue persists, try:"
echo "- Disable CODE_SIGN_INJECT_BASE_ENTITLEMENTS in Build Settings"
echo "- Check if project folder is synced with iCloud/Dropbox"
echo "- Restart Xcode"

