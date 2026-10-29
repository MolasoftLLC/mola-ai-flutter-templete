# 5.0.29（158）デモ用比較カートの一時撤去

2026-10-29、ホームの「お酒えらび・デモ」カードと比較カートへの遷移・importを削除した。比較デモ以外の解析・検索・保存の実装は変更していない。一時撤去のためデモのソースと端末内の保存データは削除せず、通常アプリ側からの参照・入口をなくした。比較デモ配下以外からのimport／SakeComparisonPage参照は0件。

実装コミット: `a9d336c`（mainへpush済み）。元チェックアウトの未コミットiOS設定は変更していない。

## 検証・配信

- ホーム関連の既存テスト4件成功。
- 全体の静的解析は既存の指摘432件が残る。errorなし、変更したnew_home_page.dartへの指摘なし。差分チェック成功。
- iOS release archive成功。Bundle IDは `okinawa.molasoft.sakepedia`、5.0.29（158）を確認。
- アーカイブ内の地図キーが非空・展開済みであることを確認。秘密値は出力・記録・コミットしていない。
- CLI exportはNo Accountsで失敗したが、完成済みアーカイブをOrganizerで配布し成功。証明書・アカウント設定は変更していない。
- Organizerで `TestFlight Internal Only` により送信。2026-10-29 16:46 JST、「App upload complete」と同ビルドの「Uploaded to Apple」を確認。
- Apple処理完了とTestFlight利用可能状態は未確認。App Store審査提出・一般公開はしていない。

## Android

同じコミットの5.0.29（158）から、`command/android_release.sh`で署名付きAABを作成。必要なJava 17をこのMacへ導入した。アプリの追加コード変更はなし。元の署名・Firebase・地図設定を非公開のローカル設定として利用し、秘密値を出力・コミットしていない。

- パッケージ `okinawa.molasoft_ai.sake`、5.0.29（158）、非空の解決済み地図キーを結合後マニフェストで確認。
- AABの署名検証成功。アップロード後にGoogleが返したバージョンコードとSHA256が作成物に一致。
- Google Play Developer APIの編集検証とcommitが成功。新たな編集セッションの再取得でinternalのname=`5.0.29`、status=`completed`、versionCodes=`[158]`を確認。
- productionは5.0.24（151）のままで、取得前後の一致を確認。本番トラックへは送っていない。
- 実機でのインストール・更新反映は未確認。ストア情報、画像、テスターの権限、契約・ポリシー申告は変更していない。

送信・反映記録: [release_158_android_20261029.json](data/release_158_android_20261029.json)。

## Android製品版の審査申請

その後のユーザー依頼により、同じSHA256・ビルド158を製品版へ指定し、編集検証・commitに成功。内部テストのファイルを再利用し、再ビルド・再アップロードはしていない。既存の審査を取り消さないよう `changesInReviewBehavior=ERROR_IF_IN_REVIEW` を指定した。

commit直後のリリース状態APIは `RELEASE_LIFECYCLE_STATE_NOT_SENT_FOR_REVIEW` だったため、APIのcompletedだけで審査中と断定せずPlay Consoleの公開概要で確認した。同画面の「審査中の変更」に製品版5.0.29があり、「一般的な問題のクイック チェックを実行する」「チェックが完了するとすぐに審査のために送信されます」と表示。申請は受け付けられ、現在は自動チェック待ちであり、審査の承認済み・一般公開済みとはしていない。

管理対象の公開は既存設定でオフ。変更していないため、審査承認後は自動公開される。未関連のストア情報・画像・ポリシー回答・契約・権限は変更していない。画面を確認する際に新しい規約への同意は求められなかった。

[申請受付の記録](data/release_158_android_review_20261029.json)。
