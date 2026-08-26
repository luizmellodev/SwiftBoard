#!/bin/bash
# Builds SwiftBoardiOSDemo for the iOS Simulator, hand-assembles a minimal .app bundle
# (SwiftPM alone can't produce an installable iOS app), and installs + launches it on a
# booted Simulator. Existing components render with real iOS chrome — not macOS's, which is
# what `swift run SwiftBoardKitDemo` would show instead.
#
# Usage: Scripts/run-ios-demo.sh [device-udid]
# If no UDID is given, uses the currently booted Simulator (there must be exactly one).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_ID="dev.luizmello.swiftboard.iosdemo"
PRODUCT="SwiftBoardiOSDemo"
MIN_OS="17.0"

DEVICE_ID="${1:-}"
if [ -z "$DEVICE_ID" ]; then
    DEVICE_ID=$(xcrun simctl list devices booted -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
booted = [d['udid'] for devices in data['devices'].values() for d in devices if d['state'] == 'Booted']
if len(booted) != 1:
    sys.exit('Expected exactly one booted Simulator, found ' + str(len(booted)) + '. Pass a UDID explicitly.')
print(booted[0])
")
fi

echo "Building for iOS Simulator..."
SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path)
cd "$ROOT_DIR"
swift build --sdk "$SDK_PATH" --triple arm64-apple-ios${MIN_OS}-simulator --product "$PRODUCT"

BUILD_DIR="$ROOT_DIR/.build/arm64-apple-ios-simulator/debug"
APP_DIR="$ROOT_DIR/.build/$PRODUCT.app"

echo "Assembling $PRODUCT.app..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
cp "$BUILD_DIR/$PRODUCT" "$APP_DIR/$PRODUCT"
cp -R "$BUILD_DIR/SwiftBoard_SwiftBoardServer.bundle" "$APP_DIR/"

cat > "$APP_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$PRODUCT</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$PRODUCT</string>
    <key>CFBundleDisplayName</key>
    <string>SwiftBoard</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneSimulator</string>
    </array>
    <key>DTPlatformName</key>
    <string>iphonesimulator</string>
    <key>MinimumOSVersion</key>
    <string>$MIN_OS</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
    </array>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP_DIR"

echo "Installing and launching on $DEVICE_ID..."
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$DEVICE_ID" "$APP_DIR"
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"

echo "Done. The website (rendered on-device) is also reachable at http://127.0.0.1:8080"
