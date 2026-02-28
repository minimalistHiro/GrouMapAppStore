---
name: owner-check-rules
description: 「オーナー」「オーナー判定」「オーナーの店舗」「オーナー除外」など、オーナーに関する判定・フィルタリング・権限チェックを行う際に、必ずFIRESTORE.mdでデータベース構造を確認してからusersコレクションで判定するためのルール。
---

# Owner Check Rules

## 概要

GrouMapにおける「オーナー」の判定は、**`users`コレクション**のフィールドで行う。`stores`コレクションの`isOwner`フラグは表示制御用であり、オーナー判定のソースではない。

## 必須手順

「オーナー」に関する実装（判定・除外・フィルタ・権限チェック等）を行う前に、以下を必ず実施する。

### 1. FIRESTORE.md を読み込む

- `FIRESTORE.md` が現在のリポジトリに存在する場合はそれを読む。
- 見つからない場合は `/Users/kanekohiroki/Desktop/groumapapp/FIRESTORE.md` を読む。
- 特に `users` コレクションの以下のフィールドを確認する:
  - `isOwner`: オーナー判定（全体管理権限）
  - `isStoreOwner`: 店舗オーナー判定
  - `createdStores`: オーナーが作成した店舗IDの配列

### 2. 正しいオーナー判定を適用する

| 判定内容 | 参照先 | フィールド |
|---------|--------|-----------|
| ユーザーが全体管理者か | `users/{uid}` | `isOwner == true` |
| ユーザーが店舗オーナーか | `users/{uid}` | `isStoreOwner == true` |
| ユーザーが特定店舗のオーナーか | `users/{uid}` | `createdStores` 配列に該当storeIdが含まれるか |
| オーナーの店舗を除外する | `users/{uid}` | `createdStores` 配列に含まれるstoreIdを除外 |

### 3. やってはいけないこと

- **`stores`コレクションの`isOwner`フラグでオーナー判定しない**: このフラグはユーザーアプリの表示制御用（`isOwner=true`の店舗をマップ等で非表示にする）であり、オーナーの判定ソースではない。
- **FIRESTORE.mdを確認せずにオーナー判定ロジックを実装しない**: データベース構造の変更がある可能性があるため、毎回確認する。

## 既存のプロバイダー（参考）

店舗用アプリで利用可能なオーナー判定プロバイダー:

- `userIsAdminOwnerProvider`（`auth_provider.dart`）: `users/{uid}.isOwner == true` を判定
- `userIsOwnerProvider`（`auth_provider.dart`）: `users/{uid}.isStoreOwner == true` を判定

## Firestoreルールでの判定関数（参考）

```
function isOwner() {
  return request.auth != null &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isOwner == true;
}

function isStoreOwner(storeId) {
  return request.auth != null &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isStoreOwner == true &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.createdStores.hasAny([storeId]);
}
```
