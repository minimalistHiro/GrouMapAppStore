# メール認証設定ガイド

## Firebase コンソールでの設定

### 1. メール認証テンプレートの設定

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクト `groumap-ea452` を選択
3. 左メニューから **Authentication** を選択
4. **Templates** タブをクリック
5. **Email address verification** を選択
6. テンプレートの編集:
   - Subject（件名）: `GrouMap Store - メールアドレスの確認`
   - 本文を適切に編集
   - `%LINK%` がメール認証リンクです
7. **Save** をクリック

### 2. 認証方法の確認

1. **Authentication** → **Sign-in method** タブ
2. **Email/Password** が有効になっていることを確認
3. 無効の場合は有効化してください

### 3. 承認済みドメインの確認

1. **Authentication** → **Settings** タブ
2. **Authorized domains** セクション
3. 以下のドメインが追加されていることを確認:
   - `localhost`
   - `groumap-ea452.firebaseapp.com`
   - `groumap-ea452.web.app`

## トラブルシューティング

### メールが届かない場合

1. **迷惑メールフォルダを確認**
   - Gmail, Outlook などの迷惑メールフォルダをチェック

2. **Firebase コンソールでメール送信ログを確認**
   - Authentication → Users で新規ユーザーが作成されているか確認
   - メールアドレスが正しいか確認

3. **コンソールログを確認**
   - ブラウザの開発者ツールを開く（F12）
   - Console タブでエラーメッセージを確認
   - 以下のログが表示されるはず:
     ```
     メール認証メール送信開始
     メール認証メールを送信しました: user@example.com
     メール認証メール送信完了
     ```

4. **Firebase の使用量を確認**
   - 無料プランの場合、1日のメール送信数に制限があります
   - Firebase Console → Usage を確認

### デバッグ方法

1. **テスト用メールアドレスを使用**
   - 実際のメールアドレスでテスト
   - Gmail の場合: `your.email+test1@gmail.com` などエイリアスが使えます

2. **ログの確認**
   - アプリでアカウント作成時のコンソールログを確認
   - エラーがある場合は詳細が表示されます

3. **再送信機能を使う**
   - メール認証待ち画面で「認証メールを再送信」ボタンをクリック
   - コンソールログでエラーを確認

## 本番環境での設定

### カスタムドメインを使用する場合

1. Firebase Console → **Authentication** → **Settings**
2. **Authorized domains** に本番ドメインを追加
3. `ActionCodeSettings` の `url` を本番URLに変更:
   ```dart
   final actionCodeSettings = ActionCodeSettings(
     url: 'https://your-production-domain.com',
     handleCodeInApp: false,
   );
   ```

## テスト手順

1. **新規アカウント作成**
   ```
   - メールアドレス: test@example.com
   - パスワード: test123456
   - 店舗情報を入力
   - アカウント作成ボタンをクリック
   ```

2. **コンソールログ確認**
   ```
   アカウント作成開始: test@example.com
   アカウント作成完了
   メール認証メール送信開始
   メール認証メールを送信しました: test@example.com
   メール認証メール送信完了
   ```

3. **メール受信確認**
   - 登録したメールアドレスに認証メールが届く
   - メール内のリンクをクリック
   - 「メールアドレスが確認されました」と表示される

4. **アプリで認証確認**
   - メール認証待ち画面で「認証状況を確認」ボタンをクリック
   - 認証完了後、メイン画面に遷移

## 注意事項

- Web版では実際のメールアドレスが必要です
- テスト用にGmailなどのフリーメールアドレスを使用してください
- メール送信には数秒〜数分かかる場合があります
- 1日のメール送信数には制限があります（無料プラン: 100通/日）

