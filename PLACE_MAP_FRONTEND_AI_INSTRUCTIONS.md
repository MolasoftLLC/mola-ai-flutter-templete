# 日本酒マップ機能：Flutter実装AI向け指示書

## 目的

SAKEPEDIAの保存済み日本酒と飲んだ店舗を紐づけ、次の双方向検索をFlutterアプリへ実装する。

- 日本酒名から、その日本酒が飲まれた店舗を地図で探す。
- 地図上の地域・店舗から、そこで飲まれた日本酒を探す。
- 自分の非公開記録と、他ユーザーが公開した記録を適切に分離する。

この指示書だけで判断せず、作業開始時に必ずリポジトリ直下の`AGENTS.md`、既存コード、API仕様を確認すること。既存の未コミット変更を破棄・上書きしないこと。コミット、push、デプロイは明示的に依頼された場合のみ行うこと。

## 現在の実装状況

- 詳細画面は`lib/presentation/my_page/saved_sake_detail_page.dart`。
- 場所選択UIは`lib/presentation/my_page/widgets/place_picker_sheet.dart`。
- 現在地取得には`geolocator`を使用している。
- 現在の`PlacePickerSheet.show()`は店名の`String`だけを返す。
- 現在の`Sake`モデルは`place`文字列だけを保持し、Place ID・住所・緯度・経度は保持しない。
- `lib/common/services/place_search_service.dart`はGoogle Places APIをアプリから直接呼び出している。これは暫定実装であり、サーバーの場所検索API完成後に自社API呼び出しへ置き換える。
- 公開状態は既存の`isPublic`で管理されている。
- ナビゲーションはホーム、タイムライン、スキャン、レコメンド、マイページで埋まっている。初版では下部ナビゲーションを変更せず、`new_home`から「日本酒マップ」画面へ遷移させる。

## 必須設計

### 1. 場所モデル

店名だけではなく、次のモデルを追加する。Freezed／JSON生成は既存の書き方へ合わせる。

```dart
class DrinkingPlace {
  String? venueId;            // サーバー内の店舗ID
  String? providerPlaceId;     // Google Place ID
  String displayName;
  String? formattedAddress;
  double? latitude;
  double? longitude;
  PlaceVisibility visibility; // private / public
}
```

`Sake.place`は既存データ互換のため削除しない。新規データでは`drinkingPlace`を優先表示し、古いデータは`place`へフォールバックする。手入力だけの場所は座標がないため、地図には表示しない。

### 2. 場所選択UI

`PlacePickerSheet.show()`の戻り値を`String?`から、Place ID・住所・座標を含む選択結果へ変更する。

- 「近くで探す」：現在地は検索時だけ取得する。
- 「名前で探す」：文字入力をデバウンスして検索する。
- 候補選択時：候補オブジェクト全体を詳細画面へ返す。
- 手入力時：`displayName`のみ設定し、Place ID・座標は`null`にする。
- 端末の現在地そのものはモデル・ローカルDB・APIへ保存しない。
- 位置情報拒否、恒久拒否、位置情報OFF、通信失敗、候補0件をそれぞれ処理する。
- Google由来の候補を表示するときは必要なGoogle表記を維持する。

### 3. Places検索の接続先

サーバー側実装が完成したら、FlutterからGoogle Places APIを直接呼ばない。次の自社APIを呼び出すRepositoryを`infrastructure/`または既存規約に合う場所へ追加する。

#### 周辺検索

```http
POST /api/places/search/nearby
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

{
  "latitude": 26.2124,
  "longitude": 127.6809,
  "radiusMeters": 1000,
  "locale": "ja"
}
```

#### 店名検索

```http
POST /api/places/search/text
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

{
  "query": "日本酒バー",
  "latitude": 26.2124,
  "longitude": 127.6809,
  "locale": "ja"
}
```

緯度・経度は店名検索では省略可能。検索リクエストの現在地をアプリ側で永続化しない。APIエラー本文やAPIキーをログへ出さない。

想定レスポンス：

```json
{
  "places": [
    {
      "providerPlaceId": "ChIJ...",
      "displayName": "日本酒処 サンプル",
      "formattedAddress": "沖縄県那覇市...",
      "latitude": 26.2124,
      "longitude": 127.6809,
      "distanceMeters": 180
    }
  ]
}
```

### 4. 飲んだ場所の保存

候補選択後、既存のメモ保存だけに依存せず、サーバーの専用APIで保存する。

```http
PUT /api/saved-sakes/{savedId}/place
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

{
  "providerPlaceId": "ChIJ...",
  "manualName": null,
  "placeVisibility": "public"
}
```

