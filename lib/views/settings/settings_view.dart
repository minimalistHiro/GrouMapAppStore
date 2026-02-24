import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/settings_badge_provider.dart';
import '../../widgets/custom_button.dart';
import 'store_profile_edit_view.dart';
import 'store_location_edit_view.dart';
import 'menu_edit_view.dart';
import 'store_selection_view.dart';
import 'store_activation_settings_view.dart';
import 'schedule_calendar_view.dart';
import 'help_support_view.dart';
import 'app_info_view.dart';
import 'notification_settings_view.dart';
import 'interior_images_view.dart';
import 'payment_methods_settings_view.dart';
import 'owner_settings_view.dart';
import 'live_chat_user_list_view.dart';
import 'instagram_sync_view.dart';
import 'password_change_view.dart';
import 'email_change_view.dart';
import '../plans/plan_contract_view.dart';
import '../auth/login_view.dart';
import '../stores/pending_stores_view.dart';
import '../feedback/feedback_send_view.dart';
import '../feedback/feedback_manage_view.dart';
import '../notifications/announcement_manage_view.dart';
import '../news/news_manage_view.dart';
import '../account_deletion/account_deletion_requests_list_view.dart';
import '../../providers/account_deletion_provider.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({Key? key}) : super(key: key);

  Color _getDefaultStoreColor(String category) {
    switch (category) {
      case 'レストラン':
        return Colors.red;
      case 'カフェ':
        return Colors.brown;
      case 'ショップ':
        return Colors.blue;
      case '美容院':
        return Colors.pink;
      case '薬局':
        return Colors.green;
      case 'コンビニ':
        return Colors.orange;
      case 'スーパー':
        return Colors.lightGreen;
      case '書店':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getDefaultStoreIcon(String category) {
    switch (category) {
      case 'レストラン':
        return Icons.restaurant;
      case 'カフェ':
        return Icons.local_cafe;
      case 'ショップ':
        return Icons.shopping_bag;
      case '美容院':
        return Icons.content_cut;
      case '薬局':
        return Icons.local_pharmacy;
      case 'コンビニ':
        return Icons.store;
      case 'スーパー':
        return Icons.shopping_cart;
      case '書店':
        return Icons.menu_book;
      default:
        return Icons.store;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminOwnerAsync = ref.watch(userIsAdminOwnerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 店舗情報カード
            _buildStoreInfoCard(ref),
            
            const SizedBox(height: 24),
            
            // 店舗情報セクション
            _buildSection(
              title: '店舗情報',
              children: [
                _buildSettingsItem(
                  icon: Icons.store,
                  title: '店舗プロフィール',
                  subtitle: '店舗の基本情報を編集',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StoreProfileEditView(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.location_on,
                  title: '店舗位置情報',
                  subtitle: '店舗の位置情報を設定',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StoreLocationEditView(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.restaurant_menu,
                  title: 'メニューを編集',
                  subtitle: '店舗のメニューを管理',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MenuEditView(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.photo_library,
                  title: '店内画像設定',
                  subtitle: '店内画像を最大5枚まで登録',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const InteriorImagesView(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.payment,
                  title: '店舗決済方法設定',
                  subtitle: '利用可能な決済方法を設定',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const PaymentMethodsSettingsView(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.calendar_month,
                  title: '営業カレンダー',
                  subtitle: '臨時休業・営業時間変更を管理',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ScheduleCalendarView(),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // アプリ設定セクション
            _buildSection(
              title: 'アプリ設定',
              children: [
                _buildSettingsItem(
                  icon: Icons.camera_alt,
                  title: 'Instagram同期',
                  subtitle: 'Instagram投稿の同期設定',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const InstagramSyncView(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.notifications,
                  title: '通知設定',
                  subtitle: 'プッシュ通知の設定',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsView(),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // アカウントセクション
            _buildSection(
              title: 'アカウント',
              children: [
                if (FirebaseAuth.instance.currentUser?.providerData
                        .any((p) => p.providerId == 'password') ??
                    false)
                  _buildSettingsItem(
                    icon: Icons.lock,
                    title: 'パスワード変更',
                    subtitle: 'ログインパスワードを変更',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PasswordChangeView(),
                        ),
                      );
                    },
                  ),
                if (FirebaseAuth.instance.currentUser?.providerData
                        .any((p) => p.providerId == 'password') ??
                    false)
                  _buildSettingsItem(
                    icon: Icons.email,
                    title: 'メールアドレス変更',
                    subtitle: 'ログインメールアドレスを変更',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EmailChangeView(),
                        ),
                      );
                    },
                  ),
                _buildSettingsItem(
                  icon: Icons.business,
                  title: 'プラン・契約情報',
                  subtitle: 'プランと契約内容を確認',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PlanContractView(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.feedback,
                  title: 'フィードバック送信',
                  subtitle: 'ご意見・不具合の報告',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FeedbackSendView(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.help_outline,
                  title: 'ヘルプ・サポート',
                  subtitle: 'よくある質問やサポート',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportView(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.info_outline,
                  title: 'アプリについて',
                  subtitle: 'バージョン情報など',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AppInfoView(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // オーナー管理セクション（管理者オーナーのみ表示）
            isAdminOwnerAsync.when(
              data: (isAdminOwner) {
                if (!isAdminOwner) {
                  return const SizedBox.shrink();
                }
                return _buildSection(
                  title: 'オーナー管理',
                  children: [
                    _buildSettingsItem(
                      icon: Icons.manage_accounts,
                      title: 'フィードバック管理',
                      subtitle: 'お客様のフィードバックを確認',
                      badgeCount: ref.watch(pendingFeedbackCountProvider).maybeWhen(
                        data: (v) => v,
                        orElse: () => 0,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FeedbackManageView(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.chat,
                      title: 'ライブチャット',
                      subtitle: 'ユーザーからの問い合わせを確認',
                      badgeCount: ref.watch(unreadLiveChatCountProvider).maybeWhen(
                        data: (v) => v,
                        orElse: () => 0,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LiveChatUserListView(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.settings,
                      title: '店舗設定',
                      subtitle: '店舗の有効・無効を切り替え',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const StoreActivationSettingsView(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.storefront,
                      title: '未承認店舗一覧',
                      subtitle: '未承認の店舗申請を確認',
                      badgeCount: ref.watch(pendingStoresCountProvider).maybeWhen(
                        data: (v) => v,
                        orElse: () => 0,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PendingStoresView(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.admin_panel_settings,
                      title: 'オーナー設定',
                      subtitle: '紹介キャンペーンの期間を設定',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const OwnerSettingsView(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.newspaper,
                      title: 'ニュース管理',
                      subtitle: 'ニュースの作成・編集・管理',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NewsManageView(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.announcement,
                      title: 'お知らせ管理',
                      subtitle: 'お知らせの作成・編集・管理',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AnnouncementManageView(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.person_remove,
                      title: 'アカウント削除申請',
                      subtitle: '店舗のアカウント削除申請を管理',
                      badgeCount: ref.watch(pendingDeletionRequestsCountProvider).maybeWhen(
                        data: (v) => v,
                        orElse: () => 0,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AccountDeletionRequestsListView(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 40),
            
            // ログアウトボタン
            CustomButton(
              text: 'ログアウト',
              onPressed: () => _showLogoutDialog(context, ref),
              backgroundColor: Colors.red,
              textColor: Colors.white,
            ),
            

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    Widget trailingWidget;
    if (badgeCount > 0) {
      final badgeText = badgeCount > 99 ? '99+' : badgeCount.toString();
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      );
    } else {
      trailingWidget = const Icon(Icons.chevron_right);
    }

    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF6B35)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailingWidget,
      onTap: onTap,
    );
  }

  Widget _buildStoreInfoCard(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final storeIdAsync = ref.watch(userStoreIdProvider);
        
        return storeIdAsync.when(
          data: (storeId) {
            if (storeId == null) {
              return _buildStoreInfoCardPlaceholder();
            }
            
            final storeDataAsync = ref.watch(storeDataProvider(storeId));
            
            return storeDataAsync.when(
              data: (storeData) {
                if (storeData == null) {
                  return _buildStoreInfoCardPlaceholder();
                }
                
                final String category = storeData['category'] ?? 'その他';
                final Color baseColor = _getDefaultStoreColor(category);

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 店舗アイコン
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: baseColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: storeData['iconImageUrl'] != null
                              ? Image.network(
                                  storeData['iconImageUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: baseColor.withOpacity(0.1),
                                    child: Icon(
                                      _getDefaultStoreIcon(category),
                                      size: 40,
                                      color: baseColor,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: baseColor.withOpacity(0.1),
                                  child: Icon(
                                    _getDefaultStoreIcon(category),
                                    size: 40,
                                    color: baseColor,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // 店舗情報
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeData['name'] ?? '店舗名未設定',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              storeData['category'] ?? 'カテゴリ未設定',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    storeData['address'] ?? '住所未設定',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // ボタン群
                      Column(
                        children: [
                          // 編集ボタン
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('店舗情報編集は準備中です')),
                              );
                            },
                            icon: const Icon(
                              Icons.edit,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                          // 店舗切り替えボタン
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const StoreSelectionView(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                '店舗切り替え',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => _buildStoreInfoCardPlaceholder(),
              error: (error, stackTrace) => _buildStoreInfoCardPlaceholder(),
            );
          },
          loading: () => _buildStoreInfoCardPlaceholder(),
          error: (error, stackTrace) => _buildStoreInfoCardPlaceholder(),
        );
      },
    );
  }

  Widget _buildStoreInfoCardPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 店舗アイコン（プレースホルダー）
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: Colors.grey[300],
            ),
            child: const Icon(
              Icons.store,
              size: 40,
              color: Colors.grey,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 店舗情報（プレースホルダー）
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          
          // 編集ボタン（プレースホルダー）
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ログアウトの確認'),
          content: const Text('ログアウトしますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout(context, ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ログアウト'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // ログアウト処理
      await ref.read(authServiceProvider).signOut();

      // ローディングを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // ログイン画面に遷移
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      }
    } catch (e) {
      // ローディングを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // エラー表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログアウトに失敗しました: $e')),
        );
      }
    }
  }

}
