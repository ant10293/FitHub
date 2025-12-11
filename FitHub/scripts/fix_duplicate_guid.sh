#!/bin/bash
# Fix for duplicate GUID error in Xcode workspace

set -e

echo "🔧 Fixing duplicate GUID error..."
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Step 1: Clean workspace user data
echo "1. Cleaning workspace user data..."
rm -rf FitHub.xcodeproj/project.xcworkspace/xcuserdata 2>/dev/null || true
echo "   ✓ Workspace user data cleaned"

# Step 2: Clean DerivedData
echo "2. Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/FitHub-* 2>/dev/null || true
echo "   ✓ DerivedData cleaned"

# Step 3: Remove SwiftPM cache (will be regenerated)
echo "3. Removing SwiftPM cache..."
rm -rf FitHub.xcodeproj/project.xcworkspace/xcshareddata/swiftpm 2>/dev/null || true
echo "   ✓ SwiftPM cache removed"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "1. Quit Xcode completely (Cmd+Q)"
echo "2. Reopen Xcode"
echo "3. Open the FitHub project"
echo "4. Xcode will regenerate the workspace state"
echo "5. File > Packages > Resolve Package Versions"
echo ""
echo "The duplicate GUID error should be resolved after Xcode rebuilds its internal state."
