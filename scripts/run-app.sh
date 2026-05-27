#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="ScreenSwap"
BUILD_DIR="$ROOT_DIR/.build/debug"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"
swift build

mkdir -p "$MACOS_DIR"

if [[ ! -f "$MACOS_DIR/$APP_NAME" ]] || ! cmp -s "$BUILD_DIR/ScreenSwapApp" "$MACOS_DIR/$APP_NAME"; then
    cp "$BUILD_DIR/ScreenSwapApp" "$MACOS_DIR/$APP_NAME"
fi

if [[ ! -f "$CONTENTS_DIR/Info.plist" ]]; then
    cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>local.screen-swap.prototype</string>
    <key>CFBundleName</key>
    <string>Screen Swap</string>
    <key>CFBundleDisplayName</key>
    <string>Screen Swap</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST
fi

open "$APP_BUNDLE"
