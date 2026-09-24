# MrkAppRelease

Signed and notarized macOS releases for Mrk apps. Source code is maintained in separate repositories; this repository contains release binaries only.

## Products

| App | Download | Product page |
| --- | --- | --- |
| MrkDiff Hex | [MrkDiff-Hex-1.0.0.dmg](https://github.com/MR-TABATA/MrkAppRelease/releases/download/mrkdiff-hex-v1.0.0/MrkDiff-Hex-1.0.0.dmg) | [English](https://mr-tabata.github.io/MrDiff/MrkDiffHex.en.html) · [日本語](https://mr-tabata.github.io/MrDiff/MrkDiffHex.ja.html) |

MrkDiff Hex includes a 14-day free trial from first launch. No credit card is required.

## Metrics

`.github/workflows/collect-metrics.yml` runs every day at 09:17 JST and can also be run manually. It appends rolling 14-day repository traffic and cumulative release-asset download counts to [`metrics/history.csv`](metrics/history.csv).

The workflow first tries the repository's standard `GITHUB_TOKEN`. If GitHub does not allow that token to read Traffic API data, download counts are still recorded and `traffic_status` becomes `token_required`. To enable traffic figures, add a fine-grained repository secret named `TRAFFIC_TOKEN`, restricted to this repository with read-only Administration permission.

## Release naming

- Tag: `<product>-v<version>` (for example, `mrkdiff-hex-v1.0.0`)
- Asset: `<Product>-<version>.dmg`
- Every public DMG must be Developer ID signed, notarized by Apple, stapled, and checked with Gatekeeper before upload.

## Shared release command

Each app has one file under `products/`; signing, notarization, GitHub Release, Polar upload,
release notes, tags, cross-repository reference updates, commits and pushes are handled by one command.

```sh
sh scripts/release.sh mrkdiff-hex 1.0.1 --publish
```

Add another app by adding `products/<product>.conf`; do not copy the release engine.
