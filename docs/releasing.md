# Mrkアプリ共通リリース手順

## 方針

Mrk系アプリには、配布方法が2種類ある。

1. **public trial型**: 未購入者がGitHubからDMGを直接ダウンロードして試せるアプリ。
   例: MrkDiff Hex。公開リポジトリ `MR-TABATA/MrkAppRelease` のGitHub Releaseに
   DMG assetを置く。
2. **Polar-only paid型**: 別トライアルを設けず、購入者だけがPolar購入者ポータルから
   DMGをダウンロードするアプリ。例: MrkEditor。`MR-TABATA/MrkAppRelease` には
   リリース履歴だけを置き、DMG assetは置かない。

`scripts/release.sh` は public trial型のための共通リリースエンジンである。製品ごとの差は
`products/<product>.conf` だけに置き、製品ごとにリリーススクリプトをコピーしない。

public trial型の共通処理は次のとおり。

- テストと未コミット変更のコミット
- 前回tag以降のソース変更からCHANGELOGとRelease notesを生成
- Universal build、Developer ID署名、Apple公証、staple、Gatekeeper検証
- GitHub Release作成とDMGアップロード
- PolarのFile Downloads更新
- 日英LPと各READMEのダウンロードURL更新
- source tag、各リポジトリのコミットとpush
- 公開DMG URLの確認

Polar-only paid型では、GitHub Releaseを作らない。GitHub Releasesはassetを付けなくても
`Source code (zip)` / `Source code (tar.gz)` を自動表示するため、一般ユーザーには
「ソースまたは配布物が公開されている」ように見えて紛らわしい。リリース情報は
`README.md` / `README.ja.md` のRelease Historyに書く。

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
例では次に出すバージョンを `1.0.1` としている。

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
`upload-polar.sh` を実行する。Benefit が 0 件または複数件だとアップロードスクリプトは停止する。

MrkEditor は Polar-only paid型なので、`release.sh --publish` は使わない。`release.sh` は
GitHub ReleaseにDMG assetを置くため、未購入者がpublic GitHubから直接ダウンロードできてしまう。

### Polar-only paid型の手順

MrkEditorと同じ販売方式のアプリでは、次の順番で進める。

1. **ソースリポジトリでバージョンを確定する。**
   `VERSION` と `CHANGELOG.md` を更新し、必要なソース変更をコミット・pushする。
   非公開ソースリポジトリ側のtag（例: `v1.0.1`）は作ってよい。publicな
   `MR-TABATA/MrkAppRelease` 側には製品tagを作らない。
2. **署名・公証済みDMGを作る。**

   ```sh
   cd ~/Git/MrkEditor
   SIGN_IDENTITY=2CC8414D04AECA2A8FBA4D57754C624F6ED4BE1A \
   NOTARY_PROFILE=mreditor sh scripts/make_dmg.sh
   ```

   `PRO_DEV_UNLOCK=1` などの開発用解錠フラグが入ったビルドを配布してはいけない。
3. **Polar File Downloadsへアップロードする。**

   ```sh
   cd ~/Git/MrkAppRelease
   POLAR_ACCESS_TOKEN="$(security find-generic-password -w -a "$USER" -s "com.aaedit.MrkEditor.polar-access-token")" \
     sh scripts/upload-polar.sh products/mrkeditor.conf ../MrkEditor/.build/MrkEditor-1.0.1.dmg 1.0.1
   ```

   `upload-polar.sh` は新ファイルを先頭activeにし、既存ファイルをarchivedにする。
4. **購入者ポータルから実ダウンロードしてSHA-256を照合する。**

   ```sh
   shasum -a 256 ~/Downloads/MrkEditor-1.0.1.dmg
   shasum -a 256 ~/Git/MrkEditor/.build/MrkEditor-1.0.1.dmg
   ```

   2つが一致してから配布完了とする。
5. **公開リリース情報だけを更新する。**
   `MR-TABATA/MrkAppRelease` の `README.md` / `README.ja.md` にRelease Historyを追加する。
   DMGへの直リンクは書かず、`Download is available from your Polar purchase portal.` のように
   Polar購入者ポータルを案内する。
6. **GitHub Releaseを作らない。**
   assetなしReleaseでもGitHubがsource archiveを自動表示するため、Polar-only paid型では使わない。

Products表では、MrkEditorのDownload欄は `Sold through Polar` / `Polar で販売` とし、必要なら
Polar checkoutへリンクする。DMG URLへはリンクしない。

## MrkDown

MrkDown は MrkEditor と同じ **Polar-only paid型** とする。公開GitHub ReleaseにDMGを置かず、
購入者だけがPolar購入者ポータルからDMGを取得する。
別トライアルは設けない。購入前の試用導線は無料版MRDownとする。
`scripts/release.sh --publish` は使わない。MrkDownにはまだMrkAppRelease共通エンジン用の
ローカルDMG作成スクリプトが無く、現行のGitHub Actions release workflowはdraft releaseを作る
設計なので、そのままpublic配布導線にしてはいけない。

