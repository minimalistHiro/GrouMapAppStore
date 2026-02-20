# legal-docs-update

## 説明

「プライバシーポリシーを更新して」「利用規約を更新して」「プライバシーポリシーや利用規約を変更して」など、プライバシーポリシー・利用規約の作成・更新・変更を依頼されたときに使う。

## トリガーワード

- プライバシーポリシーを更新
- 利用規約を更新
- プライバシーポリシーを変更
- 利用規約を変更
- プライバシーポリシーを修正
- 利用規約を修正
- 法務文書を更新
- 規約を更新

## 実行手順

### ステップ1: 関連マークダウンファイルの読み込み（必須・最初に実行）

変更を開始する前に、以下の4つのマークダウンファイルを**必ず先に読み取る**こと。これらのファイルの内容を把握した上で、プライバシーポリシー・利用規約の整合性を確認する。

1. `/Users/kanekohiroki/Desktop/groumapapp/FIRESTORE.md` — Firestoreのデータ構造（収集する情報の確認用）
2. `/Users/kanekohiroki/Desktop/groumapapp/SERVICE_FEATURES.md` — サービス機能一覧（サービス内容・機能の確認用）
3. `/Users/kanekohiroki/Desktop/groumapapp/BUSINESS_MODEL.md` — ビジネスモデル（料金プラン・収益モデルの確認用）
4. `/Users/kanekohiroki/Desktop/groumapapp/BADGE_LIST.md` — バッジ一覧（バッジ関連の定義確認用）

### ステップ2: 現在のプライバシーポリシー・利用規約の読み込み

以下の8ファイルを読み込み、現状の内容を把握する。

**ユーザー用アプリ:**
- `/Users/kanekohiroki/Desktop/groumapapp/PRIVACY_POLICY.md`
- `/Users/kanekohiroki/Desktop/groumapapp/TERMS_OF_SERVICE.md`
- `/Users/kanekohiroki/Desktop/groumapapp/lib/views/legal/privacy_policy_view.dart`
- `/Users/kanekohiroki/Desktop/groumapapp/lib/views/legal/terms_view.dart`

**店舗用アプリ:**
- `/Users/kanekohiroki/Desktop/groumapapp_store/PRIVACY_POLICY.md`
- `/Users/kanekohiroki/Desktop/groumapapp_store/TERMS_OF_SERVICE.md`
- `/Users/kanekohiroki/Desktop/groumapapp_store/lib/views/settings/privacy_policy_view.dart`
- `/Users/kanekohiroki/Desktop/groumapapp_store/lib/views/settings/terms_of_service_view.dart`

### ステップ3: 変更内容の特定と反映

ステップ1で読み込んだマークダウンファイルの内容と、ユーザーからの指示に基づいて、必要な変更を特定する。

変更を反映する際の注意事項:
- **マークダウンファイルとDartビューファイルの内容は必ず同期させる**こと
- ユーザー用アプリと店舗用アプリで**対象ユーザーが異なる**ため、内容を適切に書き分けること
  - ユーザー用: スタンプ収集、コイン、バッジ、マップ利用、レコメンド等の一般ユーザー向け機能
  - 店舗用: 店舗情報管理、クーポン発行、売上分析、スタンプカード管理等の店舗オーナー向け機能
- 最終更新日（制定日）を**本日の日付**に更新すること（マークダウンとDartビュー両方）

### ステップ4: 変更結果の報告

変更完了後、以下を報告する:
- 変更したファイルの一覧
- 変更内容の概要
- ユーザー用アプリと店舗用アプリでの差異がある場合はその説明

## 対象ファイル一覧

| 種別 | アプリ | ファイルパス |
|------|--------|------------|
| プライバシーポリシーMD | ユーザー用 | `/Users/kanekohiroki/Desktop/groumapapp/PRIVACY_POLICY.md` |
| 利用規約MD | ユーザー用 | `/Users/kanekohiroki/Desktop/groumapapp/TERMS_OF_SERVICE.md` |
| プライバシーポリシー画面 | ユーザー用 | `/Users/kanekohiroki/Desktop/groumapapp/lib/views/legal/privacy_policy_view.dart` |
| 利用規約画面 | ユーザー用 | `/Users/kanekohiroki/Desktop/groumapapp/lib/views/legal/terms_view.dart` |
| プライバシーポリシーMD | 店舗用 | `/Users/kanekohiroki/Desktop/groumapapp_store/PRIVACY_POLICY.md` |
| 利用規約MD | 店舗用 | `/Users/kanekohiroki/Desktop/groumapapp_store/TERMS_OF_SERVICE.md` |
| プライバシーポリシー画面 | 店舗用 | `/Users/kanekohiroki/Desktop/groumapapp_store/lib/views/settings/privacy_policy_view.dart` |
| 利用規約画面 | 店舗用 | `/Users/kanekohiroki/Desktop/groumapapp_store/lib/views/settings/terms_of_service_view.dart` |
