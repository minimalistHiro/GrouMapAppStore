# Firebase設定手順

このアプリをFirebaseプロジェクト `groumap-ea452` に連携するための設定手順です。

## 1. Firebase設定の取得

1. [Firebase Console](https://console.firebase.google.com/u/0/project/groumap-ea452) にアクセス
2. プロジェクト設定（歯車アイコン）→ 全般 → マイアプリ
3. Webアプリの設定を確認または新規追加

## 2. 設定ファイルの更新

### main.dart の更新
`lib/main.dart` の FirebaseOptions を実際の値に更新してください：

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "実際のAPIキー",
    authDomain: "groumap-ea452.firebaseapp.com",
    projectId: "groumap-ea452",
    storageBucket: "groumap-ea452.appspot.com",
    messagingSenderId: "実際のSenderID",
    appId: "実際のAppID",
    measurementId: "実際のMeasurementID",
  ),
);
```

### web/index.html の更新
`web/index.html` の firebaseConfig を実際の値に更新してください：

```javascript
const firebaseConfig = {
  apiKey: "実際のAPIキー",
  authDomain: "groumap-ea452.firebaseapp.com",
  projectId: "groumap-ea452",
  storageBucket: "groumap-ea452.appspot.com",
  messagingSenderId: "実際のSenderID",
  appId: "実際のAppID",
  measurementId: "実際のMeasurementID"
};
```

## 3. Firebase Authentication の設定

1. Firebase Console → Authentication → Sign-in method
2. メール/パスワード認証を有効化
3. 必要に応じて他の認証方法も有効化

## 4. Cloud Firestore の設定

1. Firebase Console → Firestore Database
2. データベースを作成（本番環境またはテスト環境）
3. セキュリティルールを設定：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 店舗データ
    match /stores/{storeId} {
      allow read, write: if request.auth != null && request.auth.uid == storeId;
      
      // 店舗統計
      match /stats/{statId} {
        allow read, write: if request.auth != null && request.auth.uid == storeId;
      }
      
      // 訪問記録
      match /visits/{visitId} {
        allow read, write: if request.auth != null && request.auth.uid == storeId;
      }
    }
    
    // クーポンデータ
    match /coupons/{couponId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 5. データ構造

### stores コレクション
```javascript
stores/{storeId} {
  name: string,
  address: string,
  phone: string,
  description: string,
  category: string,
  isActive: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### stores/{storeId}/stats/daily ドキュメント
```javascript
{
  totalVisits: number,
  totalPoints: number,
  activeUsers: number,
  couponsUsed: number,
  date: string (YYYY-MM-DD),
  updatedAt: timestamp
}
```

### stores/{storeId}/visits コレクション
```javascript
visits/{visitId} {
  userId: string,
  userName: string,
  pointsEarned: number,
  timestamp: timestamp
}
```

### coupons コレクション
```javascript
coupons/{couponId} {
  storeId: string,
  title: string,
  description: string,
  discountType: string, // 'percentage', 'fixed_amount', 'fixed_price'
  discountValue: number,
  validUntil: timestamp,
  imageUrl: string?,
  createdAt: timestamp
}
```

## 6. テスト用データの作成

Firebase Console で以下のテストデータを作成してください：

### テスト店舗データ
```javascript
// stores/test_store_001
{
  name: "テスト店舗",
  address: "東京都渋谷区",
  phone: "03-1234-5678",
  description: "美味しい料理を提供する店舗です",
  category: "レストラン",
  isActive: true,
  createdAt: "2024-01-01T00:00:00Z"
}
```

### テスト統計データ
```javascript
// stores/test_store_001/stats/daily
{
  totalVisits: 45,
  totalPoints: 1250,
  activeUsers: 23,
  couponsUsed: 12,
  date: "2024-01-17",
  updatedAt: "2024-01-17T12:00:00Z"
}
```

## 7. アプリの実行

設定完了後、以下のコマンドでアプリを実行：

```bash
flutter run -d chrome
```

## 8. トラブルシューティング

### よくあるエラー
1. **Firebase初期化エラー**: 設定値が正しいか確認
2. **認証エラー**: Authentication設定が有効か確認
3. **Firestore権限エラー**: セキュリティルールを確認

### ログの確認
ブラウザの開発者ツール（F12）でコンソールログを確認してください。
