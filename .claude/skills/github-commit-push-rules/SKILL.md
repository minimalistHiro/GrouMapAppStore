---
name: github-commit-push-rules
description: GrouMapプロジェクトで「GitHubにコミットしてプッシュして」などの依頼が来たときに適用するGit操作ルール。コミット・プッシュ・mainマージ・ブランチ運用の手順を厳守する。
---

# GitHub Commit Push Rules

## 概要

GrouMapのユーザー/店舗アプリの変更をGitHubへコミット・プッシュする際の必須手順を適用する。依頼があった場合は常にユーザー用・店舗用の両リポジトリで同様の手順を確認・実行する。

## 手順

ユーザーから「GitHubにコミットしてプッシュして」と依頼されたら、必ず以下の手順を順守する。

1. `/Users/kanekohiroki/Desktop/groumapapp/FIRESTORE.md` を読み込み、Firestore関連（プロバイダー追加、コレクション/ドキュメントの作成・削除・更新など）の変更がある場合は、FIRESTORE.md を追記・修正する（ユーザー用・店舗用リポジトリの変更がある場合も対象）。
2. 今回の変更に画面の作成や画面の変更等がある場合、`/Users/kanekohiroki/Desktop/groumapapp/USER_APP_SCREENS.md` と `/Users/kanekohiroki/Desktop/groumapapp_store/STORE_APP_SCREENS.md` を修正する。
3. 今回の変更にサービス内容（機能追加・変更・削除、仕様変更など）に関わる箇所がある場合、`/Users/kanekohiroki/Desktop/groumapapp/SERVICE_FEATURES.md` を追記・修正する。
4. ユーザー用リポジトリと店舗用リポジトリの両方で `git status -sb` を確認する。
5. 変更があるリポジトリは以下を順に実行する（変更がない場合は「変更なし」と報告してスキップ）。
6. 現在のブランチをコミットしてプッシュする。
7. その後、`main`にマージして`main`へpushする。
8. マージ後は元のブランチに戻す。
9. 元のブランチへ戻した時、そのブランチ名が今日の日付（`YYYY-mm-dd`）でない場合は、新しいブランチを`YYYY-mm-dd`形式で作成して切り替える。
10. `.gitignore`に含まれているもの以外は全てコミットする。
11. コミットメッセージは任意。
12. 依頼があった場合は両リポジトリを必ず確認し、変更がある場合は両方で同じ手順を実行する。
13. どちらか一方のみ変更がある場合でも、もう一方は「変更なし」を明示して報告する。

## 注意事項

- 依頼があるまで勝手にコミット・プッシュを行わない。
- 既存の未コミット変更がある場合は、内容を確認してから手順を進める。
