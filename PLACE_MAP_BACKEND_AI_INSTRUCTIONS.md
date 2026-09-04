# 日本酒マップ機能：サーバー実装AI向け指示書

## 目的

SAKEPEDIAの公開された飲酒記録を店舗単位で集約し、次の検索を提供する。

- 日本酒から、その日本酒が飲まれた店舗を検索する。
- 地図の表示範囲から、その地域で飲まれた日本酒を検索する。
- 自分の非公開記録と、他ユーザー向け公開記録を厳密に分離する。
- Google Places APIキーをサーバーで安全に管理する。

作業開始時にサーバーリポジトリの`AGENTS.md`、フレームワーク、認証方式、既存DB、保存酒API、テスト規約を必ず確認すること。既存構造に沿って実装し、独自の別レイヤーを無断で増やさないこと。未コミット変更を破棄しないこと。コミット、push、マイグレーション実行、本番デプロイは明示的に依頼された場合のみ行うこと。

## 前提となる既存Flutter API

Flutterアプリは現在、次の保存酒APIを使用している。

```text
POST /saved-sakes/analysis-start
POST /saved-sakes/analysis-complete
GET  /saved-sakes
GET  /saved-sakes/timeline
POST /saved-sakes/{savedId}/visibility
```

実際のサーバールートに`/api`が含まれるかは既存実装を優先する。Firebase IDトークン等の既存認証を再利用し、リクエスト本文の`userId`だけを信用して認可しない。

## データモデル

### 1. 店舗テーブル

既存に同等テーブルがなければ`venues`を追加する。

```text
id                         PK
provider                   google
provider_place_id          Google Place ID
display_name_cache         表示名のキャッシュ
formatted_address_cache    住所のキャッシュ
latitude                   WGS84緯度
longitude                  WGS84経度
provider_data_refreshed_at Googleデータ最終更新日時
created_at
updated_at
```

制約とインデックス：

- `(provider, provider_place_id)`へUNIQUE制約。
- 緯度・経度へ利用DBに適した空間インデックスを設定する。PostgreSQLならPostGISの`geography(Point, 4326)`、MySQLなら`POINT SRID 4326`を優先する。
- 空間拡張が既存環境で利用できない場合は、緯度・経度の複合インデックスと矩形検索で初版を実装し、勝手に本番DB拡張を有効化しない。

Google Place IDは継続保存可能だが、IDが変化する可能性があるため更新日時を持つ。Google由来の店名・住所・座標は無期限保存できる前提にせず、実装時点のGoogle Maps Platform規約を確認し、許可されたキャッシュ期間内に再取得する。Place IDは12か月以上経過した場合の再確認処理を用意する。

### 2. 飲酒記録との関連

保存済み日本酒が既に「ユーザーが飲んだ1件の記録」を表しているなら、新しい`drinking_records`を重複作成せず、既存の保存酒テーブルを拡張する。

```text
venue_id          NULL可、venuesへのFK
place_visibility  private / public、既定値private
consumed_at       NULL可
sake_id           既存値を使用、特定不能ならNULL
sake_name_snapshot 当時の名称。既存name列が同目的なら再利用
manual_place_name Google候補を使わない手入力場所
```

- 既存の`place`文字列は後方互換のため残す。
- Google候補選択時は`venue_id`を設定する。
- 手入力時は`manual_place_name`または既存`place`のみを設定し、`venue_id`はNULLにする。
- 日本酒マスターIDがない記録でも検索できるよう、正規化した日本酒名を補助検索へ利用する。ただし同名酒の誤結合を避け、確定IDと名称一致を区別する。
- 既存行の`place_visibility`は安全側の`private`でマイグレーションする。既存公開投稿を自動的に地図公開しない。

推奨インデックス：

```text
(venue_id, is_public, place_visibility, consumed_at)
(sake_id, is_public, place_visibility)
正規化日本酒名の検索用インデックス
```

## Google Places API連携

