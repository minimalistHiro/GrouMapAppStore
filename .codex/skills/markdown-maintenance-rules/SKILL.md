---
name: markdown-maintenance-rules
description: 「マークダウンを整理して」「ドキュメントを更新して」「MDファイルを整理して」など、プロジェクトのマークダウンドキュメントの整理・更新を依頼されたときに使う。
---

# Markdown Maintenance Rules

## 概要

GrouMapプロジェクトの各種マークダウンドキュメントを、直近の変更内容に基づいて整理・追記・修正する。

## 手順

ユーザーから「マークダウンを整理して」「ドキュメントを更新して」などの依頼があったら、以下の手順を順に実行する。

1. `/Users/kanekohiroki/Desktop/groumapapp/FIRESTORE.md` を読み込み、Firestore関連（プロバイダー追加、コレクション/ドキュメントの作成・削除・更新など）の変更がある場合は、FIRESTORE.md を追記・修正する（ユーザー用・店舗用リポジトリの変更がある場合も対象）。
2. 今回の変更に画面の作成や画面の変更等がある場合、`/Users/kanekohiroki/Desktop/groumapapp/USER_APP_SCREENS.md` と `/Users/kanekohiroki/Desktop/groumapapp_store/STORE_APP_SCREENS.md` を修正する。
3. 今回の変更にサービス内容（機能追加・変更・削除、仕様変更など）に関わる箇所がある場合、`/Users/kanekohiroki/Desktop/groumapapp/SERVICE_FEATURES.md` を追記・修正する。
4. 今回の変更にビジネスモデル（収益モデル・料金プラン・KPI定義・方針変更・キャンペーン設計など）に関わる箇所がある場合、`/Users/kanekohiroki/Desktop/groumapapp/BUSINESS_MODEL.md` を追記・修正する。
5. 今回の変更にバッジ関連（バッジの追加・削除・名前変更・獲得条件変更・レア度変更・画像パス変更・獲得処理の実装状況変更など）がある場合、`/Users/kanekohiroki/Desktop/groumapapp/BADGE_LIST.md` を追記・修正する。バッジ定義の正とするソースは `lib/data/badge_definitions.dart` である。
6. 今回の変更にサービス内容・機能・料金・仕様に関わる箇所がある場合、`/Users/kanekohiroki/Desktop/groumapapp/STORE_SALES_PRESENTATION.md`（店舗向け営業プレゼン資料）を追記・修正する。SERVICE_FEATURES.md や BUSINESS_MODEL.md の変更内容と整合するように更新する。
7. 今回の変更にサービス内容・機能・料金・仕様に関わる箇所がある場合、`/Users/kanekohiroki/Desktop/groumapapp/STORE_FEATURE_GUIDE.md`（店舗向け手渡し機能説明資料）を追記・修正する。SERVICE_FEATURES.md や BUSINESS_MODEL.md の変更内容と整合するように更新する。
8. `/Users/kanekohiroki/Desktop/groumapapp/QA_CHECKLIST.md` に、今回の実装内容・変更点から導かれるテスト項目を追記する。以下のルールに従う：
   - ファイル末尾に日付見出し（`## YYYY-MM-DD`）を追加し、その下にテスト項目を箇条書きで記載する。同日の見出しが既にある場合は、その見出しの下に追記する。
   - 各テスト項目はテスターが手動で確認できる具体的な操作手順と期待結果を記載する（例：「○○画面を開き、△△ボタンをタップ → □□が表示されること」）。
   - 今回の変更に関連する画面・機能・データの整合性を網羅的にカバーする。
   - 正常系だけでなく、境界値・エラー系・権限違いなどの異常系テストも含める。
   - テスト項目には未チェックのチェックボックス（`- [ ]`）を付与し、テスターが消化状況を管理できるようにする。

## 判定ルール

- 各ドキュメントについて、変更が必要かどうかを判定する。
- 変更が必要な場合のみ追記・修正を行う。
- 変更が不要な場合は「変更不要」とその理由を報告する。
- 全てのドキュメントについて結果を一覧で報告する。
