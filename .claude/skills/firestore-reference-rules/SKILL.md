---
name: firestore-reference-rules
description: Firestore/データベースに関する作業で必ずFIRESTORE.mdを読み込むためのルール。DB設計、コレクション追加、Firestore変更、スキーマ更新、データベース設計・作成・更新・書き換えなどの依頼時に使う。
---

# Firestore Reference Rules

## 手順

- Firestore/データベース設計・更新・作成・書き換えに着手する前に、必ずFIRESTORE.mdを読み込む。
- `FIRESTORE.md` が現在のリポジトリに存在する場合はそれを読む。
- 店舗用リポジトリなどで `FIRESTORE.md` が見つからない場合は、`/Users/kanekohiroki/Desktop/groumapapp/FIRESTORE.md` を読む。
- どちらにも存在しない場合は、作業を止めてユーザーに場所の確認を依頼する。

## 運用ルール

- FIRESTORE.md の内容に沿って設計・変更内容を判断する。
- スキーマの追加/変更がある場合は、FIRESTORE.md 側の追記・更新も検討する（必要時のみ）。

## デプロイルール

- Cloud Functions（`backend/functions/src/index.ts`）に変更を加えた場合は、コード変更後にデプロイまで実行する。
- デプロイ手順:
  1. ビルド: `cd /Users/kanekohiroki/Desktop/groumapapp/backend/functions && npm run build`
  2. デプロイ: `cd /Users/kanekohiroki/Desktop/groumapapp && firebase deploy --only functions:<変更した関数名>`
  3. 変更した関数のみを `--only functions:<関数名>` で指定してデプロイする。
- デプロイが成功したことを確認してからユーザーに報告する。
