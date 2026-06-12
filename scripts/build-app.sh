#!/bin/bash
# Builds SpeakPatch as a proper .app bundle so macOS can grant it
# Accessibility permission reliably (a bare SPM binary cannot be).
#
# Usage: ./scripts/build-app.sh [debug|release]   (default: release)

set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP="SpeakPatch.app"
BUNDLE_ID="com.speakpatch.app"
VERSION="${SPEAKPATCH_VERSION:-}"
BUILD_NUMBER="${SPEAKPATCH_BUILD:-}"

echo "==> Building ($CONFIG)..."
swift build -c "$CONFIG"

BIN=".build/$CONFIG/SpeakPatch"
if [[ ! -f "$BIN" ]]; then
    echo "Build product not found at $BIN" >&2
    exit 1
fi

echo "==> Assembling $APP..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/SpeakPatch"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

if [[ -n "$VERSION" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
fi

if [[ -n "$BUILD_NUMBER" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP/Contents/Info.plist"
fi

echo "==> Code signing (ad-hoc, stable identifier)..."
# A stable identifier keeps the Accessibility grant from being orphaned on
# every rebuild. Ad-hoc signing is fine for local/personal use.
codesign --force --sign - --identifier "$BUNDLE_ID" --timestamp=none "$APP"

echo "==> Done: $ROOT/$APP"
echo ""
echo "Next steps:"
echo "  1. open $APP            # launches the menu-bar app (look for 'SP')"
echo "  2. Open the SP menu → Grant Accessibility Permission → enable SpeakPatch"
echo "  3. Select text in any app → the quick toolbar should appear."
