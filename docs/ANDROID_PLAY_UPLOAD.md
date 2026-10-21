# Android Google Play自動送信

## Macの設定

- `fastlane`をインストールする（Homebrewの場合は`brew install fastlane`）。
- Google Play Android Developer APIを有効にし、送信用サービスアカウントにPlay Consoleで対象アプリの閲覧・必要なトラックへのリリース権限を付与する。
- JSONキーはリポジトリ外に保管する。キー本体をGitやチャットへ貼り付けない。
- `command/android_upload.local.env`に以下を設定する。このファイルは既存の`*.env`ルールでGit対象外。パーミッションは`600`にする。

```bash
PLAY_STORE_SERVICE_ACCOUNT_JSON='/absolute/path/to/play-service-account.json'
```

環境変数`PLAY_STORE_SERVICE_ACCOUNT_JSON`を明示した場合は、そちらを優先する。

## 接続確認（ビルド・アップロードなし）

```bash
bash command/android_upload.sh --check
```

キー認証と、対象アプリの指定トラックのバージョン取得を確認する。閲覧成功は署名一致・アップロード権限・審査通過まで保証するものではない。

## 送信

`pubspec.yaml`のビルド番号を未使用の番号へ更新し、署名設定`android/key.properties`とkeystoreを用意してから実行する。

```bash
RELEASE_CONFIRM=1 bash command/android_upload.sh
```

デフォルトは`internal`トラック・`draft`。公開はしない。`PLAY_TRACK`と`PLAY_RELEASE_STATUS`は配信先が確定したときだけ指定する。`RELEASE_CONFIRM=1`は確認プロンプトの省略であり、公開先を変更する指定ではない。

接続確認とAABビルド、Google Playアップロード、審査、一般公開はそれぞれ結果を分けて確認する。

公式資料: [Google Play APIの設定](https://developers.google.com/android-publisher/getting_started)、[fastlane supply](https://docs.fastlane.tools/actions/supply/)

## 2026-10-19の設定結果

- このMacにfastlane 2.238.0をインストールした。
- リポジトリ外の送信用JSONをローカル設定から参照する。画像解析用の別アカウントは使用しない。
- 最初の接続は権限エラーだったが、権限設定後の再確認でキー認証・対象アプリ`okinawa.molasoft_ai.sake`のinternalトラック取得に成功した。現在のバージョンコードは`63`。
- 署名付きAAB `5.0.23+150`（74.7MB）のビルドとGoogle Playアップロードが成功。`internal`トラックへ`completed`で反映した。
- 配信後のAPI再取得でもinternalのバージョンコード`150`を確認した。本番トラックには送信していない。本番リリース権限と実機でのインストール・動作は未検証。
- 自分のAndroid端末では、Play Consoleの内部テストのテスターに端末のGoogleアカウントを登録し、同画面の参加リンクから参加してGoogle Playでインストールする。
