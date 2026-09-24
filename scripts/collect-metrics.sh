#!/usr/bin/env bash
set -euo pipefail

repository="${TARGET_REPOSITORY:?TARGET_REPOSITORY is required}"
output="metrics/history.csv"
collected_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p metrics

views_json='{"count":null,"uniques":null}'
clones_json='{"count":null,"uniques":null}'
traffic_status="available"

if ! views_json="$(gh api "repos/$repository/traffic/views" 2>/dev/null)"; then
  traffic_status="token_required"
  views_json='{"count":null,"uniques":null}'
fi

if ! clones_json="$(gh api "repos/$repository/traffic/clones" 2>/dev/null)"; then
  traffic_status="token_required"
  clones_json='{"count":null,"uniques":null}'
fi

views="$(jq -r '.count // ""' <<<"$views_json")"
unique_views="$(jq -r '.uniques // ""' <<<"$views_json")"
clones="$(jq -r '.count // ""' <<<"$clones_json")"
unique_clones="$(jq -r '.uniques // ""' <<<"$clones_json")"

assets="$(gh api --paginate "repos/$repository/releases?per_page=100" --jq '.[] | .tag_name as $tag | .assets[] | [$tag, .name, .download_count, (.digest // "")] | @tsv')"

if [[ ! -f "$output" ]]; then
  printf '%s\n' 'collected_at,views_14d,unique_views_14d,clones_14d,unique_clones_14d,traffic_status,tag,asset,downloads,digest' > "$output"
fi

if [[ -z "$assets" ]]; then
  printf '%s,%s,%s,%s,%s,%s,,,,\n' \
    "$collected_at" "$views" "$unique_views" "$clones" "$unique_clones" "$traffic_status" >> "$output"
else
  while IFS=$'\t' read -r tag asset downloads digest; do
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
      "$collected_at" "$views" "$unique_views" "$clones" "$unique_clones" "$traffic_status" \
      "$tag" "$asset" "$downloads" "$digest" >> "$output"
  done <<< "$assets"
fi

echo "Recorded metrics for $repository at $collected_at (traffic: $traffic_status)"