### 環境変数

```dotenv
GOOGLE_PLACES_SERVER_API_KEY=...
```

- キーはサーバーの秘密情報管理またはサーバー側`.env`へ設定し、レスポンス、ログ、例外、Gitへ出さない。
- Google CloudではPlaces API（New）のみにAPI制限する。
- 固定送信元IPを利用できる場合はIP制限する。
- Flutter用／Maps SDK用キーと共用しない。

### Placesクライアント

- Nearby Search（New）、Text Search（New）、Place Details（New）を使用する。
- FieldMaskは`id`、表示名、住所、座標など必要最小限にする。
- タイムアウト、Googleの429／5xxに対する上限付き指数バックオフを実装する。
- APIキー、Authorizationヘッダー、正確な検索元座標をアプリケーションログへ記録しない。
- 検索結果をそのままDBへ大量保存しない。ユーザーが実際に選択した店舗だけを保存する。
- Googleの帰属情報がレスポンスに含まれる場合はFlutterへ欠落なく返す。

## API仕様

Flutter側指示書とフィールド名を一致させる。既存APIがsnake_caseへ統一されている場合は、双方を同時に修正して仕様書へ明記する。

### 1. 周辺店舗検索

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

バリデーション：

- 緯度`-90...90`、経度`-180...180`。
- 半径は初版で100〜5000m、既定値1000m。
- 結果上限20件。
- ユーザー単位・IP単位でレート制限する。
- 現在地は検索にのみ利用し、DB・通常ログへ保存しない。

### 2. 店名検索

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

- `query`は2〜100文字。
- 緯度・経度は任意で、指定時のみ検索バイアスへ使用する。
- HTML、制御文字、過剰な空白を正規化する。

両検索のレスポンス：

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

### 3. 保存酒へ店舗を設定

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

処理：

1. 認証ユーザーが`{savedId}`を所有していることを確認する。
2. `providerPlaceId`と`manualName`は排他的に受け付ける。
3. Place ID指定時はPlace Details（New）でID・店名・住所・座標をサーバー側で取得する。クライアント送信の座標を信用しない。
4. `(provider, provider_place_id)`で店舗をupsertする。
5. 保存酒と店舗をトランザクション内で関連付ける。
6. `placeVisibility == public`は、保存酒自体が公開可能な状態か検証する。
7. 更新済みの場所オブジェクトを返す。

レスポンス：

```json
{
  "drinkingPlace": {
    "venueId": "venue_123",
    "providerPlaceId": "ChIJ...",
    "displayName": "日本酒処 サンプル",
    "formattedAddress": "沖縄県那覇市...",
    "latitude": 26.2124,
    "longitude": 127.6809,
    "visibility": "public"
  }
}
```

場所の削除と公開範囲変更も用意する。

```text
DELETE /api/saved-sakes/{savedId}/place
PATCH  /api/saved-sakes/{savedId}/place-visibility
```

### 4. 地図範囲内の店舗

```http
GET /api/map/venues?swLat=26.10&swLng=127.60&neLat=26.30&neLng=127.80&zoom=13&sakeId=123&sinceDays=90
```

