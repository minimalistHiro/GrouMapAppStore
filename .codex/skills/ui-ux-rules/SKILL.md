---
name: ui-ux-rules
description: 【必須・最優先】GrouMapのFlutter画面作成・画面編集・UI実装・コード修正・機能追加でUI/UXルールを適用するためのガイド。このスキルを発動せずにFlutterコードを1行でも書くことは禁止。「作成して」「修正して」「編集して」「追加して」「実装して」「画面」「ウィジェット」「UI」「UX」「レイアウト」「デザイン」「ボタン」「フォーム」「カード」「リスト」「タブ」「画面の見た目」「図鑑」「マップ」「dart」などのキーワードを含む依頼時に、コードを書く前に必ず最初に発動すること。スタンプ・スタンプカードのUI変更時にも使う。
---

# UI/UX Rules

## 概要

GrouMapの画面作成・編集時に、このファイルに記載のUI/UXルールを最優先で適用すること。ユーザー用・店舗用の両方で同一UIとなるように、共通ウィジェットは同等実装を維持する。**このルールに違反する実装は行わないこと。**

## 実装前・実装後の必須チェックリスト

**Flutterコードを書く前に確認し、書いた後にも照合すること。1つでも違反があれば修正してから完了とすること。**

- [ ] ボタンは `CustomButton`（`custom_button.dart`）を使っているか（`ElevatedButton` / `TextButton` / `OutlinedButton` の直接使用は禁止）
- [ ] ヘッダーは `CommonHeader`（`common_header.dart`）を使っているか
- [ ] `showSnackBar` を一切使っていないか（成功・エラー・情報のいずれも完全禁止）
- [ ] ダイアログ表示は `showGameDialog`（`game_dialog.dart`）を使っているか（`showDialog` / `AlertDialog` の直接使用は禁止）
- [ ] エラーメッセージは日本語か、詳細ログ（スタックトレース等）はダイアログに含まれていないか
- [ ] 画面背景色は `Color(0xFFFBF6F2)` か
- [ ] カードUIは角丸16・白背景・影なしか
- [ ] スクロール可能な画面の最下部に `SizedBox(height: 16)` の余白があるか
- [ ] スタンプカードは `StampCardWidget` を使っているか（直接グリッド組み立て禁止）
- [ ] 統計情報は `StatsCard` を使っているか
- [ ] トグルは `CustomSwitchListTile`（`custom_switch_tile.dart`）を使っているか
- [ ] テキストラベル切り替えトグルは `CompactToggleBar`（`compact_toggle_bar.dart`）を使っているか
- [ ] キーボードのタップ外閉じのため body を `DismissKeyboard` でラップしているか（マップ画面を除く）
- [ ] 画面全体を待たせるローディングは `CustomLoadingIndicator`（`custom_loading_indicator.dart`）/ `AppLoadingOverlay`（`app_loading_overlay.dart`）で中央表示・グレーアウト・タップ無効化になっているか
- [ ] 設定/アクションメニューのリスト項目は `FloatingMenuItem`（`floating_menu_item.dart`）を使っているか（`ListTile` 直接使用禁止）
- [ ] コンテンツリスト（お知らせ・履歴等）の項目は `FloatingListItem`（`floating_list_item.dart`）を使っているか（`ListTile` 直接使用禁止）

## ガイドライン

- **【必須】ユーザー用**は `/Users/kanekohiroki/Desktop/groumapapp/lib/widgets/` の各ウィジェットを使用すること。
- **【必須】店舗用**は `/Users/kanekohiroki/Desktop/groumapapp_store/lib/widgets/` の同名ウィジェットを使用し、ユーザー用と同一UIになるよう実装を揃えること。
- **【必須】ヘッダーは必ず `CommonHeader`（`common_header.dart`）を使うこと。**
- **【必須】ボタンは必ず `CustomButton`（`custom_button.dart`）を使うこと。`ElevatedButton` / `TextButton` / `OutlinedButton` の直接使用は禁止。**
- テキストフィールドは `error_dialog.dart` を使用する。
- **【必須】画面背景は必ず `Color(0xFFFBF6F2)`（`#FBF6F2`）を使うこと。**
- **【必須】上部タブは必ず `CustomTopTabBar`（`custom_top_tab_bar.dart`）を使うこと。** 配色は背景色 `#FBF6F2`＋黒テキスト＋黒インジケーターで統一する。
- 検索窓を新設/改修する場合は、共通のカスタム検索窓UI（丸角・白背景・影・左検索アイコン付きの `TextField`）を使用すること。
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
- **【禁止】`showSnackBar` は成功・エラー・情報のいずれの場合も使用禁止。`ScaffoldMessenger.of(context).showSnackBar(...)` を呼び出さないこと。**
- **【禁止】成功時の通知は一切表示しない。** 処理完了を示すダイアログ・バー・トーストも不要。
- **【必須】ダイアログは必ず `showGameDialog`（`game_dialog.dart`）で表示すること。`showDialog` / `AlertDialog` の直接使用は禁止。**
  - エラーメッセージは必ず**日本語**で記述し、ユーザーに分かりやすい表現にする（「エラーが発生しました。もう一度お試しください。」など）。
  - 詳細なエラーログ（スタックトレース・例外クラス名・内部エラーコードなど）はダイアログ本文に含めない。デバッグ用ログは `debugPrint` 等でコンソールのみに出力する。
