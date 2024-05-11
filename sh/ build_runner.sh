flutter pub run build_runner watch --delete-conflicting-outputs
## watchにしてるので変わったら勝手に動いてくれる

#アイコン生成 スプラッシュ生成
flutter pub run flutter_native_splash:create
flutter pub run flutter_launcher_icons

#androidリリース
flutter build appbundle