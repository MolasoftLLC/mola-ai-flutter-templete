# mola_gemini_flutter_template

A new Flutter project with Gemini.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 日本酒マップの設定

Places検索とPlace DetailsはFirebase認証付きの自社APIから実行します。Flutterへ
Places APIキーを置かないでください。APIサーバー側でPlaces API (New)だけに制限した
`GOOGLE_PLACES_SERVER_API_KEY`を設定します。

地図表示にはMaps SDK for Android / iOSを使います。AndroidとiOSで別々のキーを作り、
それぞれMaps SDKだけにAPI制限を設定します。

### Android

`android/local.properties`へ次を追記します。このファイルはGit管理外です。

```properties
MAPS_API_KEY=Androidアプリ制限済みのMaps SDKキー
```

Cloud Consoleではパッケージ名`okinawa.molasoft_ai.sake`と、デバッグ／Google Play
アプリ署名鍵それぞれのSHA-1を登録してください。

### iOS

`ios/Flutter/MapsKeys.xcconfig.example`を`MapsKeys.xcconfig`へコピーし、値を設定します。
このファイルもGit管理外です。Cloud Consoleでは実際のBundle IDをiOSアプリ制限へ
登録してください。

```xcconfig
GOOGLE_MAPS_API_KEY=iOSアプリ制限済みのMaps SDKキー
```

### 実機で確認する

1. 端末の位置情報をオンにします。
2. アプリを実機へインストールして起動します。
3. 保存済み日本酒の詳細画面で「飲んだ場所を追加」を押します。
4. 「近くで探す」を選び、位置情報は「Appの使用中は許可」にします。
5. 周辺店舗が距離順に表示されることを確認します。
6. 「名前で探す」で店名検索と手入力も確認します。

候補が表示されない場合はサーバーのPlaces設定とFirebase認証を、地図が表示されない
場合はMaps SDKの有効化、課金、アプリ制限、パッケージ名・Bundle ID・SHA-1を確認します。
