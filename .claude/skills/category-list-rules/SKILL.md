---
name: category-list-rules
description: カテゴリ・サブカテゴリの一覧参照/追加/削除/編集/表示変更に関する依頼で使用する。店舗情報入力やカテゴリ編集、カテゴリ一覧の確認・更新が含まれる場合、/Users/kanekohiroki/Desktop/groumapapp/CATEGORY_LIST.md を参照し、変更があれば同ファイルを更新する。
---

# Category List Rules

## 概要
- カテゴリ/サブカテゴリの単一ソースは `CATEGORY_LIST.md` とする。
- カテゴリの変更が発生したら、コード変更と同時に `CATEGORY_LIST.md` を必ず更新する。

## 手順
1. 依頼内容が「カテゴリ」「サブカテゴリ」「ジャンル」「一覧」「カテゴリ編集」に該当するか判断する。
2. 該当する場合は `/Users/kanekohiroki/Desktop/groumapapp/CATEGORY_LIST.md` を開いて一覧を確認する。
3. 回答や実装で一覧を使う場合は、同ファイルの内容を正として扱う。
4. 追加/削除/名称変更があった場合は、コード変更と同時に `CATEGORY_LIST.md` を追記・修正・削除する。
5. 画面上のカテゴリ編集UIを変更した場合も、同ファイルを必ず更新する。

## 実装メモ
- 店舗アプリのカテゴリ一覧を変更した場合は、画面のカテゴリ選択と `CATEGORY_LIST.md` の内容が一致するように維持する。
