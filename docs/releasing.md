# Mrkアプリ共通リリース手順

## 方針

配布バイナリは公開リポジトリ `MR-TABATA/MrkAppRelease` に集約する。
リリース処理は `scripts/release.sh` の1本にまとめ、製品ごとの差は
`products/<product>.conf` だけに置く。製品ごとにリリーススクリプトをコピーしない。

共通処理は次のとおり。

- テストと未コミット変更のコミット
- 前回tag以降のソース変更からCHANGELOGとRelease notesを生成
- Universal build、Developer ID署名、Apple公証、staple、Gatekeeper検証
- GitHub Release作成とDMGアップロード
- PolarのFile Downloads更新
- 日英LPと各READMEのダウンロードURL更新
- source tag、各リポジトリのコミットとpush
- 公開DMG URLの確認

## 初回設定

GitHub CLIの認証が切れている場合、リリース処理がWeb認証を開く。手動で先に行う場合は
次を実行する。

```sh
gh auth login --hostname github.com --git-protocol https --web
```

Polarでは対象商品にFile Downloads Benefitを1つだけ紐付ける。Organization Access Tokenには
次の権限を付ける。

- `products:read`
- `benefits:read`
- `benefits:write`
- `files:write`

トークンは製品設定に書かず、製品ごとに指定されたmacOS Keychainサービスへ一度だけ保存する。
MrkDiff Hexの場合は次のとおり。

```sh
security add-generic-password -U -a "$USER" -s "com.aaedit.MrkDiff.polar-access-token" -w
```

## MrkDiff Hex

設定は `products/mrkdiff-hex.conf`。事前検査は外部へ公開せず、ファイルも変更しない。

```sh
cd ~/Git/MrkAppRelease
sh scripts/release.sh mrkdiff-hex 1.0.1 --check
```

本番公開は次の1コマンドで行う。`--publish`自体を公開の明示的な承認とする。

```sh
cd ~/Git/MrkAppRelease
sh scripts/release.sh mrkdiff-hex 1.0.1 --publish
```

MrkDiff側の互換ラッパーから実行しても同じ結果になる。

```sh
cd ~/Git/MrkDiff
sh scripts/release.sh 1.0.1 --publish
```

## MrkEditor

設定は `products/mrkeditor.conf`。MrkEditor は非公開ソース、MrEditor は公開コア兼LP側として扱う。
Polar 商品は `c061ff3e-30d0-4c1d-8e94-ca36f5ba8248`、Organization は MrkDiff Hex と同じ。

Polar Access Token は次の Keychain サービスへ保存する。

```sh
security add-generic-password -U -a "$USER" -s "com.aaedit.MrkEditor.polar-access-token" -w
```

初回公開では、事前に Polar 商品へ MrkEditor 用の File Downloads Benefit を 1 つだけ接続してから、
`upload-polar.sh` または `release.sh --publish` を実行する。Benefit が 0 件または複数件だと
アップロードスクリプトは停止する。

## 製品を追加する

`products/mrkdiff-hex.conf`を参考に`products/<product>.conf`を追加する。最低限、次が必要。

- 製品名、slug、DMG名
- ソースリポジトリと公開LPリポジトリ
- `VERSION`と`CHANGELOG`の場所
- テストコマンドとDMG作成スクリプト
- LP・READMEの更新対象
- Developer ID証明書とnotarytoolプロファイル
- Polar Organization ID、Product ID、Keychainサービス名
- Polar商品に紐付いたFile Downloads Benefit

追加後は、まず`--check`で検証してから`--publish`する。

```sh
sh scripts/release.sh mrkeditor 1.0.0 --check
sh scripts/release.sh mrkeditor 1.0.0 --publish
```

別製品としてMrkDiffを配布する場合も、同様に`products/mrkdiff.conf`を追加する。

## 秘密情報

Polar Access Token、Apple ID、App用パスワード、証明書の秘密鍵をリポジトリへ保存しない。
設定ファイルに置くPolarのOrganization ID・Product ID、証明書のSHA-1は秘密情報ではない。
