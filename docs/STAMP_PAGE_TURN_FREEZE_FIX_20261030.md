# ご酒印帳のページめくり停止修正（2026-10-30）

## 原因

5.0.43 (173) のページめくり準備処理が `RenderRepaintBoundary.debugNeedsPaint` を参照していた。Flutter 3.44 のこの getter は assert 内でのみ late 変数を初期化するため、release/profile では例外になる。準備中フラグを立てた後で例外となり、ページ変更と操作制限解除まで到達しなかった。県変更・紙面ページ送りで共通の処理を使用している。

## 修正

- アニメーション使用時は全モードで描画完了後に紙面を取得する。開発専用 getter に依存しない。
- モーション低減時は従来どおり即時に変更する。
- 表紙を繰り返しめくらず、表示中の紙面をめくる動作を保持。
- 描画待ちの間にスワイプが取り消された場合も操作が復帰するテストを追加。

## 検証

- page turn / book opening / book の widget tests: 33件成功。
- flutter analyze: 418件（既存と同数）、今回の変更ファイルに指摘なし。
- 実際の page turn 実装を使った独立 macOS release ハーネスで、順送り・逆送り・描画前スワイプ取消・スワイプ確定後にすべて isBusy=false とページ状態を確認。assert は無効の実行モード。
  - `/tmp/sakepedia-stamp-release-smoke/lib/main.dart`
  - `/tmp/sakepedia-stamp-release-smoke.log`: RELEASE SMOKE PASS
- iOS実機での修正版検証は未実施。

## 配信状態

この修正は未配信。公開中の173には反映されていない。同じ作業ブランチには、自分のラベル解析・自分の記録保存に酒印取得を限定する修正（8f62146）も含む。
