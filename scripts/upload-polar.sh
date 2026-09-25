#!/bin/sh
set -eu
CONFIG="$1"; FILE="$2"; VERSION="$3"
. "$CONFIG"
[ -f "$FILE" ] || { echo "DMG not found: $FILE" >&2; exit 2; }
[ -n "${POLAR_ACCESS_TOKEN:-}" ] || { echo "POLAR_ACCESS_TOKEN is not set" >&2; exit 2; }
API="https://api.polar.sh/v1"; AUTH="Authorization: Bearer $POLAR_ACCESS_TOKEN"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT HUP INT TERM
api() { method="$1"; url="$2"; data="${3:-}"; if [ -n "$data" ]; then curl --fail-with-body --silent --show-error -X "$method" -H "$AUTH" -H 'Content-Type: application/json' -H 'Accept: application/json' --data-binary "$data" "$url"; else curl --fail-with-body --silent --show-error -X "$method" -H "$AUTH" -H 'Accept: application/json' "$url"; fi; }
product="$(api GET "$API/products/$POLAR_PRODUCT_ID")"
benefit_id="$(printf '%s' "$product" | jq -r '[.benefits[]? | select(.type == "downloadables") | .id] | if length == 1 then .[0] else empty end')"
[ -n "$benefit_id" ] || { echo "Product needs exactly one File Downloads benefit" >&2; exit 1; }
benefit="$(api GET "$API/benefits/$benefit_id")"
size="$(stat -f '%z' "$FILE")"; last=$((size - 1)); checksum="$(${OPENSSL:-/usr/bin/openssl} dgst -sha256 -binary "$FILE" | base64 | tr -d '\n')"; name="$(basename "$FILE")"
payload="$(jq -cn --arg name "$name" --arg version "$VERSION" --arg checksum "$checksum" --argjson size "$size" --argjson last "$last" '{name:$name,mime_type:"application/x-apple-diskimage",size:$size,checksum_sha256_base64:$checksum,service:"downloadable",version:$version,upload:{parts:[{number:1,chunk_start:0,chunk_end:$last,checksum_sha256_base64:$checksum}]}}')"
created="$(api POST "$API/files/" "$payload")"; file_id="$(printf '%s' "$created" | jq -er '.id')"; upload_id="$(printf '%s' "$created" | jq -er '.upload.id')"; path="$(printf '%s' "$created" | jq -er '.upload.path')"; url="$(printf '%s' "$created" | jq -er '.upload.parts[0].url')"
printf '%s' "$created" | jq -r '.upload.parts[0].headers // {} | to_entries[] | "header = " + ((.key + ": " + .value) | @json)' > "$TMP/curl.conf"
curl --fail-with-body --silent --show-error -X PUT --config "$TMP/curl.conf" --data-binary "@$FILE" -D "$TMP/headers" "$url" >/dev/null
etag="$(awk 'tolower($0) ~ /^etag:/{gsub(/\r|\"/,""); sub(/^[Ee][Tt][Aa][Gg]:[[:space:]]*/,""); print; exit}' "$TMP/headers")"; [ -n "$etag" ] || exit 1
complete="$(jq -cn --arg id "$upload_id" --arg path "$path" --arg etag "$etag" --arg checksum "$checksum" '{id:$id,path:$path,parts:[{number:1,checksum_etag:$etag,checksum_sha256_base64:$checksum}]}')"
api POST "$API/files/$file_id/uploaded" "$complete" >/dev/null
old="$(printf '%s' "$benefit" | jq -c '.properties.files // []')"; files="$(printf '%s' "$old" | jq -c --arg id "$file_id" '[$id] + map(select(. != $id))')"; archived="$(printf '%s' "$old" | jq -c 'map({key:.,value:true}) | from_entries')"
update="$(jq -cn --argjson files "$files" --argjson archived "$archived" '{type:"downloadables",properties:{files:$files,archived:$archived}}')"
api PATCH "$API/benefits/$benefit_id" "$update" >/dev/null
echo "Uploaded $name to Polar"
