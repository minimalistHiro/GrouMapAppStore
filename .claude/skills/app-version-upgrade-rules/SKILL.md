---
name: app-version-upgrade-rules
description: GrouMapプロジェクトでアプリのバージョン更新を依頼されたときの手順。ユーザーが「バージョンをアップして」「バージョンを上げて」「アプリのバージョンをアップして」と依頼した場合に使う。
---

# App Version Upgrade Rules

## 概要

GrouMapのユーザー用/店舗用アプリのバージョン更新時に、必須の更新手順と表記統一を確実に実施する。

## 手順

ユーザーから「バージョンをアップして」「バージョンを上げて」等の依頼が来た場合、以下を順番どおりに実施する（ヘルプページ表示は`+○○`のビルド番号を記載しない）。

1. 各画面のバージョン表記を書き換える前に、先に以下を実施する。
   - ユーザー用の`pubspec.yaml`のアプリバージョンを、最小桁数（`○.○.☆`の☆）を1つ繰り上げ、ビルド番号（`+○○`）を1つ上げる。
   - 店舗用の`pubspec.yaml`のアプリバージョンを、最小桁数（`○.○.☆`の☆）を1つ繰り上げ、ビルド番号（`+○○`）を1つ上げる。
2. ユーザー用の`pubspec.yaml`のバージョンを読み取り、`/Users/kanekohiroki/Desktop/groumapapp/lib/views/support/help_view.dart`の下部にあるバージョン表記を統一し、最終更新日を今日の日付にする（ビルド番号は除外）。
3. 店舗用の`pubspec.yaml`のバージョンを読み取り、`/Users/kanekohiroki/Desktop/groumapapp_store/lib/views/settings/help_support_view.dart`の下部にあるバージョン表記を統一し、最終更新日を今日の日付にする（ビルド番号は除外）。
