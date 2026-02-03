import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/post_provider.dart';
import '../providers/owner_settings_provider.dart';
import '../widgets/custom_button.dart';
import 'auth/login_view.dart';
import 'posts/create_post_view.dart';
import 'coupons/create_coupon_view.dart';
import 'coupons/coupon_detail_view.dart';
import 'posts/posts_manage_view.dart';
import 'coupons/coupons_manage_view.dart';
import 'points/points_history_view.dart';
import 'notifications/notifications_view.dart';
import 'qr/qr_scanner_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // ログイン済みの場合は店舗IDを取得して店舗ホーム画面を表示
          return _buildStoreHomeContent(context, ref);
        } else {
          // 未ログインの場合はログイン画面を表示
          return const LoginView();
        }
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(authStateProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHomeContent(BuildContext context, WidgetRef ref) {
    final storeIdAsync = ref.watch(userStoreIdProvider);
    final isOwnerAsync = ref.watch(userIsOwnerProvider);
    
    return storeIdAsync.when(
      data: (storeId) {
        if (storeId == null) {
          return isOwnerAsync.when(
            data: (isOwner) {
              if (!isOwner) {
                return Scaffold(
                  backgroundColor: Colors.grey[50],
                  body: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '店舗が設定されていません',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '設定画面から店舗を選択してください',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _buildHomeScaffold(context, ref, 'owner_no_store');
            },
            loading: () => Scaffold(
              backgroundColor: Colors.grey[50],
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => Scaffold(
              backgroundColor: Colors.grey[50],
              body: const Center(
                child: Text('ユーザー情報の取得に失敗しました'),
              ),
            ),
          );
        }

        if (storeId == 'owner_no_store') {
          return _buildHomeScaffold(context, ref, storeId);
        }

        final storeDataAsync = ref.watch(storeDataProvider(storeId));
        return storeDataAsync.when(
          data: (storeData) {
            final isApproved = (storeData?['isApproved'] as bool?) ?? true;
            if (!isApproved) {
              return _buildApprovalPendingView(context, ref, storeId);
            }
            return _buildHomeScaffold(context, ref, storeId);
          },
          loading: () => Scaffold(
            backgroundColor: Colors.grey[50],
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Scaffold(
            backgroundColor: Colors.grey[50],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '店舗情報の取得に失敗しました',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: '再試行',
                    onPressed: () {
                      ref.invalidate(storeDataProvider(storeId));
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                '店舗情報の取得に失敗しました',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: '再試行',
                onPressed: () {
                  ref.invalidate(userStoreIdProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScaffold(BuildContext context, WidgetRef ref, String storeId) {
    final maintenanceGate = _buildMaintenanceGate(context, ref);
    if (maintenanceGate != null) {
      return maintenanceGate;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ヘッダー部分
              _buildHeader(context, ref, storeId),

              _buildMaintenanceNoticeBar(context, ref),
              
              const SizedBox(height: 24),
              
              // QRスキャンボタン
              _buildQRScanButton(context, ref, storeId),
              
              const SizedBox(height: 16),
              
              // 新規作成ボタン
              _buildCreateButtons(context, ref, storeId),
              
              const SizedBox(height: 24),
              
              // 統計カード部分
              _buildStatsCard(context, ref, storeId),
              
              const SizedBox(height: 24),
              
              // その他のコンテンツ
              _buildAdditionalContent(context, ref, storeId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalPendingView(BuildContext context, WidgetRef ref, String storeId) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.hourglass_top,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '店舗の承認待ちです',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '承認が完了するまでしばらくお待ちください。',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      onPressed: () {
                        ref.invalidate(storeDataProvider(storeId));
                      },
                      icon: const Icon(Icons.refresh),
                      color: const Color(0xFFFF6B35),
                      iconSize: 32,
                      tooltip: 'リロード',
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _showReturnToTopDialog(context, ref);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text(
                'トップに戻る',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReturnToTopDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('トップに戻る'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'トップに戻るとアカウントが削除されます。',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• アカウント情報'),
              Text('• 作成した店舗情報'),
              Text('• その他すべての関連データ'),
              SizedBox(height: 12),
              Text(
                'この操作は取り消すことができません。',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '本当にトップに戻りますか？',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccountAndReturn(context, ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('削除して戻る'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccountAndReturn(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('アカウントを削除しています...'),
            ],
          ),
        );
      },
    );

    final authService = ref.read(authServiceProvider);
    final deleted = await _deleteAccountWithReauth(context, authService);
    if (!context.mounted) return;

    if (deleted == true) {
      Navigator.of(context).pop();
      try {
        await authService.signOut();
      } catch (e) {
        debugPrint('ログアウトエラー: $e');
      }
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
      return;
    }

    if (deleted == false) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop();
    final password = await _promptPassword(context);
    if (!context.mounted || password == null || password.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('再認証しています...'),
            ],
          ),
        );
      },
    );

    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      if (context.mounted) Navigator.of(context).pop();
      await _showErrorDialog(context, '再認証に必要なメールアドレスを取得できませんでした');
      return;
    }

    try {
      await authService.reauthenticateWithPassword(email: email, password: password);
      await authService.deleteAccount();
      if (context.mounted) Navigator.of(context).pop();
      try {
        await authService.signOut();
      } catch (e) {
        debugPrint('ログアウトエラー: $e');
      }
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      await _showErrorDialog(context, '再認証に失敗しました: ${e.message ?? e.code}');
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      await _showErrorDialog(context, '再認証に失敗しました: ${e.toString()}');
    }
  }

  Future<bool?> _deleteAccountWithReauth(BuildContext context, AuthService authService) async {
    try {
      await authService.deleteAccount();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        await _showErrorDialog(context, 'アカウント削除に失敗しました: ${e.message ?? e.code}');
        return false;
      }
      return null;
    } catch (e) {
      await _showErrorDialog(context, 'アカウント削除に失敗しました: ${e.toString()}');
      return false;
    }
  }

  Future<String?> _promptPassword(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('再認証が必要です'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'パスワード',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('再認証'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(BuildContext context, String message) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String storeId) {
    final authState = ref.watch(authStateProvider);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // 左側：アプリアイコン&サービス名
          Row(
            children: [
              Image.asset(
                'assets/images/groumap_store_icon.png',
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.store, size: 40, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text(
                'GrouMap Store',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // 右側：お知らせボタン（バッジ付き）
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 28,
                  color: Colors.black87,
                ),
                // 未読通知のバッジ
                authState.when(
                  data: (user) {
                    if (user == null) return const SizedBox.shrink();

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('stores').snapshots(),
                      builder: (context, snapshot) {
                        final pendingCount = _pendingStoresCount(snapshot.data?.docs);
                        if (pendingCount <= 0) {
                          return const SizedBox.shrink();
                        }
                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              pendingCount > 99 ? '99+' : pendingCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsView(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int _pendingStoresCount(List<QueryDocumentSnapshot<Object?>>? docs) {
    if (docs == null) return 0;
    int pendingCount = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final isApproved = data['isApproved'] ?? false;
      final status = data['approvalStatus'] ?? 'pending';
      if (!isApproved && status == 'pending') {
        pendingCount++;
      }
    }
    return pendingCount;
  }

  Widget? _buildMaintenanceGate(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(ownerSettingsProvider).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    if (settings == null) {
      return null;
    }
    final isOwner = ref.watch(userIsOwnerProvider).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    if (isOwner == null || isOwner) {
      return null;
    }
    final startAt = _combineDateTime(
      settings.maintenanceStartDate,
      settings.maintenanceStartTime,
    );
    final endAt = _combineDateTime(
      settings.maintenanceEndDate,
      settings.maintenanceEndTime,
    );
    if (startAt == null || endAt == null) {
      return null;
    }
    final now = DateTime.now();
    if (now.isBefore(startAt) || now.isAfter(endAt)) {
      return null;
    }
    return _buildMaintenanceScreen(context, startAt, endAt);
  }

  Widget _buildMaintenanceScreen(
    BuildContext context,
    DateTime startAt,
    DateTime endAt,
  ) {
    final displayText = _isSameDate(startAt, endAt)
        ? '${_formatDate(startAt)} ${_formatTime(startAt)}〜${_formatTime(endAt)}'
        : '${_formatDateTime(startAt)} 〜 ${_formatDateTime(endAt)}';
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.build_circle_outlined,
                  size: 72,
                  color: Color(0xFF1E88E5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'メンテナンス中',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '現在メンテナンスを実施しています。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  displayText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E88E5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceNoticeBar(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(ownerSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final startDate = settings?.maintenanceStartDate;
        final startTime = settings?.maintenanceStartTime;
        final startAt = _combineDateTime(startDate, startTime);
        if (startAt == null) {
          return const SizedBox.shrink();
        }
        final now = DateTime.now();
        final oneWeekBefore = startAt.subtract(const Duration(days: 7));
        final shouldShow = !now.isBefore(oneWeekBefore) && !now.isAfter(startAt);
        if (!shouldShow) {
          return const SizedBox.shrink();
        }
        final endAt = _combineDateTime(
          settings?.maintenanceEndDate,
          settings?.maintenanceEndTime,
        );
        final displayText = endAt == null
            ? 'メンテナンスのお知らせ: ${_formatDateTime(startAt)}'
            : _isSameDate(startAt, endAt)
                ? 'メンテナンスのお知らせ: ${_formatDate(startAt)} ${_formatTime(startAt)}〜${_formatTime(endAt)}'
                : 'メンテナンスのお知らせ: ${_formatDateTime(startAt)} 〜 ${_formatDateTime(endAt)}';
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQRScanButton(BuildContext context, WidgetRef ref, String storeId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // QRスキャンボタン
          GestureDetector(
            onTap: () {
              // QRスキャン画面に遷移
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QRScannerView(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 115,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 左側：QRコードアイコン
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              size: 35,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 右側：テキスト
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QRスキャン',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'お客様のQRコードをスキャンして\nポイント付与',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'タップしてスキャン',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _combineDateTime(DateTime? date, String? time) {
    if (date == null || time == null || time.trim().isEmpty) {
      return null;
    }
    final parsed = _parseTime(time);
    if (parsed == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year/$month/$day $hour:$minute';
  }

  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isSameDate(DateTime start, DateTime end) {
    return start.year == end.year && start.month == end.month && start.day == end.day;
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref, String storeId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日の統計',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // 店舗統計情報
          Consumer(
            builder: (context, ref, child) {
              final todayStatsAsync = ref.watch(todayStoreStatsProvider(storeId));
              final todayNewCustomersAsync = ref.watch(todayNewCustomersProvider(storeId));
              final todayCouponUsageAsync = ref.watch(todayCouponUsageCountProvider(storeId));
              
              return todayStatsAsync.when(
                data: (stats) {
                  final visitorCount = stats['visitorCount'] ?? 0;
                  
                  return todayNewCustomersAsync.when(
                    data: (newCustomerCount) {
                      return todayCouponUsageAsync.when(
                        data: (couponUsageCount) {
                          return _buildDailyStatsRow([
                            {
                              'label': '今日の来店者',
                              'value': visitorCount.toString(),
                              'icon': Icons.people,
                              'color': const Color(0xFFFF6B35),
                            },
                            {
                              'label': '今日の新規顧客',
                              'value': newCustomerCount.toString(),
                              'icon': Icons.person_add,
                              'color': const Color(0xFFFF6B35),
                            },
                            {
                              'label': '今日のクーポン使用',
                              'value': couponUsageCount.toString(),
                              'icon': Icons.local_offer,
                              'color': const Color(0xFFFF6B35),
                            },
                          ]);
                        },
                        loading: () => _buildDailyStatsRow([
                          {
                            'label': '今日の来店者',
                            'value': visitorCount.toString(),
                            'icon': Icons.people,
                            'color': const Color(0xFFFF6B35),
                          },
                          {
                            'label': '今日の新規顧客',
                            'value': newCustomerCount.toString(),
                            'icon': Icons.person_add,
                            'color': const Color(0xFFFF6B35),
                          },
                          {
                            'label': '今日のクーポン使用',
                            'value': '...',
                            'icon': Icons.local_offer,
                            'color': const Color(0xFFFF6B35),
                          },
                        ]),
                        error: (_, __) => _buildDailyStatsRow([
                          {
                            'label': '今日の来店者',
                            'value': visitorCount.toString(),
                            'icon': Icons.people,
                            'color': const Color(0xFFFF6B35),
                          },
                          {
                            'label': '今日の新規顧客',
                            'value': newCustomerCount.toString(),
                            'icon': Icons.person_add,
                            'color': const Color(0xFFFF6B35),
                          },
                          {
                            'label': '今日のクーポン使用',
                            'value': '0',
                            'icon': Icons.local_offer,
                            'color': const Color(0xFFFF6B35),
                          },
                        ]),
                      );
                    },
                    loading: () => _buildDailyStatsRow([
                      {
                        'label': '今日の来店者',
                        'value': visitorCount.toString(),
                        'icon': Icons.people,
                        'color': const Color(0xFFFF6B35),
                      },
                      {
                        'label': '今日の新規顧客',
                        'value': '...',
                        'icon': Icons.person_add,
                        'color': const Color(0xFFFF6B35),
                      },
                      {
                        'label': '今日のクーポン使用',
                        'value': '...',
                        'icon': Icons.local_offer,
                        'color': const Color(0xFFFF6B35),
                      },
                    ]),
                    error: (_, __) => _buildDailyStatsRow([
                      {
                        'label': '今日の来店者',
                        'value': visitorCount.toString(),
                        'icon': Icons.people,
                        'color': const Color(0xFFFF6B35),
                      },
                      {
                        'label': '今日の新規顧客',
                        'value': '0',
                        'icon': Icons.person_add,
                        'color': const Color(0xFFFF6B35),
                      },
                      {
                        'label': '今日のクーポン使用',
                        'value': '0',
                        'icon': Icons.local_offer,
                        'color': const Color(0xFFFF6B35),
                      },
                    ]),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text(
                  '統計情報の取得に失敗しました',
                  style: TextStyle(color: Colors.red),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatsRow(List<Map<String, dynamic>> stats) {
    final dividerColor = Colors.grey[200];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(stats.length * 2 - 1, (index) {
          if (index.isOdd) {
            return SizedBox(
              height: 72,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: dividerColor,
              ),
            );
          }
          final stat = stats[index ~/ 2];
          final label = stat['label'] as String;
          final value = stat['value'] as String;
          final icon = stat['icon'] as IconData;
          final color = stat['color'] as Color;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAdditionalContent(BuildContext context, WidgetRef ref, String storeId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // 店舗メニューグリッド
          _buildStoreMenuGrid(context, ref, storeId),
          
          const SizedBox(height: 20),
          
          // アクティブクーポンセクション
          _buildActiveCouponsSection(context, ref, storeId),

          const SizedBox(height: 20),

          // 投稿セクション
          _buildPostsSection(context, ref, storeId),
        ],
      ),
    );
  }

  Widget _buildStoreMenuGrid(BuildContext context, WidgetRef ref, String storeId) {
    final menuItems = [
      {'icon': Icons.history, 'label': 'ポイント履歴'},
      {'icon': Icons.local_offer, 'label': 'クーポン管理'},
      {'icon': Icons.article, 'label': '投稿管理'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const iconSize = 32.0;
          const fontSize = 12.0;
          const itemHeight = 80.0;
          const mainAxisSpacing = 8.0;
          const crossAxisSpacing = 8.0;
          final rows = (menuItems.length / 4).ceil();
          final itemWidth = (constraints.maxWidth - (crossAxisSpacing * 3)) / 4;
          final aspectRatio = itemWidth / itemHeight;
          final gridHeight = (itemHeight * rows) + (mainAxisSpacing * (rows - 1));
          final backgroundHeight = gridHeight + 32;

          return SizedBox(
            height: backgroundHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: backgroundHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: aspectRatio,
                      mainAxisSpacing: mainAxisSpacing,
                      crossAxisSpacing: crossAxisSpacing,
                      children: menuItems.map((item) => _buildStoreMenuButton(
                        context,
                        item['label'] as String,
                        item['icon'] as IconData,
                        iconSize: iconSize,
                        fontSize: fontSize,
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateButtons(BuildContext context, WidgetRef ref, String storeId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 新規投稿を作成
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreatePostView(),
                  ),
                );
              },
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.post_add,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '新規投稿を作成',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 新規クーポンを作成
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateCouponView(),
                  ),
                );
              },
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '新規クーポンを作成',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreMenuButton(BuildContext context, String title, IconData icon, {double? iconSize, double? fontSize}) {
    return GestureDetector(
      onTap: () {
        // 各メニュー項目の処理
        if (title == '投稿管理') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PostsManageView(),
            ),
          );
        } else if (title == 'クーポン管理') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CouponsManageView(),
            ),
          );
        } else if (title == 'ポイント履歴') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PointsHistoryView(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title は準備中です')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize ?? 24,
              color: const Color(0xFFFF6B35),
            ),
            SizedBox(height: (iconSize ?? 24) * 0.2),
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize ?? 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCouponsSection(BuildContext context, WidgetRef ref, String storeId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              const Text(
                'アクティブクーポン',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CouponsManageView(),
                    ),
                  );
                },
                child: const Text(
                  '全て見る＞',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 270,
          child: ref.watch(activeCouponsProvider(storeId)).when(
            data: (coupons) {
              if (coupons.isEmpty) {
                return const Center(
                  child: Text(
                    'アクティブなクーポンがありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: coupons.length,
                itemBuilder: (context, index) {
                  final coupon = coupons[index];
                  return _buildCouponCard(context, coupon);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
            error: (error, _) => const Center(
              child: Text(
                'クーポン情報の取得に失敗しました',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsSection(BuildContext context, WidgetRef ref, String storeId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              const Text(
                '投稿',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PostsManageView(),
                    ),
                  );
                },
                child: const Text(
                  '全て見る＞',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: ref.watch(storePostsProvider(storeId)).when(
            data: (posts) {
              if (posts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        '投稿がありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildPostPreviewCard(context, post);
                },
              );
            },
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFFF6B35),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '投稿を読み込み中...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    '投稿の取得に失敗しました',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'データが存在しない可能性があります',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostPreviewCard(BuildContext context, Map<String, dynamic> post) {
    String formatDate() {
      try {
        final timestamp = post['createdAt'];
        if (timestamp == null) return '日付不明';

        final date = timestamp is DateTime ? timestamp : timestamp.toDate();
        final now = DateTime.now();
        final difference = now.difference(date).inDays;

        if (difference == 0) return '今日';
        if (difference == 1) return '昨日';
        if (difference < 7) return '${difference}日前';

        return '${date.month}月${date.day}日';
      } catch (e) {
        return '日付不明';
      }
    }

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿詳細画面は準備中です')),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(top: 7, bottom: 7),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: post['imageUrls'] != null &&
                      (post['imageUrls'] as List).isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        (post['imageUrls'] as List).first,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                post['category'] ?? 'お知らせ',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                post['title'] ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  post['content'] ?? '',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                  ),
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                post['storeName'] ?? '店舗名なし',
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatDate(),
                  style: const TextStyle(
                    fontSize: 7,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, Map<String, dynamic> coupon) {
    // 終了日の表示用フォーマット
    String formatEndDate() {
      final endDate = coupon['validUntil'];
      if (endDate == null) return '期限不明';
      
      try {
        final date = endDate is DateTime ? endDate : endDate.toDate();
        if (coupon['noExpiry'] == true || date.year >= 2100) {
          return '無期限';
        }
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final couponDate = DateTime(date.year, date.month, date.day);
        
        String dateText;
        if (couponDate.isAtSameMomentAs(today)) {
          dateText = '今日';
        } else if (couponDate.isAtSameMomentAs(tomorrow)) {
          dateText = '明日';
        } else {
          dateText = '${date.month}月${date.day}日';
        }
        
        return '$dateText ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}まで';
      } catch (e) {
        return '期限不明';
      }
    }

    // 割引表示用テキスト
    String getDiscountText() {
      final discountType = coupon['discountType'] ?? 'percentage';
      final discountValue = coupon['discountValue'] ?? 0.0;
      
      if (discountType == 'percentage') {
        return '${discountValue.toInt()}%OFF';
      } else if (discountType == 'fixed_amount') {
        return '${discountValue.toInt()}円OFF';
      } else if (discountType == 'fixed_price') {
        return '${discountValue.toInt()}円';
      }
      return '特典あり';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoreCouponDetailView(coupon: coupon),
          ),
        );
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 270,
          width: 170,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // 画像
              Container(
                width: 150,
                height: 150,
                margin: const EdgeInsets.only(top: 7, bottom: 7),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(7),
                ),
                child: coupon['imageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          coupon['imageUrl'],
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey,
                      ),
              ),
              
              // 期限
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  formatEndDate(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 6),
              
              // タイトル
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  coupon['title'] ?? 'タイトルなし',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // 割引情報
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  getDiscountText(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 4),
              const Divider(height: 1),
              
              // 店舗名
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  coupon['storeName'] ?? '店舗名なし',
                  style: const TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ロゴ
            Image.asset(
              'assets/images/groumap_store_icon.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.store, size: 200, color: Colors.orange),
            ),
            
            const SizedBox(height: 32),
            
            // アプリ名
            const Text(
              'GrouMap Store',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // サブタイトル
            const Text(
              '店舗管理アプリにログインして、\nお客様との接点を管理しましょう！',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // 機能説明
            _buildFeatureCard(
              icon: Icons.analytics,
              title: 'リアルタイム統計',
              description: '訪問者数やポイント配布状況をリアルタイムで確認',
            ),
            
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              icon: Icons.local_offer,
              title: 'クーポン管理',
              description: 'クーポンの作成・編集・配布状況を一元管理',
            ),
            
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              icon: Icons.people,
              title: '顧客管理',
              description: 'お客様の訪問履歴やポイント獲得状況を確認',
            ),
            
            const SizedBox(height: 48),
            
            // ログインボタン
            CustomButton(
              text: '店舗ログイン',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ログイン機能は準備中です')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: Colors.orange,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
