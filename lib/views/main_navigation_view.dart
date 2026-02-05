import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/owner_settings_provider.dart';
import '../widgets/app_update_gate.dart';
import '../widgets/custom_button.dart';
import 'auth/login_view.dart';
import 'auth/email_verification_pending_view.dart';
import 'home_view.dart';
import 'analytics/analytics_view.dart';
import 'qr/qr_scanner_view.dart';
import 'coupons/coupons_view.dart';
import 'settings/settings_view.dart';

class MainNavigationView extends ConsumerStatefulWidget {
  const MainNavigationView({Key? key, this.initialIndex = 0}) : super(key: key);

  final int initialIndex;

  @override
  ConsumerState<MainNavigationView> createState() => _MainNavigationViewState();
}

class _LoweredFabLocation extends FloatingActionButtonLocation {
  final double offset;
  const _LoweredFabLocation(this.offset);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final baseOffset = FloatingActionButtonLocation.centerDocked.getOffset(scaffoldGeometry);
    return Offset(baseOffset.dx, baseOffset.dy + offset);
  }
}

enum _MainTab {
  home,
  analytics,
  qr,
  coupons,
  settings,
}

class _MainNavigationViewState extends ConsumerState<MainNavigationView> {
  late int _currentIndex;
  int _lastNonQrTabIndex = 0;
  static const double _fabVerticalOffset = 12;

  static const List<_MainTab> _tabs = [
    _MainTab.home,
    _MainTab.analytics,
    _MainTab.qr,
    _MainTab.coupons,
    _MainTab.settings,
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _tabs.length - 1);
    _setCurrentTab(_currentIndex);
    // 初期データ読み込みをフレーム後に実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  // 初期データ読み込み
  Future<void> _loadInitialData() async {
    // 認証状態を確認
    final authState = ref.read(authStateProvider);
    await authState.when(
      data: (user) async {
        if (user != null) {
          // ログイン済みの場合、店舗IDを取得してデータを読み込み
          final storeIdAsync = ref.read(userStoreIdProvider);
          await storeIdAsync.when(
            data: (storeId) async {
              if (storeId != null) {
                await _loadHomeData(user.uid, storeId);
              }
            },
            loading: () async {},
            error: (error, _) async {},
          );
        }
      },
      loading: () async {},
      error: (error, _) async {},
    );
  }

  // 店舗データ読み込み
  Future<void> _loadStoreData(String storeId) async {
    try {
      // 店舗データのプロバイダーを無効化して再読み込み
      ref.invalidate(storeDataProvider(storeId));
      ref.invalidate(storeStatsProvider(storeId));
      ref.invalidate(todayVisitorsProvider(storeId));
    } catch (e) {
      debugPrint('店舗データ読み込みエラー: $e');
    }
  }

  // クーポンデータ読み込み
  Future<void> _loadCouponData(String storeId) async {
    try {
      ref.invalidate(storeCouponsProvider(storeId));
      ref.invalidate(activeCouponsProvider(storeId));
      ref.invalidate(couponUsageStatsProvider(storeId));
    } catch (e) {
      debugPrint('クーポンデータ読み込みエラー: $e');
    }
  }

  List<_MainTab> _bottomTabsFor() {
    return _tabs.where((tab) => tab != _MainTab.qr).toList();
  }

  void _setCurrentTab(int index) {
    _currentIndex = index;
    final tab = _tabs[index];
    if (tab != _MainTab.qr) {
      final bottomIndex = _bottomTabsFor().indexOf(tab);
      if (bottomIndex >= 0) {
        _lastNonQrTabIndex = bottomIndex;
      }
    }
  }

  int _placeholderIndexFor(List<_MainTab> bottomTabs) {
    final analyticsIndex = bottomTabs.indexOf(_MainTab.analytics);
    final couponsIndex = bottomTabs.indexOf(_MainTab.coupons);
    if (analyticsIndex >= 0 && couponsIndex >= 0 && analyticsIndex < couponsIndex) {
      return analyticsIndex + 1;
    }
    return -1;
  }

