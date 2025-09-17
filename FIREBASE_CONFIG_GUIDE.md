# Firebase設定値の取得と更新手順

## 1. Firebase Console で設定値を取得

1. [Firebase Console](https://console.firebase.google.com/u/0/project/groumap-ea452) にアクセス
2. プロジェクト設定（歯車アイコン）→ 全般
3. 「マイアプリ」セクションでWebアプリの設定を確認

## 2. 設定値の更新

### main.dart の更新
以下のファイルで実際の設定値に置き換えてください：

```dart
// lib/main.dart の FirebaseOptions 部分
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "AIzaSy...", // 実際のAPIキー
    authDomain: "groumap-ea452.firebaseapp.com",
    projectId: "groumap-ea452",
    storageBucket: "groumap-ea452.appspot.com",
    messagingSenderId: "123456789012", // 実際のSenderID
    appId: "1:123456789012:web:abcdef...", // 実際のAppID
    measurementId: "G-XXXXXXXXXX", // 実際のMeasurementID
  ),
);
```

### web/index.html の更新
以下のファイルで実際の設定値に置き換えてください：

```javascript
// web/index.html の firebaseConfig 部分
const firebaseConfig = {
  apiKey: "AIzaSy...", // 実際のAPIキー
  authDomain: "groumap-ea452.firebaseapp.com",
  projectId: "groumap-ea452",
  storageBucket: "groumap-ea452.appspot.com",
  messagingSenderId: "123456789012", // 実際のSenderID
  appId: "1:123456789012:web:abcdef...", // 実際のAppID
  measurementId: "G-XXXXXXXXXX" // 実際のMeasurementID
};
```

## 3. Firebase Authentication の設定

1. Firebase Console → Authentication → Sign-in method
2. 「メール/パスワード」を有効化
3. 「保存」をクリック

## 4. Cloud Firestore の設定

1. Firebase Console → Firestore Database
2. 「データベースを作成」をクリック
3. セキュリティルールを設定（テストモードで開始を推奨）

### セキュリティルール（テスト用）
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 5. テスト用データの作成

Firebase Console → Firestore Database → 「コレクションを開始」で以下を作成：

### stores コレクション
- ドキュメントID: `test_store_001`
- フィールド:
  - name: "テスト店舗"
  - address: "東京都渋谷区"
  - phone: "03-1234-5678"
  - description: "美味しい料理を提供する店舗です"
  - category: "レストラン"
  - isActive: true

### stores/test_store_001/stats コレクション
- ドキュメントID: `daily`
- フィールド:
  - totalVisits: 45
  - totalPoints: 1250
  - activeUsers: 23
  - couponsUsed: 12

### coupons コレクション
- ドキュメントID: `coupon_001`
- フィールド:
  - storeId: "test_store_001"
  - title: "ランチセット20%OFF"
  - description: "平日ランチセットが20%OFF！"
  - discountType: "percentage"
  - discountValue: 20
  - validUntil: 未来の日付
  - createdAt: 現在の日付

## 6. テスト用ユーザーの作成

1. Firebase Console → Authentication → Users
2. 「ユーザーを追加」をクリック
3. テスト用のメールアドレスとパスワードを設定
