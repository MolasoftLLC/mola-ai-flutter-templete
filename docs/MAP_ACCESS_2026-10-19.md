# Android地図表示と位置情報の案内

## 地図全体が白・灰色になる問題

- 配信済みAndroid版150が参照するMaps APIキーとCloud Console上のAndroid用キーが同一であることを、キーを表示せず照合した。
- Maps SDK for Androidは許可対象に含まれていたが、Androidアプリ制限には開発用・アップロード用署名しか登録されていなかった。
- Play Consoleで実際のアプリ署名を確認し、同一パッケージ`okinawa.molasoft_ai.sake`のPlay署名SHA-1を追加した。既存の2署名は維持した。
- Cloud Consoleを開き直し、3署名が保存されていることを確認した。反映に最大5分かかる表示がある。アプリ再配信は不要。
- Android端末はADBに接続されていないため、実機で地図タイルが表示されることは未検証。

## アプリ内の案内（iOS / Android共通）

- 地図画面で位置情報の利用可否を確認し、未許可・継続的な拒否・端末の位置情報オフ・取得失敗を区別する。
- 中央の案内から、OSの許可リクエスト／アプリ設定／位置情報設定／再取得へ進める。
- 「現在地を使わずに地図を見る」で案内を閉じられる。地図閲覧自体は位置情報の許可を必須にしない。
- 設定から戻った際に許可状態を再確認し、許可された場合は現在地へ移動する。画面を開くだけでOSの許可リクエストは出さない。
- 地図タイルの認証失敗を位置情報の権限不足として扱わない。現在のGoogle Maps Flutter APIはタイル認証失敗の直接通知を公開していない。
- 変更ファイルの静的解析は成功。実機の拒否・設定復帰・表示は未検証。新しいアプリの配信は未実施。

公式資料: [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)、[Maps SDKの位置情報](https://developers.google.com/maps/documentation/android-sdk/location)
