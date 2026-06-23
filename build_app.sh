#!/bin/bash
# Build Keyboard Cleaner and assemble a signed .app bundle.
#
# The app is signed with a stable, self-signed code-signing certificate
# ("Keyboard Cleaner Dev"), created automatically on first run. This matters:
# macOS Accessibility keys the granted permission to the code signature. An
# ad-hoc signature changes on every rebuild, so the grant would be lost each
# time and System Settings would accumulate stale, stuck entries. A stable
# cert means you grant access once and it survives every future rebuild.
set -euo pipefail

CONFIG="${1:-release}"
APP_NAME="Keyboard Cleaner"
BUNDLE_ID="com.example.keyboardcleaner"
EXECUTABLE="KeyboardCleaner"
SIGN_ID="Keyboard Cleaner Dev"

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/$APP_NAME.app"
CONTENTS="$APP/Contents"

# Ensure a stable self-signed code-signing identity exists in the login keychain.
ensure_signing_identity() {
    if security find-identity -p codesigning 2>/dev/null | grep -q "$SIGN_ID"; then
        return
    fi
    echo "▸ Creating self-signed code-signing certificate '$SIGN_ID'…"
    local tmp p12pass
    tmp="$(mktemp -d)"
    p12pass="keyboardcleaner"
    cat > "$tmp/openssl.cnf" <<CNF
[req]
distinguished_name = dn
x509_extensions = v3
prompt = no
[dn]
CN = $SIGN_ID
[v3]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
CNF
    openssl req -x509 -newkey rsa:2048 -keyout "$tmp/key.pem" -out "$tmp/cert.pem" \
        -days 3650 -nodes -config "$tmp/openssl.cnf" >/dev/null 2>&1
    openssl pkcs12 -export -out "$tmp/id.p12" -inkey "$tmp/key.pem" -in "$tmp/cert.pem" \
        -passout "pass:$p12pass" -name "$SIGN_ID" \
        -legacy -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1 >/dev/null 2>&1
    security import "$tmp/id.p12" -k "$HOME/Library/Keychains/login.keychain-db" \
        -P "$p12pass" -T /usr/bin/codesign -A >/dev/null 2>&1
    rm -rf "$tmp"
}

ensure_signing_identity

echo "▸ Building ($CONFIG)…"
swift build -c "$CONFIG"
BIN="$(swift build -c "$CONFIG" --show-bin-path)/$EXECUTABLE"

echo "▸ Assembling $APP_NAME.app…"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN" "$CONTENTS/MacOS/$EXECUTABLE"

# App icon — regenerate the .icns from the design if it's missing.
ICNS="$ROOT/Resources/AppIcon.icns"
if [ ! -f "$ICNS" ]; then
    echo "▸ Generating app icon…"
    ICONSET="$(mktemp -d)/AppIcon.iconset"
    swift "$ROOT/Tools/make_icon.swift" "$ICONSET" >/dev/null
    iconutil -c icns "$ICONSET" -o "$ICNS"
fi
cp "$ICNS" "$CONTENTS/Resources/AppIcon.icns"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>     <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>      <string>$EXECUTABLE</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>NSPrincipalClass</key>        <string>NSApplication</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

echo "▸ Code-signing with '$SIGN_ID'…"
codesign --force --sign "$SIGN_ID" "$APP"

echo "✓ Built: $APP"
echo "  Launch with: open \"$APP\""
