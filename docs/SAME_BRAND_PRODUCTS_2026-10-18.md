# 同じ銘柄の商品とiOSビルド150（2026-10-18）

## 変更内容

- 日本酒詳細の「みんなの評価」の直前へ「同じ銘柄の商品」を配置。
- ホームの最近調べたお酒と横スクロールカードを共通化。画像・商品名・マッチ度を表示し、現在の商品は除外。
- 「もっと見る」は最近調べたお酒の一覧と同じカード部品で、画像・酒蔵・マッチ度・レーダーチャートを表示。
- 新着順を標準とし、古い順・マッチ度順も選択可能。プロフィールは最大50IDずつ軽量APIで取得。
- GET /api/sakes/:sakeId/related-products は銘柄IDで絞り、非公開・重複・却下を除き、IDカーソルで続きも取得。AIやEC検索は実行しない。既存overviewの20件制限で一覧が切れないようにした。

## 確認

- 変更したFlutterファイルの静的解析: No issues found。
- API TypeScript: tsc --noEmit成功。
- 本番API稼働SHA: 2975861e461d0f503bf4fdf4d4f70271cc38462d。
- GitHub Actions 39053469811: 整合性チェック・ビルド・デプロイ・公開healthが成功。
- 本番でID4394（龍力秋津）の関連商品をlimit=2で4ページ取得。7商品が同じ銘柄ID3279、重複なし、ID4394自身の混入なし。healthは200。
- 実機の新UI表示確認は未実施。

## iOS

- ソース: 00d53e9（UI）、9301624（149）、e47a815（150）。最終配信対象は5.0.23 (150)。
- productionの署名付きアーカイブ作成成功。地図キーが解決済みであること、Bundle ID、バージョンとビルド番号、プライバシーマニフェスト23件を確認。
- CLI exportは既存のNo Accounts / iOS Distribution証明書エラー。完成済みアーカイブをXcode Organizerの通常App Store Connect経路で送信。
- アーカイブはbuild/ios/archive/Runner.xcarchive、およびXcode標準保存先2026-10-18/Runner 150.xcarchive（149の失敗アーカイブも保持）。
- 149はAppleの90186 / 90062で拒否。5.0.22はすでに承認済みで新規ビルド受付が終了していたため、5.0.23 (150)へ更新して再作成。
- 150はOrganizerで `App upload complete` と `mola_gemini_flutter_template 5.0.23 (150) uploaded` を確認。通常のApp Store Connect経路で送信完了。Internal Onlyではない。
- Apple側の処理完了・TestFlightでの表示・一般公開は未確認。審査提出は未実施（ストア側はユーザーが担当する既存方針を維持）。

## Androidの対応可能範囲

- android/key.properties、参照先の署名キーストア、Firebase設定の存在を確認。
- 署名付きAABの作成用・Google Play送信用スクリプトが存在する。今回はAndroidのビルド・送信は実行していない。
- 自動送信用のPLAY_STORE_SERVICE_ACCOUNT_JSONは未設定。fastlaneコマンドも現在のPATHでは未検出。Google Playへの送信は認証設定またはPlay Consoleのログインが必要。
