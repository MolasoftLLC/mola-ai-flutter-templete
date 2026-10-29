# メニュー撮影ボタンのイラスト化（未配信）

2026-10-29の追加依頼。「メニューを撮影」の黄色ボタンを白背景と角丸24、オレンジ3px枠に変更。色は下部スキャンボタンの枠と同じ `#FF914D`。白地で読む文字は紺 `#17395F`。

カメラアイコンを、スマートフォンでメニューを撮影する手描き風イラストへ差し替え。画像は装飾として読み上げ対象から外し、ボタン全体の「メニューを撮影」というラベルと操作は維持。撮影・解析・履歴の処理は変更しない。

- 保存したアプリ用画像：`assets/images/menu_capture_illustration.png`（672 KiB、透過PNG）。既存のassets/imagesディレクトリ設定で同梱。
- 生成方式：imagegenスキルに従い、内蔵 `image_gen.imagegen` を使用。CLIは不使用。生成画像を変更せずプロジェクトへコピーし、画面で縮小表示。
- 原本：`/Users/mukae-mini/.codex/generated_images/01a17b75-0932-74a0-bd6e-87df46404c69/exec-058ce133-3abe-43ee-98ad-696df465c73a.png`
- [修正後の画面](images/menu_capture_illustration_20261029/entry.png)（390×844、履歴・写真はテスト用）。
- 既存のメニュー画面関連16テスト成功。白いボタンの枠色、撮影・写真選択・履歴の各操作、撮影後の遷移を確認。
- `flutter analyze`：エラー0。既存警告・情報は残る。
- ブランチ：`codex/menu-capture-illustration`。版番号更新、アプリの配信、サーバー配備、審査申請なし。送信済みiOS 161にはこの変更は含まれない。

## 生成プロンプト（原文）

Use case: illustration-story. Asset type: small hand-drawn illustration for the SAKEPEDIA mobile app's 'photograph a menu' button. Create a charming, clean hand-drawn editorial doodle clearly showing ONE human hand holding a smartphone aimed at an upright Japanese restaurant drinks menu card. The menu card should be behind and slightly to the left of the phone, and the phone screen visibly contains the same menu rows with four tiny orange viewfinder corner marks. The hand enters from the lower right. Main subject is the menu being photographed, not a standalone camera icon. Minimal irregular rounded ink strokes, warm approachable Japanese cafe stationery illustration, restrained navy #17395F outlines, orange #FF914D highlights, white/very pale warm fills in paper and smartphone, very light peach hand. Horizontally balanced compact composition with all subjects contained, clearly readable when displayed at about 150 by 90 pixels. Actual transparent background outside the subjects, no background rectangle or scene, no shadows, no gradients, no decorative flowers, no bottles, no extra hands or fingers. No text, no letters, no words, no numbers, no watermark. Use small drawn horizontal strokes and dots to suggest menu rows. Crisp generous linework suitable for a small UI illustration.