- リストに表示する数値バッジは共通仕様とし、`padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2)`、`borderRadius: 10`、テキストは `fontSize: 11`（白・太字）を使用する。
- 下部タブに付けるバッジは共通仕様とし、数値表示ではなく赤丸のみ、サイズは `width: 10`、`height: 10`、`shape: BoxShape.circle` を使用する。
- **【必須】カードUIは角丸16・背景色は白（`Colors.white`）・影無し（`boxShadow` は空 or なし）で統一すること。**
- **【必須】影をつける場合は、必ずポップアップ（`GameDialog`）と同じ標準影スタイルを使用すること。`elevation` による影付けは禁止。** 詳細は `shadow-rules` スキル参照。
  ```dart
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF9BB8D4).withOpacity(0.6),
      blurRadius: 40,
      spreadRadius: 8,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ],
  ```
- **【必須】保存・更新・送信など、画面全体を待たせる非同期処理のローディングは `CustomLoadingIndicator`（`custom_loading_indicator.dart`）と `AppLoadingOverlay`（`app_loading_overlay.dart`）を使うこと。**
  - インジケーターは画面中央に表示する。
  - 背景はグレーアウトし、処理中は他のボタンや入力欄を触れないようにする。
  - 色はプライマリオレンジ（`AppUi.primary` / `StoreUi.primary` 相当）を使うこと。
  - 保存ボタンの上だけで回る `CircularProgressIndicator` のような局所ローディングは禁止。画面全体をブロックする。
  - 単体で使う場合は `CustomLoadingIndicator`、全面オーバーレイが必要な場合は `AppLoadingOverlay` を使用する。
- **【必須】ON/OFFトグルは必ず `CustomSwitchListTile`（`custom_switch_tile.dart`）を使うこと。**
- **【必須】テキストラベルで切り替えるピル型トグルは必ず `CompactToggleBar`（`compact_toggle_bar.dart`）を使うこと。** 白背景・影あり・プライマリカラー選択のコンパクトなフローティングトグル。マップ画面の「開拓率 / 賑わい度」切り替えなどに使用する。
  - **パラメータ**: `labels`（ラベル文字列リスト）、`selectedIndex`（選択中インデックス）、`onChanged`（選択変更コールバック）
  - 任意: `activeColor`（選択色、デフォルト: テーマprimary）、`activeTextColor`（選択テキスト色、デフォルト: white）、`inactiveTextColor`（非選択テキスト色）、`backgroundColor`（背景色）、`fontSize`（デフォルト: 12）
- **【必須】キーボードのタップ外閉じのため、画面の body を必ず `DismissKeyboard` でラップすること。**（`lib/widgets/dismiss_keyboard.dart` / `groumapapp_store/lib/widgets/dismiss_keyboard.dart`）
  - 例外: ユーザー用アプリのマップ画面は対象外（タップ操作が多いため適用しない）。
- **【必須】スクロール可能な画面では、最下部に必ず `SizedBox(height: 16)` 相当の余白を入れること。**
- スタンプカードUIは共通のカスタムウィジェット `StampCardWidget`（`lib/widgets/stamp_card_widget.dart`）を使用する。スタンプカードを表示する画面では、直接グリッドを組み立てずに必ずこのウィジェットを利用する。
  - **パラメータ**: `storeName`、`storeCategory`、`iconImageUrl`（任意）、`stamps`、`maxStamps`（デフォルト10）、`displayStamps`（任意）、`isLoading`、`isSyncing`、`errorMessage`、`punchIndex`、`scaleAnimation`、`shineAnimation`
  - **カテゴリ色・アイコンの取得**: `StampCardWidget.getCategoryColor(category)` / `StampCardWidget.getCategoryIcon(category)` を静的メソッドとして使用する。
  - スタンプカードのデザインや仕様を変更する場合は、各画面ではなく `StampCardWidget` 本体を修正する。
