# Xcode Cloud + TestFlight による スマホ即時確認フロー

## 目的

スマホ（iPhone）から Tailscale + Mosh + Claude Code で開発作業を行い、
コードを修正したあと `git push` するだけで、TestFlight 経由でスマホ上に即座にビルドを届ける。

Mac を使わずに、**コード修正 → 動作確認** のサイクルをスマホ単体で完結させることが目的。

---

## 全体の流れ

```
スマホ
  └─ Tailscale VPN で Mac に接続
       └─ Mosh + Claude Code でコード修正
            └─ git push origin main
                 └─ Xcode Cloud が自動検知
                      └─ Flutter ビルド（15〜25分）
                           └─ TestFlight に自動配信
                                └─ スマホで通知 → インストール → 動作確認
```

---

## 構成要素

| 要素 | 役割 |
|------|------|
| Tailscale | スマホから自宅 Mac に VPN 接続する |
| Mosh | 不安定なモバイル回線でも切れない SSH 接続 |
| Claude Code | スマホ上のターミナルからコード編集・Git 操作を行う |
| GitHub | コードのリモートリポジトリ（`main` ブランチへのプッシュがトリガー）|
| Xcode Cloud | Apple の CI/CD サービス。GitHub プッシュを検知して自動ビルド |
| TestFlight | Apple の内部テスト配信サービス。ビルド完了後にスマホへ自動配信 |

---

## セットアップ手順（初回のみ・Mac 作業）

### 1. CI スクリプトの作成

Xcode Cloud のビルド環境に Flutter が存在しないため、ビルド前に自動インストールするスクリプトを用意する。

**ファイル:** `ios/ci_scripts/ci_post_clone.sh`

```bash
#!/bin/sh
set -e

echo "=== Flutter SDK のインストール ==="
cd $HOME
git clone https://github.com/flutter/flutter.git --depth=1 -b stable
export PATH="$HOME/flutter/bin:$PATH"

echo "=== Flutter の初期化 ==="
flutter precache --ios

echo "=== プロジェクトルートへ移動 ==="
cd $CI_PRIMARY_REPOSITORY_PATH

echo "=== 依存関係インストール ==="
flutter pub get

echo "=== CocoaPods インストール ==="
cd ios
pod install --repo-update
cd ..

echo "=== iOSビルド（署名なし） ==="
flutter build ios --release --no-codesign

echo "=== 完了 ==="
```

実行権限を付与してコミット・プッシュする。

```bash
chmod +x ios/ci_scripts/ci_post_clone.sh
git add ios/ci_scripts/ci_post_clone.sh
git commit -m "ci: Xcode Cloud用 ci_post_clone.sh を追加"
git push origin main
```

---

### 2. Xcode でワークフローを作成

`ios/Runner.xcworkspace` を Xcode で開き、以下の手順でワークフローを作成する。

```
Xcode メニュー: Integrate → Create Workflow...
```

**ワークフロー設定内容:**

| 項目 | 設定値 |
|------|--------|
| Workflow Name | 任意（例: `Default`） |
| Environment | Latest Release（Xcode 最新版） |
| Start Conditions | Branch Changes → `main` |
| Actions | Archive - iOS |
| Distribution Preparation | App Store |
| Post-Actions | TestFlight Internal Testing |
| Artifact | Archive - iOS |
| Groups | TestFlight の内部テスターグループ |

**注意点:**
- Post-Actions の TestFlight は、Actions に `Archive - iOS` を追加してから設定しないと Artifact が空になり選択できない
- 初回セットアップ完了前は Post-Actions がグレーアウトされる。いったん Save → Next でセットアップを完了させてから再編集する
- GitHub へのアクセス許可（Grant Access）が求められたら承認する

---

### 3. TestFlight の内部テスターグループを作成

App Store Connect でテスターグループを用意する。

```
appstoreconnect.apple.com
→ 対象アプリ → TestFlight タブ
→ 内部テスト → グループ作成（例: GrouMap）
→ 自分の Apple ID をテスターとして追加
```

---

## 日常の開発フロー（スマホのみで完結）

```bash
# 1. スマホから Mosh で Mac に接続
# 2. Claude Code でコードを修正
# 3. 変更をコミット・プッシュ

git add .
git commit -m "fix: ○○を修正"
git push origin main

# → Xcode Cloud が自動でビルド開始（約 15〜25 分）
# → 完了後 TestFlight アプリに通知
# → スマホでインストール → 動作確認
```

---

## ビルドの進捗確認

```
appstoreconnect.apple.com
→ 左サイドバー「Xcode Cloud」
→「ビルド」タブ
```

---

## Xcode Cloud の無料枠

| 項目 | 内容 |
|------|------|
| 無料枠 | 月 25 コンピュート時間 |
| ビルド回数目安 | 約 75〜100 回/月 |
| 超過時 | 従量課金（通常の開発頻度では超過しない） |

---

## トラブルシューティング

| 症状 | 原因 | 対処 |
|------|------|------|
| Post-Actions がグレーアウト | 初回セットアップ未完了 | いったん Save → Next でセットアップを完了させてから再編集 |
| Artifact が空 | Archive アクションが未設定 | Actions に `Archive - iOS` を先に追加する |
| ビルドが失敗する | ci_post_clone.sh のエラー | App Store Connect → Xcode Cloud → ビルド → ログで詳細確認 |
| TestFlight に届かない | グループ未設定 | Post-Actions でテスターグループが選択されているか確認 |
