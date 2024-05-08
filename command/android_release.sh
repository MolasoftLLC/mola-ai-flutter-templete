#pubspec.yamlのバージョンを変えてから実施する
flutter build appbundle --release --no-sound-null-safety --dart-define=FLAVOR=development

#フィンガープリント出力
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

