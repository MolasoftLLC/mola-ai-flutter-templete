# iOS 5.0.31（161）配信記録

2026-10-29の「iOSだけ配信」に対応。直近5件・統一した履歴一覧/詳細・無限スクロール・場所変更・撮影直後の端末標準確認省略を含む。実装は `1eab371` / `ac8bca0`。[実装と検証](MENU_HISTORY_REFRESH_20261029.md)。

## Appleへの送信

- production指定でrelease archiveを作成。版番号5.0.31、ビルド161、Bundle ID `okinawa.molasoft.sakepedia` をアーカイブ内で確認。
- アーカイブの地図キーが非空かつ展開済みで、FlutterのFLAVORがproductionであることを確認。秘密値は出力・記録しない。
- CLI exportは既知のNo Accounts / iOS Distribution証明書エラー。完成した同じアーカイブをXcode Organizerに取り込み、**App Store Connect（testing and release）** で送信。
- **2026-10-29 20:23 JSTにUploaded to Apple / App upload completeを確認。** TestFlight Internal Onlyは選択していない。
- Appleの処理完了・TestFlightでの利用可能状態は未確認。
- 本番審査への提出は未完了。ChromeのApp Store Connectタブを閉じて開き直し、Safariでも再読み込みしたが、ブラウザの認証が完了せず申請画面へ進めない。Safariでのログイン完了をユーザーに依頼済み。Xcodeからのアップロードは認証し直さずに成功している。
- Androidのストア送信・製品版トラック更新・審査申請は実行していない。以前の160の扱いも変更していない。

[送信記録](data/release_161_ios_20261029.json) / [アップロード完了画面](images/release_161_20261029/ios_upload.png)

## 履歴APIの本番反映

- iOSの追加読み込みに必要なバックエンド `93f562a4467266bda8cf661d425d23d74e1d09dd` をmainに反映。
- [GitHub Actions 40864727085](https://github.com/MolasoftLLC/molasoft-ai-central/actions/runs/40864727085) のビルド・整合性検証・本番配備が全てsuccess。
- 本番のHEAD、対応するマイグレーション適用、4列の複合インデックスを確認。
- 既存履歴で2件ずつの第1/第2ページを本番サービスから読み取り、両ページの4件が重複しないことを確認。個人情報は出力せず、確認用データの作成も行わない。
- 公開HTTPS `/health` はproductionでok。新APIへの未認証アクセスは401。
- [本番検証の記録](data/release_161_backend_20261029.json)。既存Androidにも互換なAPI変更のみ。

## 保全

- Flutter関連71テスト、Android debug APKは実装時に成功。今回のiOS release archiveも成功。
- 元チェックアウトの未コミットiOS設定2ファイルを保全。配信作業は隔離チェックアウトで実施。
