# 店舗用アプリ 画面一覧（構成と説明）

この一覧は `/Users/kanekohiroki/Desktop/groumapapp_store/lib/views` 配下の画面実装を基に整理しています。各画面の「構成」は主要なUI要素の概要、「説明」は用途の軽い要約です。

## 起動・ナビゲーション

### MainNavigationView (`lib/views/main_navigation_view.dart`)
- 構成: ボトムタブ（ホーム/分析/QR/クーポン/設定）、FAB（QR起動）
- 説明: 店舗アプリ全体のタブ切替と初期データ読み込みを担うメインナビゲーション

### AuthWrapper (`lib/views/auth/auth_wrapper.dart`)
- 構成: 認証状態判定、メール認証要否の分岐、AppUpdateGate
- 説明: 起動時の認証・認証済み判定を行うラッパー

## 認証・登録

### LoginView (`lib/views/auth/login_view.dart`)
- 構成: ロゴ、メール/パスワード入力、ログインボタン、パスワード再設定導線
- 説明: 店舗アカウントのログイン画面

### SignUpView (`lib/views/auth/sign_up_view.dart`)
- 構成: メール/パスワード入力、登録ボタン
- 説明: 店舗アカウント作成画面

### EmailVerificationPendingView (`lib/views/auth/email_verification_pending_view.dart`)
- 構成: 認証案内、6桁コード入力、認証/再送、戻る/削除導線
- 説明: メール認証コード入力画面

### PasswordResetView (`lib/views/auth/password_reset_view.dart`)
- 構成: メールアドレス入力、再設定メール送信
- 説明: パスワード再設定画面

### StoreInfoView (`lib/views/auth/store_info_view.dart`)
- 構成: 店舗情報フォーム（名前/住所/カテゴリ/営業時間/タグ/画像など）
- 説明: 店舗登録情報の入力画面

### StoreLocationPickerView (`lib/views/auth/store_location_picker_view.dart`)
- 構成: マップ、現在地/地点選択、確定
- 説明: 店舗位置情報の選択画面

### ApprovalPendingView (`lib/views/auth/approval_pending_view.dart`)
- 構成: 承認待ちメッセージ、削除/戻る導線
- 説明: 店舗承認待ちの案内画面

## ホーム・メインタブ

### HomeView (`lib/views/home_view.dart`)
- 構成: 店舗サマリー、QRスキャン導線、投稿/クーポン作成、各管理画面への導線
- 説明: 店舗のダッシュボード兼ショートカット集約画面

### AnalyticsView (`lib/views/analytics/analytics_view.dart`)
- 構成: 店舗ヘッダー、統計カード、KPIセクション、各推移画面への導線
- 説明: 店舗の分析ダッシュボード

### QRScannerView (`lib/views/qr/qr_scanner_view.dart`)
- 構成: QRスキャナー、手動入力、スキャンガイド
- 説明: 来店ユーザーのQR読み取り画面

### CouponsView (`lib/views/coupons/coupons_view.dart`)
- 構成: タブ（投稿/クーポン）、一覧グリッド、作成導線
- 説明: 投稿/クーポンの統合管理画面

### SettingsView (`lib/views/settings/settings_view.dart`)
- 構成: 店舗情報カード、各設定/管理メニュー
- 説明: 店舗設定・運用の入口画面

## 分析（推移画面）

### TrendBaseView (`lib/views/analytics/trend_base_view.dart`)
- 構成: 期間切替、グラフ、統計カード
- 説明: 各種推移表示の共通ベース画面

### NewCustomerTrendView (`lib/views/analytics/new_customer_trend_view.dart`)
- 構成: 推移グラフ、統計カード
- 説明: 新規顧客の推移表示

### StoreUserTrendView (`lib/views/analytics/store_user_trend_view.dart`)
- 構成: 推移グラフ、統計カード
- 説明: 店舗ユーザー数の推移表示

### AllUserTrendView (`lib/views/analytics/all_user_trend_view.dart`)
- 構成: 推移グラフ、統計カード
- 説明: 全ユーザー推移の表示

### PointIssueTrendView (`lib/views/analytics/point_issue_trend_view.dart`)
- 構成: 推移グラフ、統計カード
- 説明: ポイント発行推移の表示

### TotalPointIssueTrendView (`lib/views/analytics/total_point_issue_trend_view.dart`)
- 構成: 推移グラフ、統計カード
- 説明: 累計ポイント発行推移の表示

### PointUsageUserTrendView (`lib/views/analytics/point_usage_user_trend_view.dart`)
- 構成: 推移グラフ、統計カード
- 説明: ポイント利用ユーザー推移の表示

## ポイント・会計

