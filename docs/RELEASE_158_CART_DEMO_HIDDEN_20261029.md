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
