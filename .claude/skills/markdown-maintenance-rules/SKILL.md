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
5. 今回の変更にサービス内容・機能・料金・仕様に関わる箇所がある場合、`/Users/kanekohiroki/Desktop/groumapapp/STORE_SALES_PRESENTATION.md`（店舗向け営業プレゼン資料）を追記・修正する。SERVICE_FEATURES.md や BUSINESS_MODEL.md の変更内容と整合するように更新する。
6. 今回の変更にサービス内容・機能・仕様に関わる箇所がある場合、`/Users/kanekohiroki/Desktop/groumapapp/STORE_FEATURE_GUIDE.md`（店舗向け手渡し機能説明資料）を追記・修正する。SERVICE_FEATURES.md の変更内容と整合するように更新する。**注意: このファイルは機能案内が目的のため、料金プラン・月額費用・料金改定等の料金情報は記載しない。料金情報は STORE_SALES_PRESENTATION.md にのみ記載する。**
7. 今回の変更にサービス内容・機能・仕様に関わる箇所がある場合、`/Users/kanekohiroki/Desktop/groumapapp/STORE_FEATURE_GUIDE_SIMPLE.md`（店舗向け簡潔版ガイド）を追記・修正する。STORE_FEATURE_GUIDE.md の変更内容と整合するように更新する。簡潔版のため、詳細な説明は省略し要点のみ反映する。**注意: STORE_FEATURE_GUIDE.md と同様、料金情報は記載しない。**
8. `/Users/kanekohiroki/Desktop/groumapapp/TODO_SETTINGS.md`（設定画面TODOリスト）を確認し、以下を実行する：
   - 今回の変更で完了したTODO項目がある場合、該当項目を「未着手」セクションから削除し「完了済み」セクションに完了日付付きで移動する。
   - 今回の変更で新たに必要になった設定画面のTODO（新機能追加に伴う設定項目の不足など）がある場合、適切なセクション（ユーザー用アプリ / 店舗用アプリ）に新規TODO項目を追記する。追記時は既存項目のフォーマット（優先度・概要・内容・配置先・状態）に従う。
   - TODO項目の内容が実装と乖離している場合は、実装に合わせて修正する。

## 判定ルール

- 各ドキュメントについて、変更が必要かどうかを判定する。
- 変更が必要な場合のみ追記・修正を行う。
- 変更が不要な場合は「変更不要」とその理由を報告する。
- 全てのドキュメントについて結果を一覧で報告する。