販売条件は次で固定する。

- 価格: one-time purchase / USD 39.00
- Activation: 1ライセンスキーで最大3台
- Trial: なし
- 対応環境: Apple Silicon Mac / macOS 13以降
- ライセンス猶予: MrkEditorと同じ再検証・オフライン猶予
- 移行: 無料版MRDownからの手動インポート。初版で未実装なら、その旨を明記する
- 返金: 購入から30日以内
- AI説明: オンデバイス経路とBYOK経路を分け、モデルへ送る内容を明記する
- LP: MRDown GitHub PagesにMrkDownセクションを追加する
- v1の販売機能: AI diff explanation。将来機能はロードマップ扱い

販売導線を公開する前に、Polar側で次を作る。

- 商品名: `MrkDown`
- Benefit: License Keys（prefix `MRKDOWN`、activation limit 3、customer admin enabled）
- Benefit: File Downloads（1つだけ）
- Checkout Link: publicに共有する購入リンク

商品を作ったら、`products/mrkdown.conf` の `POLAR_PRODUCT_ID` を実IDに差し替える。
Polar Access Token は次の Keychain サービスへ保存する。

```sh
security add-generic-password -U -a "$USER" -s "com.hitoshi.MrkDown.polar-access-token" -w
```

初回販売公開のブランチでは、`README.md` / `README.ja.md` のProducts表へMrkDown行を追加し、
Download欄をPolar Checkout Linkへ向ける。DMGへの直リンクは書かない。

### Polar-only release script

次回以降のMrkDown公開は、GitHub Releaseを作らずに次で行う。

```sh
cd /Users/hitoshi/Git/MrkAppRelease
sh scripts/release-polar-only.sh mrkdown 1.0.1 --check
sh scripts/release-polar-only.sh mrkdown 1.0.1 --publish
```

既にビルド済みDMGを作ってある場合は、ビルドを省略してそのDMGをPolarへアップロードできる。

```sh
sh scripts/release-polar-only.sh mrkdown 1.0.1 --publish \
  --dmg ../MrkDown/src-tauri/target/aarch64-apple-darwin/release/bundle/dmg/MrkDown_1.0.1_aarch64.dmg
```

このスクリプトが行うこと:

- `package.json` と `src-tauri/tauri.conf.json` のversion更新
- `npm test`、sidecar生成、Tauri Apple Silicon DMGビルド
- Developer ID署名の検証、Apple公証、staple、Gatekeeper評価
- Polar File Downloads BenefitへのDMGアップロード
- `MrkAppRelease` の `README.md` / `README.ja.md` へのRelease History追記
- MrkDownソースrepoの `vX.Y.Z` tag作成、必要なcommitとpush

最後に、Polar購入者ポータルから実際にDMGをダウンロードし、スクリプトが表示するSHA-256と一致するか確認する。

例:

```md
| MrkDown | [Sold through Polar](https://buy.polar.sh/polar_cl_0ZFDepQfKNP0v374jKC5AApEKjtQRs0gowqVs3x6YvO) | [English](https://github.com/MR-TABATA/MRDown) · [日本語](https://github.com/MR-TABATA/MRDown/blob/main/README.ja.md) |
```

```md
| MrkDown | [Polar で販売](https://buy.polar.sh/polar_cl_0ZFDepQfKNP0v374jKC5AApEKjtQRs0gowqVs3x6YvO) | [English](https://github.com/MR-TABATA/MRDown) · [日本語](https://github.com/MR-TABATA/MRDown/blob/main/README.ja.md) |
```

MrkDownはApple Silicon専用である。公開文面では、MRDownの無料版はApple Silicon/Intel両方、
MrkDownはApple Siliconのみであることを混同させない。

初回販売までに残る実装タスク:

1. MrkDown側にライセンスキー入力・検証UIを追加する。
2. Polar Product IDだけでなく、License Keys Benefit IDも照合対象にする。
3. MrkEditorと同じ再検証・オフライン猶予をTauri/Rust側で実装する。
4. 署名・公証済みApple Silicon DMGを作るローカル手順を確定する。
5. Polar購入者ポータルからDMGを実ダウンロードし、ローカル成果物とSHA-256を照合する。
6. checkout linkをProducts表とMRDown GitHub PagesのMrkDownセクションへ出す。

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

public trial型として追加した後は、まず`--check`で検証してから`--publish`する。

```sh
sh scripts/release.sh <product> <version> --check
sh scripts/release.sh <product> <version> --publish
```

ただし、これはpublic trial型にする場合だけである。MrkEditorと同じPolar-only paid型では、
上の「Polar-only paid型の手順」に従い、`release.sh --publish` は使わない。

別製品としてMrkDiffを配布する場合も、同様に`products/mrkdiff.conf`を追加する。

## 秘密情報

Polar Access Token、Apple ID、App用パスワード、証明書の秘密鍵をリポジトリへ保存しない。
設定ファイルに置くPolarのOrganization ID・Product ID、証明書のSHA-1は秘密情報ではない。