### PointUsageConfirmationView (`lib/views/points/point_usage_confirmation_view.dart`)
- 構成: ユーザー情報、利用ポイント確認、次画面導線
- 説明: ポイント利用の事前確認画面

### PointUsageInputView (`lib/views/points/point_usage_input_view.dart`)
- 構成: ユーザー/店舗情報、入力パッド、確定
- 説明: ポイント利用入力画面

### PointUsageRequestWaitingView (`lib/views/points/point_usage_request_waiting_view.dart`)
- 構成: 承認待ち状態表示、再送/会計導線
- 説明: ユーザー承認待ち画面

### PointUsageCheckoutPromptView (`lib/views/points/point_usage_checkout_prompt_view.dart`)
- 構成: レジ誘導メッセージ、会計完了ボタン
- 説明: 店舗側レジでの会計促進画面

### StorePaymentView (`lib/views/payment/store_payment_view.dart`)
- 構成: 金額入力、還元率/ユーザー情報、支払い確定
- 説明: 会計金額の入力・ポイント付与画面

### PointsHistoryView (`lib/views/points/points_history_view.dart`)
- 構成: タブ（発行/利用履歴）、取引リスト
- 説明: 店舗のポイント履歴一覧

## クーポン・投稿

### CouponsManageView (`lib/views/coupons/coupons_manage_view.dart`)
- 構成: フィルター、クーポン一覧、作成導線
- 説明: クーポン管理（一覧・編集）画面

### CreateCouponView (`lib/views/coupons/create_coupon_view.dart`)
- 構成: クーポン基本情報/画像/条件入力、作成ボタン
- 説明: 新規クーポン作成画面

### EditCouponView (`lib/views/coupons/edit_coupon_view.dart`)
- 構成: クーポン編集フォーム、画像更新、保存
- 説明: 既存クーポンの編集画面

### StoreCouponDetailView (`lib/views/coupons/coupon_detail_view.dart`)
- 構成: クーポン詳細、期限/特典/注意事項、編集導線
- 説明: クーポン詳細表示画面

### CouponSelectForCheckoutView (`lib/views/coupons/coupon_select_for_checkout_view.dart`)
- 構成: クーポン選択リスト、次工程への導線
- 説明: 会計時に使うクーポンの選択画面

### PostsManageView (`lib/views/posts/posts_manage_view.dart`)
- 構成: フィルター、投稿一覧、作成導線
- 説明: 投稿管理（一覧・編集）画面

### CreatePostView (`lib/views/posts/create_post_view.dart`)
- 構成: 投稿フォーム（タイトル/本文/カテゴリ/画像）、作成
- 説明: 新規投稿作成画面

### EditPostView (`lib/views/posts/edit_post_view.dart`)
- 構成: 投稿編集フォーム、画像追加/削除、保存
- 説明: 既存投稿の編集画面

## 通知・お知らせ

### NotificationsView (`lib/views/notifications/notifications_view.dart`)
- 構成: タブ（お知らせ/通知）、一覧、空/エラー表示
- 説明: 通知とお知らせの一覧画面

### AnnouncementDetailView (`lib/views/notifications/announcement_detail_view.dart`)
- 構成: カテゴリ/優先度、本文、統計情報
- 説明: お知らせ詳細画面

### NotificationDetailView (`lib/views/notifications/notification_detail_view.dart`)
- 構成: 種別バッジ、本文、タグ/画像
- 説明: 通知詳細画面

### CreateAnnouncementView (`lib/views/notifications/create_announcement_view.dart`)
- 構成: タイトル/本文、カテゴリ/優先度、予約投稿
- 説明: お知らせ作成画面

## 店舗・ユーザー管理

### PendingStoresView (`lib/views/stores/pending_stores_view.dart`)
- 構成: 統計カード、店舗一覧、承認/拒否フィルター
- 説明: 未承認店舗の管理画面

### StoreDetailView (`lib/views/stores/store_detail_view.dart`)
- 構成: 店舗詳細、営業時間/統計、承認操作
- 説明: 店舗の審査・詳細確認画面

### StoreSelectionView (`lib/views/settings/store_selection_view.dart`)
- 構成: 店舗一覧、現在店舗の切替
- 説明: 管理対象店舗の切替画面

### StoreActivationSettingsView (`lib/views/settings/store_activation_settings_view.dart`)
- 構成: 承認済み店舗の一覧、稼働ON/OFF
- 説明: 店舗の稼働状態管理画面

### StoreUserDetailView (`lib/views/user/store_user_detail_view.dart`)
- 構成: ユーザー統計、来店/スタンプ/ポイント、押印導線
- 説明: 店舗側のユーザー詳細画面

### PointRequestConfirmationView (`lib/views/user/point_request_confirmation_view.dart`)
- 構成: 押印確認、承認/拒否、結果表示
- 説明: スタンプ押印の確認画面

