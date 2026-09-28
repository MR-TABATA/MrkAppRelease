#!/bin/sh
# Polar-only release helper for paid apps whose DMG is distributed only via Polar.
set -eu

RELEASE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT="${1:-}"
VERSION="${2:-}"
MODE="--check"
[ "$#" -ge 3 ] && MODE="$3"
CONFIG="$RELEASE_ROOT/products/$PRODUCT.conf"

[ -f "$CONFIG" ] || {
    echo "unknown product: $PRODUCT" >&2
    echo "available products:" >&2
    for file in "$RELEASE_ROOT"/products/*.conf; do basename "$file" .conf >&2; done
    exit 2
}
. "$CONFIG"

printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || {
    echo "usage: $0 <product> <major.minor.patch> [--check|--publish] [--dmg path] [--skip-tests] [--no-upload] [--no-push] [--no-tag]" >&2
    exit 2
}
case "$MODE" in --check|--publish) ;; *) echo "unknown mode: $MODE" >&2; exit 2;; esac
shift 2
[ "$#" -gt 0 ] && case "$1" in --check|--publish) shift ;; esac

PREBUILT_DMG=""
SKIP_TESTS=0
NO_PUSH=0
NO_UPLOAD=0
NO_TAG=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --dmg)
            [ "$#" -ge 2 ] || { echo "--dmg requires a path" >&2; exit 2; }
            PREBUILT_DMG="$2"
            shift 2
            ;;
        --skip-tests) SKIP_TESTS=1; shift ;;
        --no-upload) NO_UPLOAD=1; shift ;;
        --no-push) NO_PUSH=1; shift ;;
        --no-tag) NO_TAG=1; shift ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

SOURCE_ROOT="$(cd "$RELEASE_ROOT/$SOURCE_REPOSITORY_PATH" && pwd)"
PUBLIC_ROOT="$(cd "$RELEASE_ROOT/$PUBLIC_REPOSITORY_PATH" && pwd)"
SOURCE_TAG="v$VERSION"
TODAY="$(date '+%Y-%m-%d')"
EXPECTED_DMG="$SOURCE_ROOT/$BUILT_DMG_PREFIX${VERSION}_aarch64.dmg"
APP_BUNDLE="$SOURCE_ROOT/src-tauri/target/aarch64-apple-darwin/release/bundle/macos/$PRODUCT_NAME.app"
PUBLISH_DMG="$EXPECTED_DMG"

need() { command -v "$1" >/dev/null 2>&1 || { echo "required command not found: $1" >&2; exit 1; }; }
main_repo() { [ "$(git -C "$1" branch --show-current)" = "main" ] || { echo "not on main: $1" >&2; exit 1; }; }
clean_repo() {
    [ -z "$(git -C "$1" status --porcelain)" ] || {
        echo "working tree is not clean: $1" >&2
        git -C "$1" status --short >&2
        exit 1
    }
}
commit_if_dirty() {
    repo="$1"; message="$2"
    if [ -n "$(git -C "$repo" status --porcelain)" ]; then
        git -C "$repo" add -A
        git -C "$repo" commit -m "$message"
    else
        echo "No commit needed: $repo"
    fi
}
set_json_versions() {
    node -e '
const fs = require("fs");
const version = process.argv[1];
for (const file of ["package.json", "src-tauri/tauri.conf.json"]) {
  const data = JSON.parse(fs.readFileSync(file, "utf8"));
  data.version = version;
  fs.writeFileSync(file, JSON.stringify(data, null, 2) + "\n");
}
' "$VERSION"
}
insert_release_history() {
    file="$1"; lang="$2"
    grep -Fq "### $PRODUCT_NAME $VERSION" "$file" && return 0
    tmp="$(mktemp)"
    if [ "$lang" = "ja" ]; then
        heading="### $PRODUCT_NAME $VERSION — $TODAY"
        body="- ダウンロードとライセンスキーは Polar の購入者ポータルから提供します.\n- Developer ID 署名・Apple 公証済みの Apple Silicon macOS アプリです."
        marker="## リリース履歴"
    else
        heading="### $PRODUCT_NAME $VERSION — $TODAY"
        body="- Download and license key are available from your Polar purchase portal.\n- Developer ID signed and notarized Apple Silicon macOS app."
        marker="## Release History"
    fi
    awk -v marker="$marker" -v heading="$heading" -v body="$body" '
        $0 == marker && !done { print; print ""; print heading; print ""; gsub(/\\n/, "\n", body); print body; done=1; next }
        { print }
        END { if (!done) exit 3 }
    ' "$file" > "$tmp" || { rm -f "$tmp"; echo "release history marker not found: $file" >&2; exit 1; }
    mv "$tmp" "$file"
}
verify_and_notarize() {
    dmg="$1"
    [ -f "$dmg" ] || { echo "DMG not found: $dmg" >&2; exit 1; }
    if [ -d "$APP_BUNDLE" ]; then
        codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
        spctl --assess --type execute --verbose=2 "$APP_BUNDLE"
    else
        echo "App bundle not found, skipping app assessment: $APP_BUNDLE" >&2
    fi
    xcrun notarytool submit "$dmg" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$dmg"
    xcrun stapler validate "$dmg"
    spctl --assess --type open --context context:primary-signature --verbose=2 "$dmg"
}
build_dmg() {
    if [ -n "$PREBUILT_DMG" ]; then
        [ -f "$PREBUILT_DMG" ] || { echo "prebuilt DMG not found: $PREBUILT_DMG" >&2; exit 1; }
        PUBLISH_DMG="$(cd "$(dirname "$PREBUILT_DMG")" && pwd)/$(basename "$PREBUILT_DMG")"
        return 0
    fi
    (cd "$SOURCE_ROOT" && npm run sidecar && APPLE_SIGNING_IDENTITY="$SIGN_IDENTITY" npm run tauri -- build --target aarch64-apple-darwin)
    PUBLISH_DMG="$EXPECTED_DMG"
}
print_plan() {
    echo "Product: $PRODUCT_NAME"
    echo "Version: $VERSION"
    echo "Mode: $MODE"
    echo "Source: $SOURCE_ROOT"
    echo "Public LP: $PUBLIC_ROOT"
    echo "Release repo: $RELEASE_ROOT"
    echo "DMG: ${PREBUILT_DMG:-$EXPECTED_DMG}"
    echo "Polar product: ${POLAR_PRODUCT_ID:-missing}"
    echo "Notary profile: ${NOTARY_PROFILE:-missing}"
}

for tool in git jq curl openssl node npm xcrun codesign spctl security shasum; do need "$tool"; done
for repo in "$SOURCE_ROOT" "$PUBLIC_ROOT" "$RELEASE_ROOT"; do main_repo "$repo"; done
clean_repo "$SOURCE_ROOT"; clean_repo "$PUBLIC_ROOT"; clean_repo "$RELEASE_ROOT"
[ -n "${POLAR_PRODUCT_ID:-}" ] || { echo "POLAR_PRODUCT_ID is missing in $CONFIG" >&2; exit 1; }
[ -n "${POLAR_KEYCHAIN_SERVICE:-}" ] || { echo "POLAR_KEYCHAIN_SERVICE is missing in $CONFIG" >&2; exit 1; }
security find-identity -v -p codesigning | grep -Fq "$SIGN_IDENTITY" || { echo "Developer ID certificate not found: $SIGN_IDENTITY" >&2; exit 1; }
xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null
POLAR_ACCESS_TOKEN="${POLAR_ACCESS_TOKEN:-$(security find-generic-password -w -a "$USER" -s "$POLAR_KEYCHAIN_SERVICE" 2>/dev/null || true)}"
export POLAR_ACCESS_TOKEN
[ -n "$POLAR_ACCESS_TOKEN" ] || { echo "Polar token not found: $POLAR_KEYCHAIN_SERVICE" >&2; exit 1; }

print_plan
[ "$MODE" = "--check" ] && { echo "Preflight OK for $PRODUCT_NAME $VERSION"; exit 0; }

git -C "$SOURCE_ROOT" rev-parse -q --verify "refs/tags/$SOURCE_TAG" >/dev/null 2>&1 && { echo "tag exists: $SOURCE_TAG" >&2; exit 1; }

if [ "$SKIP_TESTS" -eq 0 ]; then
    echo ">> Tests"
    (cd "$SOURCE_ROOT" && sh -c "$TEST_COMMAND")
fi

echo ">> Update source version"
(cd "$SOURCE_ROOT" && set_json_versions)

echo ">> Build DMG"
build_dmg
verify_and_notarize "$PUBLISH_DMG"

if [ "$NO_UPLOAD" -eq 0 ]; then
    echo ">> Upload to Polar"
    sh "$RELEASE_ROOT/scripts/upload-polar.sh" "$CONFIG" "$PUBLISH_DMG" "$VERSION"
else
    echo ">> Skip Polar upload"
fi

echo ">> Update release history"
insert_release_history "$RELEASE_ROOT/README.md" en
insert_release_history "$RELEASE_ROOT/README.ja.md" ja

commit_if_dirty "$SOURCE_ROOT" "$PRODUCT_NAME $VERSION"
commit_if_dirty "$RELEASE_ROOT" "$PRODUCT_NAME $VERSION のPolar配布を更新"

if [ "$NO_TAG" -eq 0 ]; then
    git -C "$SOURCE_ROOT" tag -a "$SOURCE_TAG" -m "$PRODUCT_NAME $VERSION"
fi
if [ "$NO_PUSH" -eq 0 ]; then
    git -C "$SOURCE_ROOT" push origin main
    [ "$NO_TAG" -eq 1 ] || git -C "$SOURCE_ROOT" push origin "$SOURCE_TAG"
    git -C "$RELEASE_ROOT" push origin main
fi

sha="$(shasum -a 256 "$PUBLISH_DMG" | awk '{print $1}')"
echo "Released $PRODUCT_NAME $VERSION to Polar"
echo "DMG: $PUBLISH_DMG"
echo "SHA-256: $sha"
echo "Final manual check: download the DMG from Polar purchase portal and compare SHA-256."