- 必須：南西・北東の緯度経度、zoom。
- 任意：`sakeId`、日本酒検索トークン、`sinceDays`。
- 他ユーザー分は`is_public = true AND place_visibility = public`のみ対象。
- 認証ユーザー本人の非公開記録を混ぜる場合は、各店舗または記録に`scope: own/private/public`を付け、公開集計件数と混同しない。
- 店舗単位で集約し、同じ店舗へ複数ピンを返さない。
- 初版は最大200店舗。超過時はズーム要求またはサーバークラスタを返す。
- 範囲外の店舗を返さない。

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
  ],
  "truncated": false
}
```

### 5. 店舗で飲まれた日本酒

```http
GET /api/map/venues/{venueId}/sakes?sinceDays=90&cursor=...
```

- 公開条件を満たす記録だけを集約する。
- `sakeId`がある場合はID単位、ない場合は正規化名称単位でまとめる。
- 日本酒名、酒蔵、種類、公開記録数、最後に飲まれた日時、代表画像を返す。
- 代表画像は公開投稿の画像だけを使用する。
- カーソルページングを使用する。

### 6. 日本酒検索

既存検索APIを再利用できなければ、次を追加する。

```http
GET /api/sakes/search?q=獺祭&limit=20
```

- マスターに存在する日本酒を優先する。
- マスターIDのない公開飲酒記録の名称候補は区別して返す。
- レスポンスには地図フィルターへ渡せる安定したIDまたは検索トークンを含める。

## 「飲める」の扱い

飲酒記録は過去の実績であり、現在の在庫・提供を保証しない。API名・レスポンス・画面文言では「この店で飲まれた」「この地域で飲まれた」を使用する。

将来、現在の提供状況を扱う場合は、飲酒記録から分離して次のようなテーブルを追加する。

```text
venue_sake_availability
- venue_id
- sake_id
- status
- observed_at
- source_record_id
- expires_at
```

確認日と有効期限なしに「現在飲める」と判定しない。

## プライバシー・不正対策

- 店舗公開は投稿公開とは別の明示設定にする。
- 既存公開投稿の店舗を自動公開しない。
- 端末の検索元現在地を保存しない。
- 公開マップからメール、Firebase UID、生の内部ユーザーIDを返さない。
- 投稿直後の正確な時刻と店舗を組み合わせてリアルタイム滞在を推測されないようにする。時刻丸め、表示遅延、一定件数未満の匿名化を検討する。
- Place ID・savedIdの所有者確認、座標範囲、公開状態をサーバー側で検証する。
- Places検索APIと地図APIにレート制限、タイムアウト、件数上限を設定する。
- 削除・非公開化がマップ集計へ即時反映されるよう、キャッシュを無効化する。

## Google Maps Platformポリシー

- Place IDは保存可能だが、Googleは古いPlace IDの定期的な再確認を推奨している。
- Place ID以外のGoogle Placesコンテンツには保存・キャッシュ制限がある。実装時点の規約を確認し、キャッシュ更新処理と更新日時を設ける。
- Places結果を地図上に表示する場合はGoogle Mapを使用し、必要なGoogleおよび第三者帰属表示を維持する。
- 利用規約・プライバシーポリシーへGoogleの要件を反映する。

参照：

- https://developers.google.com/maps/documentation/places/web-service/place-id
- https://developers.google.com/maps/documentation/places/web-service/policies
- https://developers.google.com/maps/api-security-best-practices

## テスト要件

- Migrationのup/downまたはロールバック相当。
- 同一Place IDの店舗重複作成防止。
- 保存酒の所有者以外による場所更新拒否。
- Place ID／手入力の排他バリデーション。
- Places API成功、タイムアウト、429、4xx、5xx、無効Place ID。
- 緯度経度・半径・検索文字列の境界値。
- 非公開記録が公開マップへ一件も混入しないこと。
- 日本酒IDあり／なしの集約。
- 表示範囲外の店舗を返さないこと。
- 場所削除・投稿非公開化後に集計から消えること。
- N+1クエリが発生しないこと。
- 既存の保存酒・タイムラインAPIの回帰テスト。

## 完了条件

- Flutter向けPlaces検索APIがAPIキーを漏らさず動作する。
- Place IDから検証した店舗を保存酒へ関連付けられる。
- 日本酒→店舗、店舗→日本酒の双方向クエリが成立する。
- 公開条件と所有者認可が全エンドポイントで統一される。
- 既存データと既存APIの互換性を維持する。
- DBインデックスを含め、想定件数で地図範囲検索が実用速度で動作する。
- API仕様、環境変数、Google Cloud設定、マイグレーション手順をREADMEまたはAPIドキュメントへ記載する。
