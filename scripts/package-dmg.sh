#!/bin/sh
# Package an already signed .app. No Git, Polar or release publication changes.
set -eu
APP="${1:?app path required}"
DMG="${2:?dmg path required}"
: "${SIGN_IDENTITY:?Developer ID required}"
: "${NOTARY_PROFILE:?notarytool profile required}"
[ "$SIGN_IDENTITY" != "-" ] || { echo "Developer ID required" >&2; exit 1; }
[ -d "$APP" ] || exit 1
[ ! -e "$DMG" ] || { echo "Output already exists: $DMG" >&2; exit 1; }
codesign --verify --deep --strict "$APP"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT HUP INT TERM
ditto -c -k --keepParent "$APP" "$STAGE/app.zip"
xcrun notarytool submit "$STAGE/app.zip" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose=2 "$APP"
mkdir "$STAGE/image"
ditto "$APP" "$STAGE/image/$(basename "$APP")"
ln -s /Applications "$STAGE/image/Applications"
hdiutil create -volname "$(basename "$DMG" .dmg)" -srcfolder "$STAGE/image" -format UDZO "$DMG"
codesign --sign "$SIGN_IDENTITY" --timestamp "$DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"
shasum -a 256 "$DMG"
