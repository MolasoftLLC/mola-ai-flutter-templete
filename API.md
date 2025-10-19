# 保存酒 API 仕様

## 共通事項
- ベース URL: `https://{環境別ドメイン}/api`
- 認証: Firebase Auth で取得したユーザーの `uid` を `userId` に指定
- 画像送信: クライアント側で WebP などに圧縮し Base64 文字列として送信
- 画像取得: サーバー側で S3 に保存し、レスポンスでは画像の公開 URL を返却

---

## 保存酒の解析開始通知
- **Method:** `POST`
- **Path:** `/saved-sakes/analysis-start`
- **Body:**
  ```json
  {
    "userId": "firebase-uid",
    "savedId": "saved_1700000000000_123456",
    "stage": "analysis_start",
    "timestamp": "2024-05-01T12:34:56.789Z",
    "sake": {
      "name": "解析中"
    },
    "imageBase64": "..."
  }
  ```
- **Response:** `200 OK`（ボディなし）

## 保存酒の解析完了通知
- **Method:** `POST`
- **Path:** `/saved-sakes/analysis-complete`
- **Body:** `analysis-start` と同形式。`sake` には解析後の詳細情報を格納。
- **Response:** `200 OK`

## 保存酒一覧の取得
- **Method:** `GET`
- **Path:** `/saved-sakes`
- **Query:** `userId=firebase-uid`
- **Response:**
  ```json
  {
    "sakes": [
      {
        "savedId": "saved_1700000000000_123456",
        "name": "十四代 角新本丸",
        "type": "純米吟醸",
        "imageUrls": [
          "https://s3.amazonaws.com/.../saved_1700000000000_123456-main.webp"
        ]
      },
      {
        "savedId": "saved_1700000000001_999999",
        "name": "而今 雄町",
        "type": "純米吟醸",
        "imageUrl": "https://s3.amazonaws.com/.../saved_1700000000001_999999.webp"
      }
    ]
  }
  ```
  - `imageUrl` / `imageUrls`: S3 に保存された公開 URL（単数・複数両対応）

---

## 保存酒を削除
- **Method:** `POST`
- **Path:** `/saved-sakes/{savedId}/remove`
- **Body:**
  ```json
  {
    "userId": "firebase-uid",
    "timestamp": "2024-05-01T12:45:00.456Z"
  }
  ```
- **Response:** `200 OK`

---

## 保存酒に画像を追加
- **Method:** `POST`
- **Path:** `/saved-sakes/{savedId}/images`
- **Body:**
  ```json
  {
    "userId": "firebase-uid",
    "imageBase64": "...",
    "timestamp": "2024-05-01T12:45:00.456Z"
  }
  ```
- **Response:**
  ```json
  {
    "imageUrl": "https://s3.amazonaws.com/.../saved_1700000000000_123456-main.webp"
  }
  ```

## 保存酒の画像を削除
- **Method:** `POST`
- **Path:** `/saved-sakes/{savedId}/images/delete`
- **Body:**
  ```json
  {
    "userId": "firebase-uid",
    "imageUrl": "https://s3.amazonaws.com/.../saved_1700000000000_123456-main.webp"
  }
  ```
- **Response:** `200 OK`

## お気に入り一覧の取得
- **Method:** `GET`
- **Path:** `/favorites`
- **Query:** `userId=firebase-uid`
- **Response:**
  ```json
  {
    "favorites": [
      {
        "name": "而今",
        "type": "純米吟醸"
      },
      {
        "name": "田酒"
      }
    ]
  }
  ```

## お気に入りに追加
- **Method:** `POST`
- **Path:** `/favorites`
- **Body:**
  ```json
  {
    "userId": "firebase-uid",
    "name": "而今",
    "type": "純米吟醸",
    "timestamp": "2024-05-01T13:00:00.000Z"
  }
  ```
- **Response:** `200 OK`

## お気に入りから削除
- **Method:** `POST`
- **Path:** `/favorites/delete`
- **Body:**
  ```json
  {
    "userId": "firebase-uid",
    "name": "而今",
    "type": "純米吟醸"
  }
  ```
- **Response:** `200 OK`

## ユーザー好みの取得
- **Method:** `GET`
- **Path:** `/preferences`
- **Query:** `userId=firebase-uid`
- **Response:**
  ```json
  {
    "preferences": "吟醸香が強いお酒が好き..."
  }
  ```

## ユーザー好みの更新
- **Method:** `POST`
- **Path:** `/preferences`
- **Body:**
  ```json
  {
    "userId": "firebase-uid",
    "preferences": "吟醸香が強く、やや甘口の日本酒が好みです",
    "timestamp": "2024-05-01T13:15:00.000Z"
  }
  ```
- **Response:** `200 OK`

## ユーザー登録・更新
- **Method:** `POST`
- **Path:** `/sake-users/register`
- **Body:**
  ```json
  {
    "user": {
      "id": 1,
      "firebaseUid": "firebase-uid",
      "username": "user_xxx",
      "displayName": "表示名",
      "photoUrl": "https://...",
      "createdAt": "2024-05-01T13:20:00.000Z",
      "updatedAt": "2024-05-01T13:20:00.000Z"
    }
  }
  ```
- **Response:** `200 OK`

## ユーザー情報の取得
- **Method:** `GET`
- **Path:** `/sake-users/me`
- **Query:** `userId=firebase-uid`
- **Response:**
  ```json
  {
    "userId": "firebase-uid",
    "displayName": "表示名",
    "photoUrl": "https://..."
  }
  ```

## ユーザー名の更新
- **Method:** `POST`
- **Path:** `/sake-users/username`
- **Body:**
  ```json
  {
    "username": "新しいニックネーム"
  }
  ```
- **Response:** `200 OK`

## 備考
- クライアントは `imageBase64` があればローカルに書き出し、それ以外の画像は URL を直接表示します。
- ステージ値は `analysis_start` / `analysis_complete` の 2 種類。
