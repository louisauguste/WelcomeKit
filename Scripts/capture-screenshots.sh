#!/usr/bin/env bash
#
# capture-screenshots.sh
#
# Rebuilds the demo app, drives it through the simulator with launch arguments
# and writes the images used in README.md. The demo reads its settings from
# UserDefaults, so every variant is one `simctl launch` away — no tapping.
#
# Usage: Scripts/capture-screenshots.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/Screenshots"
DERIVED="${TMPDIR:-/tmp}/WelcomeKitDemo-build"
BUNDLE_ID="com.welcomekit.WelcomeKitDemo"

PHONE_NAME="${PHONE_NAME:-iPhone 17}"
PAD_NAME="${PAD_NAME:-iPad Air 11-inch (M4)}"

mkdir -p "$OUT"

udid_for () { xcrun simctl list devices available | grep -F "$1 (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'; }

PHONE="$(udid_for "$PHONE_NAME")"
PAD="$(udid_for "$PAD_NAME")"
[ -n "$PHONE" ] || { echo "No simulator named $PHONE_NAME"; exit 1; }
[ -n "$PAD" ] || { echo "No simulator named $PAD_NAME"; exit 1; }

echo "Building the demo app…"
xcodebuild -project "$ROOT/Demo/WelcomeKitDemo.xcodeproj" \
    -scheme WelcomeKitDemo \
    -destination "platform=iOS Simulator,name=$PHONE_NAME" \
    -derivedDataPath "$DERIVED" \
    -quiet build
APP="$DERIVED/Build/Products/Debug-iphonesimulator/WelcomeKitDemo.app"

prepare () { # udid
    xcrun simctl boot "$1" 2>/dev/null || true
    xcrun simctl bootstatus "$1" -b >/dev/null 2>&1 || true
    xcrun simctl install "$1" "$APP"
    xcrun simctl status_bar "$1" override \
        --time "9:41" --batteryState charged --batteryLevel 100 \
        --cellularMode active --cellularBars 4 --operatorName "" \
        --dataNetwork wifi --wifiMode active --wifiBars 3
}

shoot () { # udid, name, appearance, extra launch args…
    local udid="$1" name="$2" appearance="$3"; shift 3
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl ui "$udid" appearance "$appearance" >/dev/null
    python3 -c "import time; time.sleep(1)"   # let the appearance switch land
    xcrun simctl launch "$udid" "$BUNDLE_ID" \
        -demo.autoPresent YES -WelcomeKit.hasSeen.demo YES "$@" >/dev/null
    python3 -c "import time; time.sleep(3.2)"   # let the reveal finish
    xcrun simctl io "$udid" screenshot "$OUT/$name.png" >/dev/null 2>&1
    echo "  $name.png"
}

echo "Capturing iPhone…"
prepare "$PHONE"
shoot "$PHONE" iphone-light light  -demo.tint blue   -demo.symbols monochrome   -demo.featureCount 5
shoot "$PHONE" iphone-dark  dark   -demo.tint indigo -demo.symbols hierarchical -demo.featureCount 5
shoot "$PHONE" iphone-pink  light  -demo.tint pink   -demo.symbols hierarchical -demo.featureCount 4 -demo.footnote YES

echo "Capturing iPad…"
prepare "$PAD"
shoot "$PAD" ipad-light light -demo.tint blue -demo.symbols monochrome -demo.featureCount 5

echo "Recording the reveal on iPhone…"
xcrun simctl terminate "$PHONE" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl ui "$PHONE" appearance light >/dev/null
xcrun simctl io "$PHONE" recordVideo --codec h264 --force "$OUT/reveal.mov" &
RECORDER=$!
python3 -c "import time; time.sleep(1.5)"
xcrun simctl launch "$PHONE" "$BUNDLE_ID" \
    -demo.autoPresent YES -WelcomeKit.hasSeen.demo YES \
    -demo.tint blue -demo.symbols monochrome -demo.featureCount 5 >/dev/null
python3 -c "import time; time.sleep(5)"
kill -INT $RECORDER
wait $RECORDER 2>/dev/null || true

# The recording opens on the home screen; the reveal itself starts once the
# sheet is up, about 2.6s in.
xcrun swift "$ROOT/Scripts/make-gif.swift" "$OUT/reveal.mov" "$OUT/reveal.gif" 300 15 2.62 2.9

echo "Capturing macOS…"
# `screencapture` needs a Screen Recording permission a fresh checkout will not
# have, so the demo app snapshots its own sheet instead — see WindowCapture.swift.
xcodebuild -project "$ROOT/Demo/WelcomeKitDemo.xcodeproj" \
    -scheme WelcomeKitDemo -destination "platform=macOS" \
    -derivedDataPath "$DERIVED-mac" -quiet build
MAC_BIN="$DERIVED-mac/Build/Products/Debug/WelcomeKitDemo.app/Contents/MacOS/WelcomeKitDemo"

mac_shoot () { # name, appearance, extra args…
    local name="$1" appearance="$2"; shift 2
    "$MAC_BIN" -demo.autoPresent YES -WelcomeKit.hasSeen.demo YES \
        -demo.appearance "$appearance" -demo.captureTo "$OUT/$name.png" "$@" >/dev/null 2>&1 &
    python3 -c "import time; time.sleep(9)"
    echo "  $name.png"
}

# Liquid Glass does not composite into a layer render, so the macOS shots use
# the flat prominent button — which is what the reference macOS sheet uses too.
mac_shoot macos-light light -demo.tint blue   -demo.symbols monochrome   -demo.button prominent -demo.featureCount 5
mac_shoot macos-dark  dark  -demo.tint indigo -demo.symbols hierarchical -demo.button prominent -demo.featureCount 5

echo "Done. Images are in $OUT"
