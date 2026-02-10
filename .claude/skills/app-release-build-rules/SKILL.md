---
name: app-release-build-rules
description: GrouMapプロジェクトで「アプリをリリースして」等の依頼が来たときに、Google Play/App Store向けのリリースビルド手順を実行するために使う。
---

# App Release Build Rules

## 概要

GrouMapのリリース依頼時に、AndroidのAAB作成とiOSビルド準備を順番に実行する。iOSのArchiveはコマンドで作成し、Xcode Organizer に表示されるようアーカイブ場所へコピーして開くところまで行う。

## 手順

ユーザーから「アプリをリリースして」等の依頼が来た場合は、以下を順番どおりに実施する。

1. Android向けに`flutter build appbundle`を実行し、Google Playリリース用のAABを作成する。
2. `ios`ディレクトリで`pod install`を実行する（`cd ios && pod install`）。
3. `flutter build ios`を実行し、App Storeリリース向けのビルドを行う。
4. iOSのArchiveを`xcodebuild`で実行する。
   - ワークスペース: `ios/Runner.xcworkspace`
   - Scheme: `Runner`
   - Configuration: `Release`
   - 出力先: `ios/build/Runner.xcarchive`
   - 例: `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath ios/build/Runner.xcarchive archive`
5. Xcode Organizer に表示されるよう、最初から既定の Archives 直下へアーカイブを作成して開く（コピー工程を省略）。
   - 例:
     - `archive_date=$(date "+%Y-%m-%d")`
     - `archive_name="Runner $(date "+%Y-%m-%d %H.%M").xcarchive"`
     - `archive_dir="/Users/kanekohiroki/Library/Developer/Xcode/Archives/$archive_date"`
     - `mkdir -p "$archive_dir"`
     - `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath "$archive_dir/$archive_name" archive`
     - `open -a Xcode "$archive_dir/$archive_name"`

6. 一連の流れが完了したら、店舗用アプリも同じ手順で実行する。
   - 対象プロジェクト: `/Users/kanekohiroki/Desktop/groumapapp_store`
   - 手順は上記 1〜5 をそのまま繰り返す。

## 注意事項

- iOSのアップロードは手動で進める（Archive作成後の配布はGUIで実施）。
- 権限不足や依存エラーが出た場合は、ターミナルでコマンドを実行して確認・修正する。
- `flutter build appbundle` で権限エラーが出る場合は、Flutter SDK の所有権を一度だけ修正して以後の sudo を不要にする。
  - 例:
    - `sudo chown -R $(whoami) /Users/kanekohiroki/Developer/flutter`
    - `sudo chmod -R u+rwX /Users/kanekohiroki/Developer/flutter`