## バッジ

### BadgeManageView (`lib/views/badges/badge_manage_view.dart`)
- 構成: カテゴリフィルタ、バッジ一覧、作成導線
- 説明: バッジ管理画面

### BadgeCreateView (`lib/views/badges/badge_create_view.dart`)
- 構成: タブ（基本情報/条件）、画像、条件設定
- 説明: バッジ作成画面

### BadgeEditView (`lib/views/badges/badge_edit_view.dart`)
- 構成: タブ（基本情報/条件）、編集フォーム
- 説明: バッジ編集画面

## ランキング・来店

### LeaderboardView (`lib/views/ranking/leaderboard_view.dart`)
- 構成: タイプ/期間フィルタ、ランキング一覧
- 説明: ランキング表示画面

### TodayVisitorsView (`lib/views/visitors/today_visitors_view.dart`)
- 構成: 来店者リスト、時刻/獲得ポイント表示
- 説明: 今日の来店者一覧画面

## フィードバック

### FeedbackSendView (`lib/views/feedback/feedback_send_view.dart`)
- 構成: カテゴリ選択、件名/本文/メール入力、送信
- 説明: フィードバック送信画面

### FeedbackManageView (`lib/views/feedback/feedback_manage_view.dart`)
- 構成: ステータス集計、フィードバック一覧
- 説明: フィードバック管理画面

### FeedbackDetailView (`lib/views/feedback/feedback_detail_view.dart`)
- 構成: 詳細内容、ステータス変更、削除導線
- 説明: フィードバック詳細画面

## 設定・サポート・法務

### StoreProfileEditView (`lib/views/settings/store_profile_edit_view.dart`)
- 構成: 共通ヘッダー、店舗情報フォーム、画像/タグ/営業時間編集
- 説明: 店舗プロフィール編集画面

### StoreLocationEditView (`lib/views/settings/store_location_edit_view.dart`)
- 構成: マップ、位置選択、保存（初回描画後にマップ移動）
- 説明: 店舗位置情報編集画面

### StoreSettingsView (`lib/views/settings/store_settings_view.dart`)
- 構成: 店舗ID/名称/説明、QR保存
- 説明: QR検証に必要な店舗設定画面

### MenuEditView (`lib/views/settings/menu_edit_view.dart`)
- 構成: メニュー一覧、カテゴリ管理、追加/編集導線
- 説明: メニュー管理画面

### MenuItemEditView (`lib/views/settings/menu_item_edit_view.dart`)
- 構成: メニュー編集フォーム、画像、保存
- 説明: メニューアイテム編集画面

### InteriorImagesView (`lib/views/settings/interior_images_view.dart`)
- 構成: 店内画像一覧、追加/並び替え、保存
- 説明: 店内画像管理画面

### StoreIconCropView (`lib/views/settings/store_icon_crop_view.dart`)
- 構成: 画像プレビュー、切り抜き、保存
- 説明: 店舗アイコンのトリミング画面

### NotificationSettingsView (`lib/views/settings/notification_settings_view.dart`)
- 構成: 通知方法/内容/時間帯の設定
- 説明: 通知設定画面

### OwnerSettingsView (`lib/views/settings/owner_settings_view.dart`)
- 構成: 還元率/キャンペーン/メンテナンス等の設定
- 説明: オーナー向けの高度設定画面

### HelpSupportView (`lib/views/settings/help_support_view.dart`)
- 構成: FAQ、問い合わせ導線、アプリ情報
- 説明: ヘルプ・サポート入口画面

### EmailSupportView (`lib/views/settings/email_support_view.dart`)
- 構成: 問い合わせフォーム、送信処理
- 説明: メールサポート画面

### PhoneSupportView (`lib/views/settings/phone_support_view.dart`)
- 構成: 電話番号、営業時間、対応内容
- 説明: 電話サポート案内画面

### LiveChatUserListView (`lib/views/settings/live_chat_user_list_view.dart`)
- 構成: チャットルーム一覧、未読バッジ
- 説明: ライブチャットのユーザー一覧

### LiveChatView (`lib/views/settings/live_chat_user_list_view.dart`)
- 構成: メッセージ一覧、入力欄、送信
- 説明: ライブチャットの会話画面

### AppInfoView (`lib/views/settings/app_info_view.dart`)
- 構成: アプリ情報、開発者情報、法的リンク
- 説明: アプリ情報表示画面

### PrivacyPolicyView (`lib/views/settings/privacy_policy_view.dart`)
- 構成: ポリシー本文、更新日
- 説明: プライバシーポリシー画面

### TermsOfServiceView (`lib/views/settings/terms_of_service_view.dart`)
- 構成: 利用規約本文、更新日
- 説明: 利用規約画面

