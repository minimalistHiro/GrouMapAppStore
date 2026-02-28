---
name: store-submission-texts
description: アプリストア（App Store / Google Play Store）の申請テキスト（プロモーション用テキスト・概要・簡単な説明など）の作成・変更・修正を依頼されたときに使う。「ストアのテキストを変更して」「プロモーション用テキストを修正して」「App Storeの説明文を更新して」「Google Playの説明を変えて」「ストア申請テキスト」などの依頼時に使う。
---

# Store Submission Texts

## 概要

App Store / Google Play Store の申請用テキスト（プロモーション用テキスト・概要・簡単な説明・詳しい説明など）の作成・変更・修正を行う際に、ビジネスモデルとサービス機能を把握した上でテキストを編集する。

## 対象ファイル

| アプリ | ストア申請テキスト |
|-------|-----------------|
| ユーザー用アプリ | `/Users/kanekohiroki/Desktop/groumapapp/STORE_SUBMISSION_TEXTS.md` |
| 店舗用アプリ | `/Users/kanekohiroki/Desktop/groumapapp_store/STORE_SUBMISSION_TEXTS.md` |

## 手順

1. 以下のファイルを必ず読み込む:
   - `/Users/kanekohiroki/Desktop/groumapapp/BUSINESS_MODEL.md`（ビジネスモデル定義）
   - `/Users/kanekohiroki/Desktop/groumapapp/SERVICE_FEATURES.md`（サービス機能一覧）
   - `/Users/kanekohiroki/Desktop/groumapapp/STORE_SUBMISSION_TEXTS.md`（ユーザー用アプリのストア申請テキスト集）
   - `/Users/kanekohiroki/Desktop/groumapapp_store/STORE_SUBMISSION_TEXTS.md`（店舗用アプリのストア申請テキスト集）
2. ユーザーの依頼がどちらのアプリ向けか特定する。明示されていない場合は確認する。
   - 「ユーザー用」「ユーザーアプリ」→ ユーザー用アプリのテキストを編集
   - 「店舗用」「店舗アプリ」「for Business」→ 店舗用アプリのテキストを編集
   - 「両方」→ 両方のテキストを編集
3. 各ファイルの内容を把握した上で、ユーザーの依頼に基づきテキストを作成・修正する。
4. 修正後は対象のストア申請テキストファイルを更新する。
5. 更新後、文字数サマリー表の文字数・残り文字数も必ず更新する。

## 各ストアのテキスト文字数制限

### App Store Connect（iOS）

| フィールド | 文字数制限 | 備考 |
|-----------|----------|------|
| アプリ名 | 30文字 | |
| サブタイトル | 30文字 | |
| プロモーション用テキスト | 170文字 | 審査なしで随時更新可能。検索順位には影響しない |
| 概要（説明文） | 4,000文字 | プレーンテキスト（HTMLタグ不可）。改行のみ可 |
| このバージョンの最新情報 | 4,000文字 | 初回リリース以降は毎バージョン必須 |
| キーワード | 100バイト | カンマ区切り。アプリ名・会社名と重複不可 |

### Google Play Store（Android）

| フィールド | 文字数制限 | 備考 |
|-----------|----------|------|
| アプリ名 | 30文字 | |
| 簡単な説明（Short Description） | 80文字 | |
| 詳しい説明（Full Description） | 4,000文字 | |

## 運用ルール

- テキストの変更は必ずユーザーの承認を得てからドキュメントに反映する。
- ビジネスモデル・サービス機能の内容と矛盾しないテキストを作成する。矛盾がある場合はその旨を明示する。
- 各フィールドの文字数制限を必ず守る。制限を超える場合は警告する。
- プロモーション用テキストは検索順位に影響しないため、キーワード詰め込みではなく訴求力を重視する。
- Google Play の簡単な説明・詳しい説明は検索キーワードを自然に含める（ASO考慮）。
- キーワードフィールド（App Store）にはアプリ名・会社名と重複する語を入れない。
