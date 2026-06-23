#!/bin/bash
# Build Keyboard Cleaner and package it into a distributable .dmg.
#
# The app is self-signed (not notarized), so on first launch each recipient
# must approve it once via System Settings › Privacy & Security › Open Anyway.
# A "Read Me First.txt" with those steps is included in the disk image.
#
# Note: the binary is arm64-only — it runs on Apple Silicon Macs (M1 and later).
set -euo pipefail

APP_NAME="Keyboard Cleaner"
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/$APP_NAME.app"
DMG="$ROOT/$APP_NAME.dmg"

# Build/refresh the signed .app bundle.
"$ROOT/build_app.sh" release

echo "▸ Staging disk image contents…"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

cat > "$STAGE/Read Me First.txt" <<'TXT'
Keyboard Cleaner — installation

1. Drag "Keyboard Cleaner" onto the Applications folder in this window.

2. First launch only — this takes a few clicks because the app isn't sold
   through the App Store (this is normal for free apps):
   • Double-click the app. macOS shows "Keyboard Cleaner.app Not Opened".
     Click "Done" — do NOT click "Move to Trash".
   • Open System Settings › Privacy & Security and scroll to the bottom.
   • Next to "Keyboard Cleaner.app was blocked…", click "Open Anyway".
   • Enter your password / Touch ID, then click "Open".
   After this one-time approval it opens normally every time.

3. The app will ask for Accessibility access — this is what lets it block
   the keyboard or trackpad while you clean. Click "Open System Settings",
   turn on the switch for Keyboard Cleaner, then click Continue.

That's it. Click a zone to lock it; unlock with the on-screen button
(keyboard mode) or the Escape key (trackpad mode).

Requires an Apple Silicon Mac (M1 or later) running macOS 13 or newer.
TXT

echo "▸ Creating $APP_NAME.dmg…"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "✓ Built: $DMG"
echo "  Share this file. Recipients drag the app to Applications and follow Read Me First."
