# 文字スキャンの表示・認識範囲修正（191でTestFlight配信済み）

## 原因

- camera_avfoundation 0.10.3 の DefaultCamera.swift は captureVideoOutput の接続へ deviceOrientation を適用している。iOSの映像フレームはすでに正立しているが、190ではセンサーの90度をVisionへ渡し、もう一度回していた。
- プレビューは画面内へ切り抜いて表示する一方、OCR領域はネイティブ側の固定値だった。表示サイズや向きが変わっても同じ領域を使っていた。
- 前回の生成画像によるチャンネル試験は正立画像へrotation=0を渡していたため、カメラ呼出側の二重回転を検出できなかった。

## 修正

- iOSの映像はrotation=0。Androidは既存のセンサー・端末姿勢による回転を維持。
- ScanGeometryでBoxFit.cover相当の拡大・中央切り抜きと、表示領域内の黄色い枠を計算する。
- 枠を正立フレーム上の正規化座標へ逆変換し、同じ座標をネイティブOCRへ渡す。iOSではVisionの左下原点へ変換。固定ROIを廃止。
- Visionの認識結果座標はROI内基準なので、元フレーム座標と直接比較して再フィルターしない。AndroidのML Kitは正立フレームの行中心座標をROIと照合する。
- 音・画像送信・検索API・待機間隔は変更しない。

## 検証

- 範囲の逆変換、縦横表示・切り抜き、実際の表示枠とチャンネル引数、連続追加・検索の12テスト成功。
- iOSシミュレーターでネイティブVisionチャンネルを実行。1080×1920画像の上に南部美人、中央に浦霞、下に出羽桜を配置。中央ROIは浦霞だけ、上ROIは南部美人だけ、下ROIは出羽桜だけを返すことを確認。上下非対称ROIも検証し、原点変換の誤りを防ぐ。
- iOS Debugビルド、Android compileDebugKotlin成功。flutter analyzeはエラーなし（既存警告あり）。git diff --check成功。
- 物理iPhoneを使った店内カメラ確認は未実施。TestFlight190にはこの修正は含まれない。5.0.55 (191)でTestFlight配信を確認済み。
