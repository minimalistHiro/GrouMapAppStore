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

## 判定ルール

- 各ドキュメントについて、変更が必要かどうかを判定する。
- 変更が必要な場合のみ追記・修正を行う。
- 変更が不要な場合は「変更不要」とその理由を報告する。
- 全てのドキュメントについて結果を一覧で報告する。
