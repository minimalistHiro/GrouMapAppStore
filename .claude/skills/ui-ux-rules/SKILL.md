---
name: ui-ux-rules
description: GrouMapの画面作成・画面編集でUI/UXルールを適用するためのガイド。ユーザーが「画面作成」「画面編集」「UI」「UX」「レイアウト」「デザイン」や画面の見た目・レイアウト変更を依頼したときに使う。「スタンプ」「スタンプカード」に関するUI変更時にも使う。
---

# UI/UX Rules

## 概要

GrouMapの画面作成・編集時に、既定のUI/UXルールを必ず適用する。ユーザー用・店舗用の両方で同一UIとなるように、共通ウィジェットは同等実装を維持する。

## ガイドライン

- **ユーザー用**は `/Users/kanekohiroki/Desktop/groumapapp/lib/widgets/` の各ウィジェットを使用する。
- **店舗用**は `/Users/kanekohiroki/Desktop/groumapapp_store/lib/widgets/` の同名ウィジェットを使用し、ユーザー用と同一UIになるよう実装を揃える。
- ヘッダーは `common_header.dart` を使用する。
- ボタンは `custom_button.dart` を使用する。
- テキストフィールドは `error_dialog.dart` を使用する。
- 画面背景は `Color(0xFFFBF6F2)`（`#FBF6F2`）を基準に、他画面も同系統で統一する。
- 上部タブは `custom_top_tab_bar.dart` を使用する。
- 上部タブの配色はオレンジ背景 `#FF6B35`（`Color(0xFFFF6B35)`）＋白テキストで統一する。
- 検索窓を新設/改修する場合は、今回作成した共通のカスタム検索窓UI（丸角・白背景・影・左検索アイコン付きの `TextField`）を使用する。
- 青色のテキストボタンは `Colors.blue`（`Color(0xFF2196F3)` 相当）を使用し、文字は **ボールド** にする。
- 入力不備がある場合は、ボタンの下に赤文字（`Colors.red`）・フォントサイズ12のテキストを表示する（ボールドにしない）。
- 店舗アイコン未設定時のデフォルト表示は、店舗詳細画面の既定仕様に合わせる（アイコンと背景色はカテゴリ依存、背景色はアイコン色の `withOpacity(0.1)` を使用）。
  - カテゴリごとのアイコン・色の一覧は `/Users/kanekohiroki/Desktop/groumapapp/CATEGORY_LIST.md` を参照する。
  - コード上では `StampCardWidget.getCategoryIcon(category)` / `StampCardWidget.getCategoryColor(category)`（`lib/widgets/stamp_card_widget.dart`）を使用する。
- ユーザーのデフォルトアイコンは、背景色をアイコン色の `withOpacity(0.1)` にし、アイコンはホーム画面と同じ人型（`Icons.person`）を使用する。
- プロフィール画像の作成/更新は、店舗用・ユーザー用ともに共通のカスタムアイコンUIを使用する（`IconImagePickerField`）。タップで画像選択→位置調整画面へ遷移し、右上のマイナスボタンで画像削除を行う。
- アイコン以外の画像を作成/更新する際は、共通の `ImagePickerField` を使用する。
- 画像比率は `/Users/kanekohiroki/Desktop/groumapapp/IMAGE_RATIOS.md` を参照する。記載がない・不明な場合は独断で決めずにユーザーへ確認する。
- 新たに決定した画像比率は、このスキル（`/Users/kanekohiroki/Desktop/groumapapp/.codex/skills/ui-ux-rules/SKILL.md`）に追記する。
- 成功時の通知は表示しない（緑のスナックバーは使わない）。
- エラー時は赤いスナックバーを使わず、デフォルトのダイアログで日本語メッセージを表示する。
- リストに表示する数値バッジは共通仕様とし、`padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2)`、`borderRadius: 10`、テキストは `fontSize: 11`（白・太字）を使用する。
- 下部タブに付けるバッジは共通仕様とし、数値表示ではなく赤丸のみ、サイズは `width: 10`、`height: 10`、`shape: BoxShape.circle` を使用する。
- カードUIは共通仕様として、角丸16・背景色は白（`Colors.white`）・影無し（`boxShadow` は空 or なし）で統一する。
- トグルは共通仕様として、`custom_switch_tile.dart` のカスタムトグル（`CustomSwitchListTile`）を使用する。
- キーボードのタップ外閉じは共通化する。原則として画面の body を `DismissKeyboard` でラップする（`lib/widgets/dismiss_keyboard.dart` / `groumapapp_store/lib/widgets/dismiss_keyboard.dart`）。
  - 例外: ユーザー用アプリのマップ画面は対象外（タップ操作が多いため適用しない）。
