# iOS 5.0.29（159）App Store申請用の再送信

158を `TestFlight Internal Only` で送ったためApp Storeの審査提出に使用できなかった。今回の配信方式の選択ミスとして、同じ内容を159へ更新し、Organizerの `App Store Connect` 方式で送り直した。マーケティングバージョンは5.0.29のまま。Androidの審査申請済み158は変更していない。

- 実装・版番号・手順修正: `9b6deaa`。AGENTS.mdを修正し、本番用は通常のApp Store Connect、内部専用は明示依頼時のみとした。
- iOS release archive成功。Bundle ID `okinawa.molasoft.sakepedia`、5.0.29（159）、非空・解決済みの地図キーを確認。秘密値は出力・記録していない。
- 送信用アーカイブ `build/ios/archive/SAKEPEDIA-5.0.29-159.xcarchive`。
- OrganizerでApp Store Connectを明示選択し、「testing and release」の説明と「Upload for App Store Connect」の進行画面を確認。内部専用を選んでいない。
- 初回の認証エラーは配布ダイアログを閉じて再試行すると解消。ログイン・証明書変更は不要だった。
- 2026-10-29 17:23 JST、159の「App upload complete」と「Uploaded to Apple」を確認。
- Appleの処理完了・App Storeの申請画面でのビルド選択は未確認。ブラウザのApp Store Connectは未ログインのため、159が選択可能になったと断定しない。審査提出・一般公開はしていない。
- 元のチェックアウトをmainへfast-forwardし、修正した配信手順を反映。元からある未コミットのiOS設定2ファイルは前後のハッシュ一致で保全を確認。

公式仕様: [Appleのテスト配信説明](https://developer.apple.com/tutorials/develop-in-swift/test-your-beta-app)、[配信方式](https://help.apple.com/xcode/mac/current/en.lproj/dev31de635e5.html)。TestFlight Internal OnlyのビルドはApp Review提出・App Store配信へ使用できない。通常App Store Connect方式はTestFlightとApp Storeの両方に対応する。
