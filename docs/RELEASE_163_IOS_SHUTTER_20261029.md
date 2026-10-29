# iOS 5.0.33（163）配信記録

メニュー撮影のシャッターをラベル撮影と同じデザインへ変更し、iOS配信する依頼に対応。

- メニュー撮影シャッターを76pt、白4pt枠、黄色（#FFD54F）背景、紺（#1D3567）のカメラアイコン（34pt、camera_alt_rounded）へ統一。ラベル撮影の値と同一。
- 撮影中は小さな進捗表示とし、連打防止・エラー時の再試行・ライト切替・撮影後の確認フローを維持。
- 写真を参照して描き直した日本酒瓶の補助枠（`3a9da40`）を初めて配信に含めた。首から胴へ長く滑らかに広がり、直線部は下側約3割。[補助枠の記録](SAKE_BOTTLE_CAPTURE_GUIDE_20261029.md)。
- 実装・版番号のコミット `272bab1`。

## 検証・配信

- メニュー撮影・解析・履歴・ラベル撮影の関連47テスト成功。撮影連打、失敗・再試行、カメラ権限、バックグラウンド復帰、ガイド切替・小画面を含む。
- 全体analyzeはエラー0、既存の警告・情報419件。
- productionのrelease archive成功。アーカイブ内で5.0.33（163）、Bundle ID、非空・展開済み地図設定、production指定、イラスト画像同梱を検証。AOTバイナリが162と異なることを確認。秘密値は出力・記録しない。
- CLI exportの既知のアカウント/証明書エラー後、完成した同じアーカイブをXcode OrganizerのApp Store Connect（testing and release）で送信。Internal Onlyは選択していない。
- **2026-10-29 21:38 JST、5.0.33（163）のApp upload complete / Uploaded to Appleを確認。**
- Appleの処理完了・TestFlight利用可能状態は未確認。本番審査提出は従来のユーザー意向に従い未実施。
- Android配信・バックエンド配備なし。元チェックアウトの未コミットiOS設定2ファイルを保全。

[撮影画面プレビュー](images/release_163_20261029/menu_camera.png) / [送信完了画面](images/release_163_20261029/ios_upload.png) / [検証・送信記録](data/release_163_ios_20261029.json)
