import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/coupon_provider.dart';
import 'home_view.dart';
import 'analytics/analytics_view.dart';
import 'qr/qr_scanner_view.dart';
import 'coupons/coupon_management_view.dart';
import 'settings/settings_view.dart';

class MainNavigationView extends ConsumerStatefulWidget {
  const MainNavigationView({Key? key}) : super(key: key);

  @override
  ConsumerState<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends ConsumerState<MainNavigationView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeView(),
    const AnalyticsView(),
    const QRScannerView(),
    const CouponManagementView(),
    const SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
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
          // ログイン済みの場合、必要なデータを並列で読み込み
          await Future.wait([
            _loadStoreData(user.uid),
            _loadCouponData(user.uid),
          ]);
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

        switch (tabIndex) {
          case 0: // ホーム
            await _loadHomeData(user.uid);
            break;
          case 1: // 分析
            await _loadAnalyticsData(user.uid);
            break;
          case 2: // QRスキャナー
            // QRスキャナーは特別なデータ読み込み不要
            break;
          case 3: // クーポン管理
            await _loadCouponManagementData(user.uid);
            break;
          case 4: // 設定
            await _loadSettingsData(user.uid);
            break;
        }
      },
      loading: () async {},
      error: (error, _) async {},
    );
  }

  // 各タブのデータ読み込みメソッド
  Future<void> _loadHomeData(String storeId) async {
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

  @override
  Widget build(BuildContext context) {
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
}
