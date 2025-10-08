# メール配信トラブルシューティング

## 問題: 特定のメールアドレスにメールが届かない

### 現象
- `h.kaneko.baseball@gmail.com` にはメールが届く
- `h.kaneko.baseball@rakumail.jp` には届かない
- ログでは両方とも送信成功と表示される

### 考えられる原因

#### 1. **メールプロバイダーの制限**

**rakumail.jp の特徴:**
- 無料のメールサービス
- スパム対策が厳しい可能性
- Firebaseからの自動メールをブロックしている可能性

**対策:**
```
1. rakumailの受信設定を確認
   - 迷惑メールフォルダを確認
   - 受信拒否設定を確認
   - ドメイン受信許可設定で以下を追加:
     - @firebase.com
     - @groumap-ea452.firebaseapp.com
     - noreply@groumap-ea452.firebaseapp.com
```

#### 2. **SPF/DKIM設定の問題**

Firebaseのメールは、デフォルトのFirebase認証ドメインから送信されます。一部のメールプロバイダーは、SPF/DKIM設定が不完全なメールをブロックします。

**確認方法:**
1. Gmailで受信したメールのヘッダーを確認
2. 送信元ドメインを確認
3. SPF/DKIM認証が通っているか確認

**対策:**
- カスタムドメインを使用してメールを送信（Firebase Authの高度な設定）

#### 3. **メール配信の遅延**

**確認方法:**
- 数分〜数時間待ってから再確認
- rakumailのサーバー状態を確認

#### 4. **Firebaseの制限**

**無料プランの制限:**
- 1日あたりのメール送信数: 100通
- 同じメールアドレスへの再送信間隔: 1時間（推奨）

**確認方法:**
```
1. Firebase Console → Authentication → Users
2. 該当ユーザーの "Email verified" 列を確認
3. 最後のメール送信時刻を確認
```

#### 5. **メールアドレスのブラックリスト**

一部のメールアドレスやドメインがFirebaseのブラックリストに入っている可能性があります。

### デバッグ手順

#### ステップ1: Firebase Consoleで確認

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクト `groumap-ea452` を選択
3. **Authentication** → **Users** を開く
4. `h.kaneko.baseball@rakumail.jp` を検索
5. ユーザーの詳細情報を確認:
   - Email verified: false/true
   - Last sign in: 最終ログイン時刻
   - Created: アカウント作成時刻

#### ステップ2: メール送信ログの確認

Firebaseには詳細なメール送信ログはありませんが、以下で確認できます：

```bash
# Firebase CLIでログを確認
firebase functions:log

# または、Google Cloud Consoleで確認
# https://console.cloud.google.com/logs
# プロジェクト: groumap-ea452
# ログを検索: "sendEmailVerification"
```

#### ステップ3: テスト用の別アドレスで確認

別のメールプロバイダーでテスト：
- Gmail: ✅ 動作確認済み
- Yahoo: テスト推奨
- Outlook: テスト推奨
- iCloud: テスト推奨
- 独自ドメイン: テスト推奨

#### ステップ4: rakumailの設定を確認

1. **rakumailにログイン**
2. **設定** → **受信設定** を開く
3. **迷惑メール設定** を確認
4. **ドメイン指定受信** を設定:
   ```
   firebase.com
   firebaseapp.com
   groumap-ea452.firebaseapp.com
   ```

### 解決策

#### 方法1: Gmail など信頼性の高いメールサービスを使用

**推奨:**
- Gmail
- Outlook
- iCloud
- 独自ドメインのメール

#### 方法2: カスタムSMTPを使用（Cloud Functions）

Firebase Authenticationの標準メール送信を使わず、独自のメール送信システムを構築：

```typescript
// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as nodemailer from 'nodemailer';

export const sendVerificationEmail = functions.https.onCall(async (data, context) => {
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ユーザーが認証されていません');
  }

  // Nodemailerでメール送信
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: 'your-email@gmail.com',
      pass: 'your-app-password'
    }
  });

  await transporter.sendMail({
    from: 'noreply@groumap.com',
    to: data.email,
    subject: 'メールアドレスの確認',
    html: `メール認証用リンク: ${data.verificationLink}`
  });
});
```

#### 方法3: メール配信サービスを使用

**推奨サービス:**
- SendGrid（Firebase拡張機能あり）
- Mailgun
- Amazon SES
- Postmark

**Firebase拡張機能を使用する方法:**

```bash
# SendGrid拡張機能をインストール
firebase ext:install sendgrid/firestore-send-email

# 設定
firebase ext:configure sendgrid/firestore-send-email
```

### 現在の対処法

#### 即座にできること

1. **rakumailの受信設定を変更**
   - 迷惑メールフォルダを確認
   - ドメイン受信許可を設定

2. **別のメールアドレスで再登録**
   - Gmailなど信頼性の高いサービスを使用

3. **時間をおいて再送信**
   - メール配信の遅延の可能性
   - 数時間後に再確認

#### 長期的な解決策

1. **カスタムメール送信システムの構築**
   - Cloud Functionsを使用
   - SendGridなどのサービスを統合

2. **ユーザーへの案内**
   - 推奨メールアドレスを明記
   - rakumailなど一部サービスで問題が発生する可能性を告知

### 注意事項

**重要:**
- rakumail.jpはメールが届きにくいことが知られています
- 本番環境では、ユーザーに信頼性の高いメールサービスを推奨してください
- メール認証が必須の場合は、代替手段（SMS認証など）も検討してください

### コンソールログの見方

```
=== メール認証送信開始 ===
ユーザーID: abc123
メールアドレス: h.kaneko.baseball@rakumail.jp
現在の認証状態: false
送信リクエスト実行中...
✅ メール認証メール送信成功: h.kaneko.baseball@rakumail.jp
=== メール認証送信完了 ===
```

このログが表示されれば、Firebase側の送信は成功しています。
メールが届かない場合は、受信側（rakumail）の問題です。