- Google候補の場合、緯度・経度や店名を信頼情報として送らない。サーバーがPlace IDから詳細を確認する。
- 手入力の場合は`providerPlaceId: null`、`manualName: "イベント名"`とする。
- 保存成功後のサーバーレスポンスをローカル状態へ反映する。
- 未ログイン時はローカル保存のみ可能とし、公開マップへは送らない。
- 公開投稿でも場所を非公開にできるよう、`isPublic`と`placeVisibility`を分離する。
- 公開へ切り替える際は「店舗情報も公開される」ことを画面上で明示する。

### 5. 日本酒マップ画面

`lib/presentation/sake_map/`配下にページ、Notifier、状態、必要なWidgetを分割する。既存のProvider／StateNotifier構成へ合わせる。

初版のUI要件：

- `new_home`に「日本酒マップ」への入口を追加する。
- 画面上部に日本酒名検索欄を置く。
- Google Map上に店舗単位のピンを表示する。
- 同じ店舗の複数記録を複数ピンにせず、1つの店舗ピンへ集約する。
- ピンには日本酒種類数または飲酒記録数を表示できる構造にする。
- ピンタップでボトムシートを開き、「この店で飲まれた日本酒」を表示する。
- 日本酒選択後は、その日本酒が飲まれた店舗だけを地図へ表示する。
- 地図移動完了時に表示範囲をAPIへ送り、範囲内の店舗を再取得する。
- リクエストをデバウンスし、古いレスポンスで新しい地図状態を上書きしない。
- ローディング、空状態、再試行、オフラインを実装する。
- 初回は最大200店舗などAPI上限を設ける。件数増加に備えてクラスタリング可能な構造にする。

Google Places由来の情報を地図上で表示するため、地図基盤はGoogle Mapsを使用する。`google_maps_flutter`の導入時は、現在のFlutter・Firebase依存関係と解決できる版を選び、Android／iOSの両方をビルド確認する。Places検索用キーとは別にMaps SDK用キーを作成・制限し、ソースコードへ直書きしない。

### 6. マップAPI

#### 表示範囲内の店舗

```http
GET /api/map/venues?swLat=26.10&swLng=127.60&neLat=26.30&neLng=127.80&zoom=13&sakeId=123&sinceDays=90
```

`sakeId`と`sinceDays`は任意。日本酒マスターIDがない場合に備え、確定済みの日本酒検索結果からサーバー用検索トークンまたは正規化名を渡せる設計にする。

想定レスポンス：

```json
{
  "venues": [
    {
      "venueId": "venue_123",
      "displayName": "日本酒処 サンプル",
      "latitude": 26.2124,
      "longitude": 127.6809,
      "sakeCount": 3,
      "recordCount": 5,
      "latestConsumedAt": "2026-09-01T12:00:00Z"
    }
  ]
}
```

#### 店舗で飲まれた日本酒

```http
GET /api/map/venues/{venueId}/sakes?sinceDays=90&cursor=...
```

表示文言は「現在飲める」ではなく、「この店で飲まれた日本酒」「この地域で飲まれた日本酒」とする。投稿実績だけでは現在の提供・在庫を保証できないためである。

### 7. 公開範囲

- みんなのマップには`isPublic == true`かつ`placeVisibility == public`だけを表示する。
- 自分のマップでは本人の非公開記録も表示できる。
- 他ユーザーの非公開記録、ユーザーID、メールアドレス、端末位置をレスポンスやログへ出さない。
- 店舗ピンから投稿者のリアルタイム滞在を推測しにくい表示にする。必要に応じて最新投稿時刻を丸めるか、公開反映を遅延させる。

## テスト要件

- `DrinkingPlace`のJSONシリアライズ／デシリアライズ。
- 旧データの`place`フォールバック。
- Place候補選択と手入力のWidgetテスト。
- 位置情報の許可、拒否、恒久拒否、サービスOFF。
- 検索デバウンスと古いレスポンス破棄。
- 店舗保存成功／失敗／未ログイン。
- 地図範囲、日本酒フィルター、空状態、API失敗。
- 非公開記録が公開マップへ混入しないことをAPIモックで確認する。
- `dart format lib test`、`flutter analyze`、`flutter test`を実行する。
- AndroidデバッグビルドとiOS署名なしビルドを実行する。

## 完了条件

- 店舗候補を選ぶとPlace IDを含む場所情報が保存される。
- アプリ再起動後も場所情報が復元される。
- 日本酒から店舗、店舗から日本酒の両方向で検索できる。
- 公開／非公開の条件がAPIと画面で一致する。
- 旧データと手入力場所が壊れない。
- APIキーや正確な端末現在地がログ・リポジトリ・公開APIへ漏れない。
- Googleの表示・帰属要件を満たす。