- スクロール可能な画面では、最下部に `SizedBox(height: 16)` 相当の余白を入れる。
- スタンプカードUIは共通のカスタムウィジェット `StampCardWidget`（`lib/widgets/stamp_card_widget.dart`）を使用する。スタンプカードを表示する画面では、直接グリッドを組み立てずに必ずこのウィジェットを利用する。
  - **パラメータ**: `storeName`、`storeCategory`、`iconImageUrl`（任意）、`stamps`、`maxStamps`（デフォルト10）、`displayStamps`（任意）、`isLoading`、`isSyncing`、`errorMessage`、`punchIndex`、`scaleAnimation`、`shineAnimation`
  - **カテゴリ色・アイコンの取得**: `StampCardWidget.getCategoryColor(category)` / `StampCardWidget.getCategoryIcon(category)` を静的メソッドとして使用する。
  - スタンプカードのデザインや仕様を変更する場合は、各画面ではなく `StampCardWidget` 本体を修正する。
- 統計情報UIは共通のカスタムウィジェット `StatsCard`（`lib/widgets/stats_card.dart`）を使用する。統計情報を表示する画面では、直接レイアウトを組み立てずに必ずこのウィジェットを利用する。
  - **パラメータ**: `title`（タイトル）、`titleIcon`（任意）、`items`（`StatItem`リスト）、`showShadow`（デフォルトtrue）、`margin`（任意）、`child`（任意のカスタムコンテンツ）
  - **`StatItem`**: 各統計項目のデータモデル。`label`（ラベル）、`value`（値）、`icon`（アイコン）、`color`（色）を指定する。
  - **`StatsRow`**: 統計項目を横一列に並べるウィジェット。カードなしで単独利用も可能。
  - 統計情報のデザインや仕様を変更する場合は、各画面ではなく `StatsCard` 本体を修正する。
- **設定画面のリスト項目と通知バッジ**: 設定画面にリスト項目を追加する際は、必ず通知バッジ対応をセットで行う。以下のルールに従う。
  - 設定画面の各リスト項目は `_buildSettingsItem()` で生成し、`badgeCount` パラメータ（デフォルト `0`）でバッジ数を制御する。
  - `badgeCount > 0` のとき、リスト項目の右側に赤い数値バッジ（`padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2)`、`borderRadius: 10`、テキスト `fontSize: 11` 白・太字、99超は `99+` 表示）＋ `chevron_right` アイコンを表示する。`badgeCount == 0` のときは `chevron_right` アイコンのみ。
  - バッジのカウントソースは `settings_badge_provider.dart` でプロバイダーとして定義する。新しいバッジカウントを追加する場合は、個別の `StreamProvider<int>` を作成し、`settingsTotalBadgeCountProvider` にもカウントを追加する。
  - `settingsTotalBadgeCountProvider` はユーザーの権限（`isAdminOwner` 等）に応じて、**実際に表示されている項目のバッジ数のみ**を合計する。非表示セクションのバッジは含めない。
  - 下部タブの「設定」バッジは `settingsTotalBadgeCountProvider` の値が `1` 以上の場合のみ赤丸を表示する（数値なし）。
  - 店舗用: `groumapapp_store/lib/providers/settings_badge_provider.dart`