- 統計情報UIは共通のカスタムウィジェット `StatsCard`（`lib/widgets/stats_card.dart`）を使用する。統計情報を表示する画面では、直接レイアウトを組み立てずに必ずこのウィジェットを利用する。
  - **パラメータ**: `title`（タイトル）、`titleIcon`（任意）、`items`（`StatItem`リスト）、`showShadow`（デフォルトtrue）、`margin`（任意）、`child`（任意のカスタムコンテンツ）
  - **`StatItem`**: 各統計項目のデータモデル。`label`（ラベル）、`value`（値）、`icon`（アイコン）、`color`（色）を指定する。
  - **`StatsRow`**: 統計項目を横一列に並べるウィジェット。カードなしで単独利用も可能。
  - 統計情報のデザインや仕様を変更する場合は、各画面ではなく `StatsCard` 本体を修正する。
- **ダイアログUIは `GameDialog`（`game_dialog.dart`）を使用する。** Flutterデフォルトの `showDialog` / `AlertDialog` の直接使用は禁止。
  - 呼び出しは `showGameDialog(context, title, message, actions, icon, headerColor)` のヘルパー関数を使用する。
  - **パラメータ**:
    - `title`: ダイアログタイトル（日本語）
    - `message`: 本文メッセージ（日本語）
    - `actions`: `GameDialogAction` のリスト。各アクションに `label`・`onPressed`・`isPrimary`（Primary ボタンか否か）・`color`（任意）を指定する
    - `icon`: ヘッダーアイコン（デフォルト: `Icons.info_outline`）
    - `headerColor`: ヘッダー背景色（デフォルト: `AppUi.primary`）
  - Primary ボタンはヘッダー色の塗りつぶし、非 Primary ボタンは白地＋ヘッダー色のボーダーで表示される。
  - ユーザー用: `lib/widgets/game_dialog.dart` / 店舗用: `lib/widgets/game_dialog.dart`（存在しない場合はユーザー用を参考に同等実装を作成する）
- **【必須】設定/アクションリストは `FloatingMenuItem`（`floating_menu_item.dart`）を使うこと。** 白背景・カプセル型（borderRadius: 100）・影付きのフローティングボタン。`ListTile` の直接使用は禁止。
  - **パラメータ**: `icon`（IconData）、`title`（String）、`onTap`（VoidCallback）
  - 任意: `iconColor`（デフォルト: primary）、`trailing`（デフォルト: chevron_right）、`isDestructive`（デフォルト: false）
  - 使用例: アカウント画面の設定メニュー各項目
  - 複数アイテムを縦に並べる場合は `Column` + 各アイテム間に `SizedBox(height: 10)` を入れること
- **【必須】コンテンツリスト（お知らせ・履歴等）は `FloatingListItem`（`floating_list_item.dart`）を使うこと。** 白背景・角丸16・影付きのフローティングカード。`ListTile` の直接使用は禁止。
  - **パラメータ**: `title`（String）、`onTap`（VoidCallback）
  - 任意: `subtitle`（本文プレビュー）、`trailingText`（日付等）、`leading`（カスタムウィジェット）、`trailing`（デフォルト: chevron_right）、`isUnread`（未読ドット表示、デフォルト: false）
  - 使用例: お知らせ画面の通知リスト各項目
  - `ListView.builder` + `padding: EdgeInsets.fromLTRB(16, 16, 16, 0)` + 各アイテムに `Padding(bottom: 10)` を使うこと
- **設定画面のリスト項目と通知バッジ**: 設定画面にリスト項目を追加する際は、必ず通知バッジ対応をセットで行う。以下のルールに従う。
  - 設定画面の各リスト項目は `_buildSettingsItem()` で生成し、`badgeCount` パラメータ（デフォルト `0`）でバッジ数を制御する。
  - `badgeCount > 0` のとき、リスト項目の右側に赤い数値バッジ（`padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2)`、`borderRadius: 10`、テキスト `fontSize: 11` 白・太字、99超は `99+` 表示）＋ `chevron_right` アイコンを表示する。`badgeCount == 0` のときは `chevron_right` アイコンのみ。
  - バッジのカウントソースは `settings_badge_provider.dart` でプロバイダーとして定義する。新しいバッジカウントを追加する場合は、個別の `StreamProvider<int>` を作成し、`settingsTotalBadgeCountProvider` にもカウントを追加する。
  - `settingsTotalBadgeCountProvider` はユーザーの権限に応じて、**実際に表示されている項目のバッジ数のみ**を合計する。非表示セクションのバッジは含めない。
  - 下部タブの「設定」バッジは `settingsTotalBadgeCountProvider` の値が `1` 以上の場合のみ赤丸を表示する（数値なし）。
  - 店舗用: `groumapapp_store/lib/providers/settings_badge_provider.dart`
