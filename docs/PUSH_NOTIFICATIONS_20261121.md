# SAKEPEDIA お知らせ通知（2026-11-21）

管理画面 `/push-notifications` からタイトル・本文を確認し、1端末へのテストまたは受信ON端末への通知を送る。実際の通知送信は未実施。履歴のacceptedはFCM受付であり配達・開封数ではない。トピックは `sakepedia_announcements_v1`、開発アプリは `sakepedia_announcements_dev_v1`。個別ユーザー通知には使わない。

## 反映と前提

1. Backend migration `20261121010000_create_app_push_notifications.js` とAPIを反映する。旧admin UIは変更しない。
2. active Next.js admin のナビゲーション・API中継・送信画面を反映する。
3. アプリの通知設定、Android権限、iOS entitlements/background modesを含む新ビルドを配布する。リリース時は既存通り `--dart-define=FLAVOR=production`。
4. Firebaseプロジェクト `sakepedia-5c50b` のFCM v1 APIは有効（コンソール実測）。iOS APNs認証キー・証明書は開発/本番とも未登録（コンソール実測）。Apple DeveloperのAPNsキー作成・Firebase登録とPush capability対応の署名プロファイルが必要。既存ASCアップロードキーはAPNsキーではない。
5. アプリ「マイページ→設定→お知らせ通知」でONにし、テスト用トークンをコピーして管理画面から1端末へ送信する。前面・背面・停止中からの起動、OFF後の受信停止、再起動後の設定維持を実機で確認する。一斉送信はこの検証後に管理者が明示操作する。

## 保全・再送

送信IDをDBで先に確保し、同じIDでの再確認は二重送信しない。送信結果不明/処理中も自動再送しない。通信切断後は履歴を確認する。FCM受付後にDB更新が失敗した場合はsendingのままになり得るため、到達済みの可能性があるとして扱う。履歴に端末トークンは保存せず、ハッシュに含めて内容変更を防止する。Firebaseエラー本文は保存・表示しない。

アプリは初回起動で許可を求めない。OFF時の通信失敗は停止未確認と表示して復帰時に再試行する。端末からのトピック購読解除が届くまでバックグラウンド通知を完全には停止できない。OS設定での通知OFFは端末側で即時反映される。

公式参考: https://firebase.google.com/docs/cloud-messaging/flutter/get-started

## 検証実績

- Backendビルド・旧管理UI境界チェック成功。通知固有3テスト（並行受付、再実行不変、変更ID競合、不明結果の保全）成功。商品整合性449件、HTTP4件成功。
- Next.js本番ビルド・型チェック成功。
- 本番の既存Firebase資格情報でFCM dry-run成功。通知の実送信なし。
- Flutter通知固有3件成功。既存マップ/導線16件成功。全体399成功/13失敗は変更前の独立worktreeでも同じ399成功/13失敗（既存UIテスト）。静的解析エラー0。
- iOS Simulatorのarm64単一構成でXcode BUILD SUCCEEDED。Flutter CLIの全Simulator構成はSDK側のarchitecture文字列判定で失敗したため、Xcodeで単一構成を確認。APNs実機配送と配布版署名は未検証。
