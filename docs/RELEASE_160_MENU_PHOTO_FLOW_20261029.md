# 5.0.30（160）メニュー解析の2ステップ化

2026-10-29の配信依頼に対応。実装は `c9342ef`、版番号更新は `9b522bb`。撮影・写真選択後の確認、任意の切り抜き、元写真の復元、中止・失敗後の再試行、直近の解析履歴を含む。詳細は [実装・検証記録](MENU_PHOTO_FLOW_20261029.md)。

## iOS

- `5.0.30+160` のrelease archiveを作成。Bundle IDは `okinawa.molasoft.sakepedia`。
- アーカイブ内の地図キーが非空・展開済みであることを確認。秘密値は出力・記録していない。
- `build/ios/archive/SAKEPEDIA-5.0.30-160.xcarchive` に保存。以前の158・159のアーカイブも保全。
- CLI exportはNo Accounts・iOS Distribution証明書エラーで失敗したため、完成済みアーカイブをXcode Organizerから送信。再ビルド・証明書変更は不要だった。
- **App Store Connect** を明示選択。「testing and release」と「Upload for App Store Connect」を確認。内部テスト専用は使用していない。
- **2026-10-29 19:35 JST（Organizerの分単位表示）にUploaded to Appleを確認。** 「App upload complete」の画面も保存。
- Appleの処理完了・TestFlightでの利用可能状態は未確認。本番審査への提出はまだ行っていない。
- 審査申請用のApp Store Connectは、Chromeで既存タブを閉じて開き直し、Xcodeの「Open App Store Connect」からも再試行。Safariでもログイン画面へ戻ることを確認。ブラウザの認証が必要。Xcodeからのアップロード自体は認証のやり直しなしで成功している。

[送信記録](data/release_160_ios_20261029.json) / [アップロード完了画面](images/release_160_20261029/ios_upload.png)

## Android

- `command/android_release.sh` で署名付きAABを作成。パッケージは `okinawa.molasoft_ai.sake`、5.0.30（160）。
- 署名、パッケージ、版番号、地図キーの非空・展開済みを確認。Googleが受け付けたAABのSHA256が作成物に一致。
- AAB: `build/app/outputs/bundle/release/app-release.aab`、76,130,591 bytes。
- SHA256: `c4c903e6ce5bd44a2584b4c9cac94d67e7ba8c79cf1868813a7ccbed68f485f3`。
- 読み込み直後のブラウザは古い審査中表示だったが、APIと画面の更新により、前の158が公開済みであることを確認。既存審査の取り消しは行っていない。
- 製品版トラックを160へ設定し、編集の検証とcommitが成功（2026-10-29T10:36:44.855Z）。競合する審査を取り消さない `ERROR_IF_IN_REVIEW` を使用。
- APIの `NOT_SENT_FOR_REVIEW` だけで終了せず、Play Console公開の概要を確認。「審査中の変更」に **5.0.30** があり、Googleのクイックチェックが終わると審査へ自動送信する旨を確認。申請は受付済みで、自動チェック中。
- 管理対象の公開は既存設定のオフを維持。審査承認後は自動公開となる。160の承認・一般公開は未確認。
- ストア情報・画像・権限・契約・ポリシー回答は変更していない。

[受付記録](data/release_160_android_20261029.json) / [Play Console確認画面](images/release_160_20261029/android_review.jpg)

## ソース・作業内容の保全

- 隔離した既存チェックアウトでビルドし、元チェックアウトの未コミットiOS設定2ファイルを保全する。
- 本番データへの新規テスト解析・履歴投入は行っていない。
- 57件の関連テストとiOS・Android debugビルドは実装時に確認済み。配信用releaseビルドも両方成功。