  int? _bottomTabIndexForVisualIndex(int visualIndex, int placeholderIndex) {
    if (placeholderIndex < 0) {
      return visualIndex;
    }
    if (visualIndex == placeholderIndex) {
      return null;
    }
    return visualIndex > placeholderIndex ? visualIndex - 1 : visualIndex;
  }

  int _visualIndexForBottomTabIndex(int bottomTabIndex, int placeholderIndex) {
    if (placeholderIndex < 0) {
      return bottomTabIndex;
    }
    return bottomTabIndex >= placeholderIndex ? bottomTabIndex + 1 : bottomTabIndex;
  }

  List<BottomNavigationBarItem> _bottomNavItemsWithPlaceholder(
    List<_MainTab> bottomTabs, {
    int settingsBadgeCount = 0,
  }) {
    final items = _navItemsForTabs(
      bottomTabs,
      settingsBadgeCount: settingsBadgeCount,
    );
    final placeholderIndex = _placeholderIndexFor(bottomTabs);
    if (placeholderIndex >= 0 && placeholderIndex <= items.length) {
      items.insert(
        placeholderIndex,
        const BottomNavigationBarItem(
          icon: SizedBox.shrink(),
          label: '',
        ),
      );
    }
    return items;
  }

  // タブ切り替え時のデータ読み込み（BottomNavigationBar用）
  Future<void> _onBottomTabChanged(int bottomIndex) async {
    final bottomTabs = _bottomTabsFor();
    final placeholderIndex = _placeholderIndexFor(bottomTabs);
    final bottomTabIndex = _bottomTabIndexForVisualIndex(bottomIndex, placeholderIndex);
    if (bottomTabIndex == null) {
      return;
    }
    final nextTab = bottomTabs[bottomTabIndex];
    final nextIndex = _tabs.indexOf(nextTab);
    setState(() {
      _setCurrentTab(nextIndex);
    });

    // タブに応じて必要なデータを読み込み
    await _loadTabSpecificData(nextTab);
  }

  // タブ固有のデータ読み込み
  Future<void> _loadTabSpecificData(_MainTab tab) async {
    final authState = ref.read(authStateProvider);
    await authState.when(
      data: (user) async {
        if (user == null) return;

        // 店舗IDを取得
        final storeIdAsync = ref.read(userStoreIdProvider);
        await storeIdAsync.when(
          data: (storeId) async {
            if (storeId == null) return;

            switch (tab) {
              case _MainTab.home:
                await _loadHomeData(user.uid, storeId);
                break;
              case _MainTab.analytics:
                await _loadAnalyticsData(storeId);
                break;
              case _MainTab.qr:
                // QRスキャナーは特別なデータ読み込み不要
                break;
              case _MainTab.coupons:
                await _loadCouponManagementData(storeId);
                break;
              case _MainTab.settings:
                await _loadSettingsData(storeId);
                break;
            }
          },
          loading: () async {},
          error: (error, _) async {},
        );
      },
      loading: () async {},
      error: (error, _) async {},
    );
  }

  // 各タブのデータ読み込みメソッド
  Future<void> _loadHomeData(String userId, String storeId) async {
    // ホーム画面のデータ読み込み
    await _loadStoreData(storeId);
    await _loadCouponData(storeId);
  }

  Future<void> _loadAnalyticsData(String storeId) async {
    // 分析画面のデータ読み込み
    await _loadStoreData(storeId);
    // 必要に応じて追加の分析データプロバイダーを無効化
  }

  Future<void> _loadCouponManagementData(String storeId) async {
    // クーポン管理画面のデータ読み込み
    await _loadCouponData(storeId);
  }

  Future<void> _loadSettingsData(String storeId) async {
    // 設定画面のデータ読み込み
    ref.invalidate(storeDataProvider(storeId));
  }

