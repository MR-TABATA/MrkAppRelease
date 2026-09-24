#!/bin/sh
# Shared release entry point for every Mrk app.
set -eu

RELEASE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT="${1:-}"
VERSION="${2:-}"
MODE="${3:---check}"
EXTRA="${4:-}"
CONFIG="$RELEASE_ROOT/products/$PRODUCT.conf"

[ -f "$CONFIG" ] || {
    echo "unknown product: $PRODUCT" >&2
    echo "available products:" >&2
    for file in "$RELEASE_ROOT"/products/*.conf; do basename "$file" .conf >&2; done
    exit 2
}
. "$CONFIG"
printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || {
    echo "usage: $0 <product> <major.minor.patch> [--check|--publish] [--skip-polar]" >&2
    exit 2
}
case "$MODE" in --check|--publish) ;; *) echo "unknown mode: $MODE" >&2; exit 2;; esac
SKIP_POLAR=0
[ "$EXTRA" = "--skip-polar" ] && SKIP_POLAR=1

SOURCE_ROOT="$(cd "$RELEASE_ROOT/$SOURCE_REPOSITORY_PATH" && pwd)"
PUBLIC_ROOT="$(cd "$RELEASE_ROOT/$PUBLIC_REPOSITORY_PATH" && pwd)"
REPOSITORY="MR-TABATA/MrkAppRelease"
TAG="$PRODUCT_SLUG-v$VERSION"
SOURCE_TAG="v$VERSION"
ASSET="$ASSET_STEM-$VERSION.dmg"
BUILT_DMG="$SOURCE_ROOT/$BUILT_DMG_PREFIX$VERSION.dmg"
PUBLISH_DMG="$SOURCE_ROOT/.build/$ASSET"

need() { command -v "$1" >/dev/null 2>&1 || { echo "required command not found: $1" >&2; exit 1; }; }
main_repo() {
    [ "$(git -C "$1" branch --show-current)" = "main" ] || { echo "not on main: $1" >&2; exit 1; }
}
clean_repo() {
    [ -z "$(git -C "$1" status --porcelain)" ] || {
        echo "working tree is not clean: $1" >&2; git -C "$1" status --short >&2; exit 1
    }
}
generated_notes() {
    previous="$(git -C "$SOURCE_ROOT" tag --list 'v[0-9]*' --sort=-version:refname | head -1)"
    range=""
    [ -z "$previous" ] || range="$previous..HEAD"
    # shellcheck disable=SC2086
    git -C "$SOURCE_ROOT" log $range --format='- %s' -- $SOURCE_FILTER | awk '!seen[$0]++'
}
release_notes() {
    awk -v version="$VERSION" '
        $0 ~ "^## v" version "([[:space:]]|$)" { found=1; next }
        found && /^## / { exit }
        found { print }
    ' "$SOURCE_ROOT/$CHANGELOG_FILE"
}
create_changelog() {
    notes="$1"; output="$(mktemp)"; today="$(date '+%Y-%m-%d')"
    awk -v version="$VERSION" -v today="$today" -v notes="$notes" '
        BEGIN { while ((getline line < notes) > 0) body = body line ORS; close(notes) }
        !inserted && /^## / { printf "## v%s — %s\n\n%s\n", version, today, body; inserted=1 }
        { print }
    ' "$SOURCE_ROOT/$CHANGELOG_FILE" > "$output"
    mv "$output" "$SOURCE_ROOT/$CHANGELOG_FILE"
}
replace_refs() {
    old="$(tr -d '[:space:]' < "$SOURCE_ROOT/$VERSION_FILE")"
    old_tag="$PRODUCT_SLUG-v$old"; old_asset="$ASSET_STEM-$old.dmg"
    new_url="https://github.com/$REPOSITORY/releases/download/$TAG/$ASSET"
    printf '%s\n' "$VERSION" > "$SOURCE_ROOT/$VERSION_FILE"
    for spec in \
        "source:$SOURCE_REFERENCE_FILES" \
        "public:$PUBLIC_REFERENCE_FILES" \
        "release:$RELEASE_REFERENCE_FILES"
    do
        kind="${spec%%:*}"; files="${spec#*:}"
        case "$kind" in source) base="$SOURCE_ROOT";; public) base="$PUBLIC_ROOT";; release) base="$RELEASE_ROOT";; esac
        for file in $files; do
            perl -0pi -e "s/\\Q$old_tag\\E/$TAG/g; s/\\Q$old_asset\\E/$ASSET/g" "$base/$file"
            grep -Fq "$new_url" "$base/$file" || { echo "release URL missing in $base/$file" >&2; exit 1; }
        done
    done
}

for tool in git gh jq curl openssl swift xcrun codesign spctl; do need "$tool"; done
for repo in "$SOURCE_ROOT" "$PUBLIC_ROOT" "$RELEASE_ROOT"; do main_repo "$repo"; done
clean_repo "$PUBLIC_ROOT"; clean_repo "$RELEASE_ROOT"
security find-identity -v -p codesigning | grep -Fq "$SIGN_IDENTITY" || { echo "Developer ID certificate not found" >&2; exit 1; }
xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null

if [ "$MODE" = "--check" ]; then
    echo "Preflight OK for $PRODUCT_NAME $VERSION"
    generated_notes
    exit 0
fi

if ! gh auth status -h github.com >/dev/null 2>&1; then
    gh auth login --hostname github.com --git-protocol https --web
fi
[ -n "${POLAR_ACCESS_TOKEN:-}" ] || POLAR_ACCESS_TOKEN="$(security find-generic-password -w -a "$USER" -s "$POLAR_KEYCHAIN_SERVICE" 2>/dev/null || true)"
export POLAR_ACCESS_TOKEN
[ "$SKIP_POLAR" -eq 1 ] || [ -n "$POLAR_ACCESS_TOKEN" ] || { echo "Polar token not found: $POLAR_KEYCHAIN_SERVICE" >&2; exit 1; }
git -C "$SOURCE_ROOT" rev-parse -q --verify "refs/tags/$SOURCE_TAG" >/dev/null 2>&1 && { echo "tag exists: $SOURCE_TAG" >&2; exit 1; }
gh release view "$TAG" --repo "$REPOSITORY" >/dev/null 2>&1 && { echo "release exists: $TAG" >&2; exit 1; }

echo ">> Tests"
(cd "$SOURCE_ROOT" && sh -c "$TEST_COMMAND")
if [ -n "$(git -C "$SOURCE_ROOT" status --porcelain)" ]; then
    git -C "$SOURCE_ROOT" add -A
    git -C "$SOURCE_ROOT" commit -m "$PRODUCT_NAME $VERSION の変更"
fi

notes="$(mktemp)"; trap 'rm -f "$notes"' EXIT HUP INT TERM
if grep -Eq "^## v$VERSION([[:space:]]|$)" "$SOURCE_ROOT/$CHANGELOG_FILE"; then release_notes > "$notes"; else
    generated_notes > "$notes"; [ -s "$notes" ] || echo '- Maintenance update' > "$notes"; create_changelog "$notes"
fi
echo ">> Release notes"; cat "$notes"

echo ">> Build, sign and notarize"
(cd "$SOURCE_ROOT" && SIGN_IDENTITY="$SIGN_IDENTITY" NOTARY_PROFILE="$NOTARY_PROFILE" VERSION="$VERSION" sh "$BUILD_SCRIPT")
[ -f "$BUILT_DMG" ] || { echo "DMG not found: $BUILT_DMG" >&2; exit 1; }
cp "$BUILT_DMG" "$PUBLISH_DMG"

replace_refs
git -C "$SOURCE_ROOT" add "$VERSION_FILE" "$CHANGELOG_FILE" $SOURCE_REFERENCE_FILES
git -C "$SOURCE_ROOT" commit -m "$PRODUCT_NAME $VERSION"
git -C "$PUBLIC_ROOT" add $PUBLIC_REFERENCE_FILES
git -C "$PUBLIC_ROOT" commit -m "$PRODUCT_NAME $VERSION のダウンロード先を更新"
git -C "$RELEASE_ROOT" add $RELEASE_REFERENCE_FILES
git -C "$RELEASE_ROOT" commit -m "$PRODUCT_NAME $VERSION の配布先を更新"
git -C "$SOURCE_ROOT" tag -a "$SOURCE_TAG" -m "$PRODUCT_NAME $VERSION"

gh release create "$TAG" "$PUBLISH_DMG" --repo "$REPOSITORY" --title "$PRODUCT_NAME $VERSION" --notes-file "$notes"
if [ "$SKIP_POLAR" -eq 0 ]; then
    sh "$RELEASE_ROOT/scripts/upload-polar.sh" "$CONFIG" "$PUBLISH_DMG" "$VERSION"
fi
git -C "$SOURCE_ROOT" push origin main "$SOURCE_TAG"
git -C "$RELEASE_ROOT" push origin main
git -C "$PUBLIC_ROOT" push origin main

url="https://github.com/$REPOSITORY/releases/download/$TAG/$ASSET"
curl --fail --silent --show-error --location --range 0-0 --output /dev/null "$url"
echo "Released $PRODUCT_NAME $VERSION"
echo "$url"
