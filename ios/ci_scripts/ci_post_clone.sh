#!/bin/sh
set -e

echo "=== Flutter SDK のインストール ==="
cd $HOME
git clone https://github.com/flutter/flutter.git --depth=1 -b 3.24.0
export PATH="$HOME/flutter/bin:$PATH"

echo "=== Flutter の初期化 ==="
flutter precache --ios

echo "=== プロジェクトルートへ移動 ==="
cd $CI_PRIMARY_REPOSITORY_PATH

echo "=== 依存関係インストール ==="
flutter pub get

echo "=== CocoaPods インストール ==="
cd ios
pod install --no-repo-update
cd ..

echo "=== iOSビルド（署名なし） ==="
flutter build ios --release --no-codesign

echo "=== 完了 ==="
