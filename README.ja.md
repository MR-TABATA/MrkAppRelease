# MrkAppRelease

Mrk 系アプリの署名・公証済み macOS リリース置き場です。ソースコードは別リポジトリで管理し、このリポジトリには配布物とリリース情報だけを置きます。

[English](README.md)

## 製品

| アプリ | ダウンロード | 製品ページ |
| --- | --- | --- |
| MrkDiff Hex | [MrkDiff-Hex-1.0.0.dmg](https://github.com/MR-TABATA/MrkAppRelease/releases/download/mrkdiff-hex-v1.0.0/MrkDiff-Hex-1.0.0.dmg) | [English](https://mr-tabata.github.io/MrDiff/MrkDiffHex.en.html) · [日本語](https://mr-tabata.github.io/MrDiff/MrkDiffHex.ja.html) |
| MrkEditor | Polar で販売 | [English](https://mr-tabata.github.io/MrEditor/MrkEditor.html) · [日本語](https://mr-tabata.github.io/MrEditor/MrkEditor.ja.html) |

MrkDiff Hex は初回起動から 14 日間の無料トライアル付きです。開始にクレジットカードは不要です。
MrkEditor には別トライアルを設けません。購入前の試用は、同じ editor core を使う無料版 MrEditor で行えます。MrkEditor のダウンロードは Polar の購入者ポータルから提供します。

## Metrics

`.github/workflows/collect-metrics.yml` は毎日 09:17 JST に実行され、手動実行もできます。直近 14 日間のリポジトリ traffic と、Release asset の累計ダウンロード数を [`metrics/history.csv`](metrics/history.csv) に追記します。

通常はリポジトリ標準の `GITHUB_TOKEN` を使います。Traffic API の読み取りが許可されない場合でも、ダウンロード数は記録し、`traffic_status` は `token_required` になります。traffic も取りたい場合は、このリポジトリ限定・Administration 読み取り専用の fine-grained secret `TRAFFIC_TOKEN` を追加します。

## リリース名

- タグ: `<product>-v<version>`（例: `mrkdiff-hex-v1.0.0`）
- Asset: `<Product>-<version>.dmg`
- public に置く DMG は、アップロード前に必ず Developer ID 署名、Apple 公証、staple、Gatekeeper 確認を済ませます。

## 共通リリースコマンド

各アプリの差分は `products/` 配下の設定ファイル 1 つに寄せます。署名、公証、GitHub Release、Polar アップロード、リリースノート、タグ、関連リポジトリの参照更新、コミット、push は 1 コマンドで行います。詳しい手順は [`docs/releasing.md`](docs/releasing.md) にあります。

```sh
sh scripts/release.sh <product> <version> --publish
```

アプリを増やすときは `products/<product>.conf` を追加します。リリースエンジンは複製しません。
