# MrkAppRelease

Mrk 系アプリの署名・公証済み macOS リリース置き場です。ソースコードは別リポジトリで管理し、このリポジトリには配布物とリリース情報だけを置きます。

[English](README.md)

## 製品

| アプリ | ダウンロード | 製品ページ |
| --- | --- | --- |
| MrkDiff Hex | [アプリをダウンロード（14日間トライアル）](https://github.com/MR-TABATA/MrkAppRelease/releases/download/mrkdiff-hex-v1.1.0/MrkDiff-Hex-1.1.0.dmg) | [English](https://mr-tabata.github.io/MrDiff/MrkDiffHex.en.html) · [日本語](https://mr-tabata.github.io/MrDiff/MrkDiffHex.ja.html) |
| MrkEditor | [Polar で販売](https://buy.polar.sh/polar_cl_S32h7CYTXCxbYQ5IimcpI4DayCFkHUYQ8I6bv2tOki8) | [English](https://mr-tabata.github.io/MrEditor/MrkEditor.html) · [日本語](https://mr-tabata.github.io/MrEditor/MrkEditor.ja.html) |
| MrkDown | [Polar で販売](https://buy.polar.sh/polar_cl_0ZFDepQfKNP0v374jKC5AApEKjtQRs0gowqVs3x6YvO) | [English](https://github.com/MR-TABATA/MRDown) · [日本語](https://github.com/MR-TABATA/MRDown/blob/main/README.ja.md) |

MrkDiff Hex は初回起動から 14 日間の無料トライアル付きです。開始にクレジットカードは不要です。購入後は同じアプリにライセンスキーを入力します。
MrkEditor には別トライアルを設けません。購入前の試用は、同じ editor core を使う無料版 MrEditor で行えます。MrkEditor のダウンロードは Polar の購入者ポータルから提供します。
MrkDown には別トライアルを設けません。購入前の試用は無料版 MRDown で行えます。購入後は Polar の購入者ポータルから DMG をダウンロードし、`MrkDown License Key - copy to app` を MrkDown の Settings > Licenses に入力します。

## リリース履歴

### MrkEditor 1.0.5 — 2026-09-29

- 独立した検索パネルに入力できない問題を修正し、黒地にゴールドのMrkEditorアイコンを維持します。
- ダウンロードは Polar の購入者ポータルから提供します。

### MrkEditor 1.0.4 — 2026-09-29

- 共有コア経由でMrEditor 1.19.1の検索改善を取り込みました。検索中も本文全体を表示し、一致箇所をハイライト。検索パネルはコンテンツウインドウの外へドラッグできます。
- ダウンロードは Polar の購入者ポータルから提供します。

### MrkEditor 1.0.3 — 2026-09-28

- 更新のたびにmacOSのキーチェーン許可ダイアログが再度出る問題を修正（新規インストール分のみ。既存のインストールは一度deactivate→activateが必要です）。
- ダウンロードは Polar の購入者ポータルから提供します。

### MrkEditor 1.0.2 — 2026-09-28

- 無料版MrEditorの「パスを指定して開く…」（⌥⌘O）を取り込みました。コピーしたローカルパスを貼り付けて開けます。
- ダウンロードは Polar の購入者ポータルから提供します。

### MrkDown 1.0.0 — 2026-09-28

- AI diff explanation 向けの有償版初回リリース。
- ダウンロードとライセンスキーは Polar の購入者ポータルから提供します。
- Developer ID 署名・Apple 公証済みの Apple Silicon macOS アプリ。

### MrkEditor 1.0.1 — 2026-09-27

- 無料版 MrEditor から移行するユーザー向けに、File メニューへ「MrEditorから設定を読み込む…」を追加。
- ダウンロードは Polar の購入者ポータルから提供します。

### MrkDiff Hex 1.0.0 — 2026-09-24

- 初回リリース。
- 初回起動から 14 日間の無料トライアル付き。購入後は同じアプリにライセンスキーを入力します。
- Developer ID 署名・Apple 公証済みの Universal macOS アプリ。

## Metrics

`.github/workflows/collect-metrics.yml` は毎日 09:17 JST に実行され、手動実行もできます。直近 14 日間のリポジトリ traffic と、Release asset の累計ダウンロード数を [`metrics/history.csv`](metrics/history.csv) に追記します。

通常はリポジトリ標準の `GITHUB_TOKEN` を使います。Traffic API の読み取りが許可されない場合でも、ダウンロード数は記録し、`traffic_status` は `token_required` になります。traffic も取りたい場合は、このリポジトリ限定・Administration 読み取り専用の fine-grained secret `TRAFFIC_TOKEN` を追加します。

## リリース名

- タグ: `<product>-v<version>`（例: `mrkdiff-hex-v1.1.0`）
- Asset: `<Product>-<version>.dmg`
- public に置く DMG は、アップロード前に必ず Developer ID 署名、Apple 公証、staple、Gatekeeper 確認を済ませます。

## 共通リリースコマンド

各アプリの差分は `products/` 配下の設定ファイル 1 つに寄せます。署名、公証、GitHub Release、Polar アップロード、リリースノート、タグ、関連リポジトリの参照更新、コミット、push は 1 コマンドで行います。詳しい手順は [`docs/releasing.md`](docs/releasing.md) にあります。

```sh
sh scripts/release.sh <product> <version> --publish
```

アプリを増やすときは `products/<product>.conf` を追加します。リリースエンジンは複製しません。
