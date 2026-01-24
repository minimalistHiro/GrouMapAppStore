import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/coupon_provider.dart';
import '../providers/owner_settings_provider.dart';
import '../services/push_notification_service.dart';
import '../widgets/app_update_gate.dart';
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

class _MainNavigationViewState extends ConsumerState<MainNavigationView> {
  late int _currentIndex;

  final List<Widget> _pages = [
    const HomeView(),
    const AnalyticsView(),
    const QRScannerView(),
    const CouponsView(),
    const SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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

  // タブ切り替え時のデータ読み込み
  Future<void> _onTabChanged(int index) async {
    setState(() {
      _currentIndex = index;
    });

    // タブに応じて必要なデータを読み込み
    await _loadTabSpecificData(index);
  }

  // タブ固有のデータ読み込み
  Future<void> _loadTabSpecificData(int tabIndex) async {
    final authState = ref.read(authStateProvider);
    await authState.when(
      data: (user) async {
        if (user == null) return;

        // 店舗IDを取得
        final storeIdAsync = ref.read(userStoreIdProvider);
        await storeIdAsync.when(
          data: (storeId) async {
            if (storeId == null) return;

            switch (tabIndex) {
              case 0: // ホーム
                await _loadHomeData(user.uid, storeId);
                break;
              case 1: // 分析
                await _loadAnalyticsData(storeId);
                break;
              case 2: // QRスキャナー
                // QRスキャナーは特別なデータ読み込み不要
                break;
              case 3: // クーポン管理
                await _loadCouponManagementData(storeId);
                break;
              case 4: // 設定
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
    final pushService = ref.read(pushNotificationServiceProvider);
    await pushService.syncForUser(userId);
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
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        selectedItemColor: const Color(0xFFFF6B35),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '分析',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'QRスキャン',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'クーポン',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalPendingView(BuildContext context, String storeId) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(storeDataProvider(storeId));
                },
                child: const Text('リロード'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
