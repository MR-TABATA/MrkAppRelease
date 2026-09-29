# MrkAppRelease

Signed and notarized macOS releases for Mrk apps. Source code is maintained in separate repositories; this repository contains release binaries only.

[日本語](README.ja.md)

## Products

| App | Download | Product page |
| --- | --- | --- |
| MrkDiff Hex | [Download app / 14-day trial](https://github.com/MR-TABATA/MrkAppRelease/releases/download/mrkdiff-hex-v1.1.0/MrkDiff-Hex-1.1.0.dmg) | [English](https://mr-tabata.github.io/MrDiff/MrkDiffHex.en.html) · [日本語](https://mr-tabata.github.io/MrDiff/MrkDiffHex.ja.html) |
| MrkEditor | [Sold through Polar](https://buy.polar.sh/polar_cl_S32h7CYTXCxbYQ5IimcpI4DayCFkHUYQ8I6bv2tOki8) | [English](https://mr-tabata.github.io/MrEditor/MrkEditor.html) · [日本語](https://mr-tabata.github.io/MrEditor/MrkEditor.ja.html) |
| MrkDown | [Sold through Polar](https://buy.polar.sh/polar_cl_0ZFDepQfKNP0v374jKC5AApEKjtQRs0gowqVs3x6YvO) | [English](https://github.com/MR-TABATA/MRDown) · [日本語](https://github.com/MR-TABATA/MRDown/blob/main/README.ja.md) |

MrkDiff Hex includes a 14-day free trial from first launch. No credit card is required. After purchase, enter your license key in the same app.
MrkEditor does not have a separate trial; the free MrEditor app uses the same editor core and can be used before purchase.
MrkDown does not have a separate trial; the free MRDown app is the trial path. After purchase, download the DMG from your Polar purchase portal and copy `MrkDown License Key - copy to app` into MrkDown Settings > Licenses.

## Release History

### MrkEditor 1.0.5 — 2026-09-29

- Fixes typing into the detached search panel and preserves the black-and-gold MrkEditor app icon.
- Download is available from your Polar purchase portal.

### MrkEditor 1.0.4 — 2026-09-29

- Picks up MrEditor 1.19.1's search improvements through the shared core: full content stays visible, matches are highlighted, and the search panel can be dragged beyond the document window.
- Download is available from your Polar purchase portal.

### MrkEditor 1.0.3 — 2026-09-28

- Fixes a macOS Keychain prompt reappearing on every update (new installs only; existing ones need one deactivate/activate).
- Download is available from your Polar purchase portal.

### MrkEditor 1.0.2 — 2026-09-28

- Picks up the free MrEditor app's "Open by Path…" (⌥⌘O): paste a copied local path to open it.
- Download is available from your Polar purchase portal.

### MrkDown 1.0.0 — 2026-09-28

- Initial paid release for AI diff explanation.
- Download and license key are available from your Polar purchase portal.
- Developer ID signed and notarized Apple Silicon macOS app.

### MrkEditor 1.0.1 — 2026-09-27

- Adds "Import Settings from MrEditor..." to the File menu for users moving from the free MrEditor app.
- Download is available from your Polar purchase portal.

### MrkDiff Hex 1.0.0 — 2026-09-24

- Initial release.
- 14-day free trial from first launch; after purchase, enter your license key in the same app.
- Developer ID signed and notarized universal macOS app.

## Metrics

`.github/workflows/collect-metrics.yml` runs every day at 09:17 JST and can also be run manually. It appends rolling 14-day repository traffic and cumulative release-asset download counts to [`metrics/history.csv`](metrics/history.csv).

The workflow first tries the repository's standard `GITHUB_TOKEN`. If GitHub does not allow that token to read Traffic API data, download counts are still recorded and `traffic_status` becomes `token_required`. To enable traffic figures, add a fine-grained repository secret named `TRAFFIC_TOKEN`, restricted to this repository with read-only Administration permission.

## Release naming

- Tag: `<product>-v<version>` (for example, `mrkdiff-hex-v1.1.0`)
- Asset: `<Product>-<version>.dmg`
- Every public DMG must be Developer ID signed, notarized by Apple, stapled, and checked with Gatekeeper before upload.

## Shared release command

Each app has one file under `products/`; signing, notarization, GitHub Release, Polar upload,
release notes, tags, cross-repository reference updates, commits and pushes are handled by one command.
The complete setup and operating procedure is documented in [`docs/releasing.md`](docs/releasing.md).

```sh
sh scripts/release.sh <product> <version> --publish
```

Add another app by adding `products/<product>.conf`; do not copy the release engine.
