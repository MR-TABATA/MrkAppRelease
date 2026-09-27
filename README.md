# MrkAppRelease

Signed and notarized macOS releases for Mrk apps. Source code is maintained in separate repositories; this repository contains release binaries only.

Mrk 系アプリの署名・公証済み macOS リリース置き場です。ソースコードは別リポジトリで管理し、このリポジトリには配布物とリリース情報だけを置きます。

## Products

| App | Download | Product page |
| --- | --- | --- |
| MrkDiff Hex | [MrkDiff-Hex-1.0.0.dmg](https://github.com/MR-TABATA/MrkAppRelease/releases/download/mrkdiff-hex-v1.0.0/MrkDiff-Hex-1.0.0.dmg) | [English](https://mr-tabata.github.io/MrDiff/MrkDiffHex.en.html) · [日本語](https://mr-tabata.github.io/MrDiff/MrkDiffHex.ja.html) |
| MrkEditor | Sold through Polar | [English](https://mr-tabata.github.io/MrEditor/MrkEditor.html) · [日本語](https://mr-tabata.github.io/MrEditor/MrkEditor.ja.html) |

MrkDiff Hex includes a 14-day free trial from first launch. No credit card is required.
MrkEditor does not have a separate trial; the free MrEditor app uses the same editor core and can be used before purchase.

MrkDiff Hex は初回起動から 14 日間の無料トライアル付きです。開始にクレジットカードは不要です。
MrkEditor には別トライアルを設けません。購入前の試用は、同じ editor core を使う無料版 MrEditor で行えます。MrkEditor のダウンロードは Polar の購入者ポータルから提供します。

## Metrics

`.github/workflows/collect-metrics.yml` runs every day at 09:17 JST and can also be run manually. It appends rolling 14-day repository traffic and cumulative release-asset download counts to [`metrics/history.csv`](metrics/history.csv).

The workflow first tries the repository's standard `GITHUB_TOKEN`. If GitHub does not allow that token to read Traffic API data, download counts are still recorded and `traffic_status` becomes `token_required`. To enable traffic figures, add a fine-grained repository secret named `TRAFFIC_TOKEN`, restricted to this repository with read-only Administration permission.

`.github/workflows/collect-metrics.yml` は毎日 09:17 JST に実行され、手動実行もできます。直近 14 日間のリポジトリ traffic と、Release asset の累計ダウンロード数を [`metrics/history.csv`](metrics/history.csv) に追記します。

通常はリポジトリ標準の `GITHUB_TOKEN` を使います。Traffic API の読み取りが許可されない場合でも、ダウンロード数は記録し、`traffic_status` は `token_required` になります。traffic も取りたい場合は、このリポジトリ限定・Administration 読み取り専用の fine-grained secret `TRAFFIC_TOKEN` を追加します。

## Release naming

- Tag: `<product>-v<version>` (for example, `mrkdiff-hex-v1.0.0`)
- Asset: `<Product>-<version>.dmg`
- Every public DMG must be Developer ID signed, notarized by Apple, stapled, and checked with Gatekeeper before upload.

- タグ: `<product>-v<version>`（例: `mrkdiff-hex-v1.0.0`）
- Asset: `<Product>-<version>.dmg`
- public に置く DMG は、アップロード前に必ず Developer ID 署名、Apple 公証、staple、Gatekeeper 確認を済ませます。

## Shared release command

Each app has one file under `products/`; signing, notarization, GitHub Release, Polar upload,
release notes, tags, cross-repository reference updates, commits and pushes are handled by one command.
The complete setup and operating procedure is documented in [`docs/releasing.md`](docs/releasing.md).

```sh
sh scripts/release.sh <product> <version> --publish
```

Add another app by adding `products/<product>.conf`; do not copy the release engine.

各アプリの差分は `products/` 配下の設定ファイル 1 つに寄せます。署名、公証、GitHub Release、Polar アップロード、リリースノート、タグ、関連リポジトリの参照更新、コミット、push は 1 コマンドで行います。詳しい手順は [`docs/releasing.md`](docs/releasing.md) にあります。

アプリを増やすときは `products/<product>.conf` を追加します。リリースエンジンは複製しません。