  void _onQrFabPressed() {
    _loadTabSpecificData(_MainTab.qr);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRScannerView(),
      ),
    );
  }

  int _safeBottomIndex(List<_MainTab> bottomTabs) {
    if (bottomTabs.isEmpty) {
      return 0;
    }
    return _lastNonQrTabIndex.clamp(0, bottomTabs.length - 1);
  }

  Widget _pageForTab(_MainTab tab) {
    switch (tab) {
      case _MainTab.home:
        return const HomeView();
      case _MainTab.analytics:
        return const AnalyticsView();
      case _MainTab.qr:
        return const QRScannerView();
      case _MainTab.coupons:
        return const CouponsView();
      case _MainTab.settings:
        return const SettingsView();
    }
  }

  List<BottomNavigationBarItem> _navItemsForTabs(
    List<_MainTab> tabs, {
    int settingsBadgeCount = 0,
  }) {
    return tabs.map((tab) {
      switch (tab) {
        case _MainTab.home:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          );
        case _MainTab.analytics:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '分析',
          );
        case _MainTab.qr:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'QRスキャン',
          );
        case _MainTab.coupons:
          return const BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'クーポン',
          );
        case _MainTab.settings:
          return BottomNavigationBarItem(
            icon: _buildSettingsNavIcon(settingsBadgeCount),
            label: '設定',
          );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppUpdateGate(
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final maintenanceGate = _buildMaintenanceGate(context, ref);
    if (maintenanceGate != null) {
      return maintenanceGate;
    }

    final emailOtpRequired = ref.watch(emailOtpRequiredProvider);
    return emailOtpRequired.when(
      data: (isRequired) {
        if (isRequired) {
          return const EmailVerificationPendingView(
            autoSendOnLoad: false,
            isLoginFlow: true,
          );
        }

        final isOwnerAsync = ref.watch(userIsOwnerProvider);
        return isOwnerAsync.when(
          data: (isOwner) {
            if (!isOwner) {
              return _buildUserAccountLockedView(context);
            }
            return _buildOwnerMainContent();
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
              child: Text(
                'ユーザー情報の取得に失敗しました: ${error.toString()}',
                textAlign: TextAlign.center,
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
      error: (_, __) => const EmailVerificationPendingView(
        autoSendOnLoad: false,
        isLoginFlow: true,
      ),
    );
  }

  Widget _buildOwnerMainContent() {
    final storeIdAsync = ref.watch(userStoreIdProvider);

    return storeIdAsync.when(
      data: (storeId) {
        if (storeId == null) {
          return _buildMainScaffold();
        }

        final storeDataAsync = ref.watch(storeDataProvider(storeId));
        return storeDataAsync.when(
          data: (storeData) {
            final isApproved = (storeData?['isApproved'] as bool?) ?? true;
            if (!isApproved) {
              return _buildApprovalPendingView(context, storeId);
            }
            return _buildMainScaffold();
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
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(storeDataProvider(storeId));
                    },
                    child: const Text('再試行'),
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
          child: Text(
            'ユーザー情報の取得に失敗しました: ${error.toString()}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAccountLockedView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Icon(
                Icons.lock_outline,
                size: 72,
                color: Color(0xFFFF6B35),
              ),
              const SizedBox(height: 16),
              const Text(
                '店舗用アカウントが必要です',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'このアカウントはユーザー用アカウントとして作成されています。\n店舗用アカウントでログインしてください。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              CustomButton(
                text: 'ログアウト',
                onPressed: () async {
                  final authService = ref.read(authServiceProvider);
                  try {
                    await authService.signOut();
                  } catch (e) {
                    debugPrint('ログアウトエラー: $e');
                  }
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginView()),
                    (route) => false,
                  );
                },
                backgroundColor: const Color(0xFFFF6B35),
                textColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildMainScaffold() {
    final safeIndex = _currentIndex.clamp(0, _tabs.length - 1);
    if (safeIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _setCurrentTab(safeIndex);
        });
      });
    }

    final bottomTabs = _bottomTabsFor();
    final placeholderIndex = _placeholderIndexFor(bottomTabs);
    final currentTab = _tabs[safeIndex];
    final bottomIndex = bottomTabs.isEmpty
        ? 0
        : currentTab == _MainTab.qr
            ? _visualIndexForBottomTabIndex(_safeBottomIndex(bottomTabs), placeholderIndex)
            : _visualIndexForBottomTabIndex(
                bottomTabs.indexOf(currentTab).clamp(0, bottomTabs.length - 1),
                placeholderIndex,
              );

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('stores').snapshots(),
      builder: (context, snapshot) {
        final pendingCount = _pendingStoresCount(snapshot.data?.docs);
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.data == null) {
              final items = _bottomNavItemsWithPlaceholder(
                bottomTabs,
                settingsBadgeCount: pendingCount,
              );
              return _buildBottomScaffold(
                currentTab: currentTab,
                bottomIndex: bottomIndex,
                items: items,
              );
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('messages')
                  .where('senderRole', isEqualTo: 'user')
                  .where('readByOwnerAt', isNull: true)
                  .snapshots(),
              builder: (context, unreadSnapshot) {
                final unreadCount = unreadSnapshot.hasError
                    ? 0
                    : (unreadSnapshot.data?.docs.length ?? 0);
                final totalBadgeCount = pendingCount + unreadCount;
                final items = _bottomNavItemsWithPlaceholder(
                  bottomTabs,
                  settingsBadgeCount: totalBadgeCount,
                );
                return _buildBottomScaffold(
                  currentTab: currentTab,
                  bottomIndex: bottomIndex,
                  items: items,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomScaffold({
    required _MainTab currentTab,
    required int bottomIndex,
    required List<BottomNavigationBarItem> items,
  }) {
    return Scaffold(
      body: _pageForTab(currentTab),
      floatingActionButton: FloatingActionButton(
        onPressed: _onQrFabPressed,
        backgroundColor: const Color(0xFFFF6B35),
        shape: const CircleBorder(),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.white),
            SizedBox(height: 2),
            Text(
              '読み取り',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: const _LoweredFabLocation(_fabVerticalOffset),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: bottomIndex,
        onTap: _onBottomTabChanged,
        selectedItemColor: const Color(0xFFFF6B35),
        unselectedItemColor: Colors.grey,
        iconSize: 24,
        selectedLabelStyle: const TextStyle(fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: items,
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

  Widget _buildSettingsNavIcon(int badgeCount) {
    if (badgeCount <= 0) {
      return const Icon(Icons.settings);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.settings),
        Positioned(
          right: -4,
          top: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalPendingView(BuildContext context, String storeId) {
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
              onPressed: _showReturnToTopDialog,
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

  void _showReturnToTopDialog() {
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
                await _deleteAccountAndReturn();
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

  Future<void> _deleteAccountAndReturn() async {
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
    final deleted = await _deleteAccountWithReauth(authService);
    if (!mounted) return;

    if (deleted == true) {
      Navigator.of(context).pop();
      try {
        await authService.signOut();
      } catch (e) {
        debugPrint('ログアウトエラー: $e');
      }
      if (!mounted) return;
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
    final password = await _promptPassword();
    if (!mounted || password == null || password.isEmpty) {
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
      if (mounted) Navigator.of(context).pop();
      await _showErrorDialog('再認証に必要なメールアドレスを取得できませんでした');
      return;
    }

    try {
      await authService.reauthenticateWithPassword(email: email, password: password);
      await authService.deleteAccount();
      if (mounted) Navigator.of(context).pop();
      try {
        await authService.signOut();
      } catch (e) {
        debugPrint('ログアウトエラー: $e');
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.of(context).pop();
      await _showErrorDialog('再認証に失敗しました: ${e.message ?? e.code}');
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      await _showErrorDialog('再認証に失敗しました: ${e.toString()}');
    }
  }

  Future<bool?> _deleteAccountWithReauth(AuthService authService) async {
    try {
      await authService.deleteAccount();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        await _showErrorDialog('アカウント削除に失敗しました: ${e.message ?? e.code}');
        return false;
      }
      return null;
    } catch (e) {
      await _showErrorDialog('アカウント削除に失敗しました: ${e.toString()}');
      return false;
    }
  }

  Future<String?> _promptPassword() async {
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

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
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
}
