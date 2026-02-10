---
name: firestore-rules-routing
description: Firestore ルール、Firebase Functions、Firebase 設定変更の作業先を正しいリポジトリに誘導する。Firestore ルール、firestore.rules、Firebase Functions/functions、firebase.json、firestore.indexes.json が話題に出たときに使う。
---

# Firestore/Firebase Routing Rules

## Rules

- Firestore ルールの変更は必ずユーザーアプリのリポジトリで行う。
  - 編集対象: `/Users/kanekohiroki/Desktop/groumapapp/firestore.rules`
  - ルール変更後は、Codex が **必ず自分で** デプロイまで実行する（`firebase deploy --only firestore:rules`）。
  - 店舗アプリ側リポジトリでルール更新やデプロイは行わない。

- Firebase 関連の設定変更はユーザーアプリのリポジトリ内のファイルを編集する。
  - `/Users/kanekohiroki/Desktop/groumapapp/firebase.json`
  - `/Users/kanekohiroki/Desktop/groumapapp/firestore.indexes.json`

- Firebase Functions に関する変更はユーザーアプリのリポジトリで扱う。
  - 対象: `/Users/kanekohiroki/Desktop/groumapapp/backend/functions`

## Expected Behavior

- 依頼が店舗アプリ側のリポジトリでの Firestore ルール/デプロイ/設定変更を要求していても、上記ルールに従ってユーザーアプリ側へ誘導する。
- ルール違反の操作は実行せず、正しいリポジトリとファイルパスを明示して説明する。
- Firestore ルールを変更した場合、変更内容の説明後に **必ず** デプロイを実行する。

## 認証・再認証

- Firebase CLI の認証や再認証が必要な場合は、`firebase login --reauth` を自分で実行する。
- ブラウザでのログイン操作はユーザーに依頼し、完了後は自分が続行する。
