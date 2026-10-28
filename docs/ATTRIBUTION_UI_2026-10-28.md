# 商品詳細の出典・提供元表示（2026-10-28）

- 商品詳細下部の出典と提供元リンクを12pt、グレーの黒（#616161）に変更。外部リンクアイコンは13pt、行の最小高さは36ptに縮小。
- 確認日とAmazonアソシエイトの説明も同じ色に統一。文言・リンク先・表示条件は維持し、蔵元公式サイトなど他のリンクの表示は変更していない。
- 配信バージョンは5.0.25（152）。

## 確認

- 変更ファイルの整形、静的解析、差分チェックに問題なし。
- 全体の静的解析はエラー0件。既存の警告37件・info 395件あり。
- productionの署名付きアーカイブとApp Store IPAの作成成功。
- アーカイブのバージョン、ビルド番号、Bundle ID（okinawa.molasoft.sakepedia）と、地図APIキーが空・未解決でないことを確認。
- 保存先: build/ios/archive/Runner.xcarchive、およびXcode標準保存先2026-10-28/SAKEPEDIA 152.xcarchive。

## 送信状況

- Xcode Organizerで通常のApp Store Connect配信を開始した際、認証エラーが表示された。再ログインを依頼したが、ログにはXcode内部のITunesSoftwareService接続エラー（NSCocoaErrorDomain 4097）が記録されていた。認証情報の失効と断定できる状態ではなかった。
- 古い配信エラー画面を閉じ、完成済みアーカイブで通常のApp Store Connect配信をやり直すと、追加のログインなしで送信が進んだ。
- Organizerで `App upload complete` と `mola_gemini_flutter_template 5.0.25 (152) uploaded` を確認。アップロード完了。Internal Onlyではない。
- Apple側の処理完了・TestFlightでの表示・一般公開・審査提出は未確認。ストア側の審査提出はユーザーが担当する既存方針を維持。