### SecurityPolicyView (`lib/views/settings/security_policy_view.dart`)
- 構成: セキュリティポリシー本文、更新日
- 説明: セキュリティポリシー画面

### PlanContractView (`lib/views/plans/plan_contract_view.dart`)
- 構成: 現在プラン、プラン一覧、契約情報
- 説明: プラン・契約情報の表示画面

---

# 階層図（画面構成の全体像）

```
アプリ起動
└─ AuthWrapper
   ├─ 未ログイン
   │  └─ LoginView
   │     └─ PasswordResetView
   └─ ログイン済み
      ├─ EmailVerificationPendingView（認証必須時）
      └─ MainNavigationView
         ├─ ホーム（HomeView）
         │  ├─ QRスキャン（QRScannerView）
         │  │  └─ ポイント利用確認（PointUsageConfirmationView）
         │  │     └─ ポイント利用入力（PointUsageInputView）
         │  │        └─ クーポン選択（CouponSelectForCheckoutView）
         │  │           └─ 会計案内（PointUsageCheckoutPromptView）
         │  │              └─ 会計入力（StorePaymentView）
         │  │                 └─ 押印確認（PointRequestConfirmationView）
         │  ├─ 投稿管理（PostsManageView）
         │  │  ├─ 新規投稿（CreatePostView）
         │  │  └─ 投稿編集（EditPostView）
         │  ├─ クーポン管理（CouponsManageView）
         │  │  ├─ 新規作成（CreateCouponView）
         │  │  └─ 編集（EditCouponView）
         │  ├─ クーポン詳細（StoreCouponDetailView）
         │  ├─ ポイント履歴（PointsHistoryView）
         │  └─ お知らせ（NotificationsView）
         │     ├─ お知らせ詳細（AnnouncementDetailView）
         │     └─ 通知詳細（NotificationDetailView）
         │
         ├─ 分析（AnalyticsView）
         │  ├─ 新規顧客推移（NewCustomerTrendView）
         │  ├─ 店舗ユーザー推移（StoreUserTrendView）
         │  ├─ 全ユーザー推移（AllUserTrendView）
         │  ├─ ポイント発行推移（PointIssueTrendView）
         │  ├─ 累計発行推移（TotalPointIssueTrendView）
         │  └─ 利用ユーザー推移（PointUsageUserTrendView）
         │
         ├─ QR（QRScannerView）
         │  └─ 会計・押印フロー（上記と同様）
         │
         ├─ クーポン（CouponsView）
         │  ├─ 投稿タブ（CreatePostView / EditPostView）
         │  └─ クーポンタブ（CreateCouponView / EditCouponView）
         │
         └─ 設定（SettingsView）
            ├─ 店舗プロフィール（StoreProfileEditView）
            │  ├─ アイコン調整（StoreIconCropView）
            │  └─ 位置選択（StoreLocationPickerView）
            ├─ 店舗位置情報（StoreLocationEditView）
            ├─ メニュー編集（MenuEditView）
            │  └─ メニュー項目編集（MenuItemEditView）
            ├─ 店内画像設定（InteriorImagesView）
            ├─ QRコード設定（StoreSettingsView）
            ├─ 通知設定（NotificationSettingsView）
            ├─ プラン・契約情報（PlanContractView）
            ├─ フィードバック送信（FeedbackSendView）
            ├─ フィードバック管理（FeedbackManageView）
            │  └─ 詳細（FeedbackDetailView）
            ├─ バッジ管理（BadgeManageView）
            │  ├─ 作成（BadgeCreateView）
            │  └─ 編集（BadgeEditView）
            ├─ オーナー設定（OwnerSettingsView）
            ├─ 店舗切替（StoreSelectionView）
            ├─ 店舗稼働設定（StoreActivationSettingsView）
            ├─ 店舗審査（PendingStoresView）
            │  └─ 店舗詳細（StoreDetailView）
            ├─ ヘルプ・サポート（HelpSupportView）
            │  ├─ メールサポート（EmailSupportView）
            │  ├─ 電話サポート（PhoneSupportView）
            │  └─ ライブチャット（LiveChatUserListView / LiveChatView）
            ├─ アプリについて（AppInfoView）
            │  ├─ プライバシーポリシー（PrivacyPolicyView）
            │  ├─ 利用規約（TermsOfServiceView）
            │  └─ セキュリティポリシー（SecurityPolicyView）
            └─ お知らせ作成（CreateAnnouncementView）

補助・単独遷移
├─ 店舗登録情報入力（StoreInfoView）
├─ 店舗位置ピッカー（StoreLocationPickerView）
├─ 店舗ユーザー詳細（StoreUserDetailView）
└─ 今日の訪問者（TodayVisitorsView）
```
