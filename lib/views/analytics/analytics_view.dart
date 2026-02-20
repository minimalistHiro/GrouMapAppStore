import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/coupon_provider.dart';
import 'store_user_trend_view.dart';
import 'new_customer_trend_view.dart';
import 'coupon_usage_trend_view.dart';
import 'all_user_trend_view.dart';
import 'all_login_trend_view.dart';
import 'recommendation_trend_view.dart';
import '../../providers/referral_kpi_provider.dart';
import '../ranking/leaderboard_view.dart';
import 'individual_coupon_usage_trend_view.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 店舗情報ヘッダー
            _buildStoreHeader(ref),
            
            const SizedBox(height: 24),
            
            // 月間ポイント統計カード
            _buildMonthlyPointStatsCard(ref),
            
            const SizedBox(height: 24),
            
            // データセクション
            _buildDataSection(ref),

            const SizedBox(height: 24),

            // 全来店記録 円グラフセクション
            _buildAllVisitPieChartsSection(ref),

            const SizedBox(height: 24),

            // 週間統計セクション
            _buildWeeklyStatsSection(ref),
            
            const SizedBox(height: 24),
            
            // 月間統計セクション
            _buildMonthlyStatsSection(ref),
            
            const SizedBox(height: 24),

            // 送客KPIセクション
            _buildReferralKpiSection(ref),
            
            const SizedBox(height: 24),
            
            // クーポン使用統計セクション
            _buildCouponStatsSection(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final storeIdAsync = ref.watch(userStoreIdProvider);
        
        return storeIdAsync.when(
          data: (storeId) {
            if (storeId == null) {
              return _buildStoreHeaderPlaceholder();
            }
            
            final storeDataAsync = ref.watch(storeDataProvider(storeId));
            
            return storeDataAsync.when(
              data: (storeData) {
                if (storeData == null) {
                  return _buildStoreHeaderPlaceholder();
                }
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
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
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: storeData['iconImageUrl'] != null
                              ? Image.network(
                                  storeData['iconImageUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.white.withOpacity(0.3),
                                    child: const Icon(
                                      Icons.store,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.white.withOpacity(0.3),
                                  child: const Icon(
                                    Icons.store,
                                    size: 30,
                                    color: Colors.white,
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
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${storeData['category'] ?? 'カテゴリ未設定'} • 分析ダッシュボード',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 分析アイコン
                      const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                );
              },
              loading: () => _buildStoreHeaderPlaceholder(),
              error: (error, stackTrace) => _buildStoreHeaderPlaceholder(),
            );
          },
          loading: () => _buildStoreHeaderPlaceholder(),
          error: (error, stackTrace) => _buildStoreHeaderPlaceholder(),
        );
      },
    );
  }

  Widget _buildStoreHeaderPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white.withOpacity(0.3),
            ),
            child: const Icon(
              Icons.store,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '分析ダッシュボード',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '店舗の統計情報を確認',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.analytics,
            color: Colors.white,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyPointStatsCard(WidgetRef ref) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month, color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                '月間来店者数',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer(
            builder: (context, ref, child) {
              final storeIdAsync = ref.watch(userStoreIdProvider);
              
              return storeIdAsync.when(
                data: (storeId) {
                  if (storeId == null) {
                    return _buildStatsGridPlaceholder(count: 2);
                  }
                  
                  final monthlyStatsAsync = ref.watch(monthlyStatsProvider(storeId));
                  
                  return monthlyStatsAsync.when(
                    data: (monthlyStats) {
                      final visitorCount = monthlyStats['visitorCount'] ?? 0;
                      final newCustomers = monthlyStats['newCustomers'] ?? 0;
                      final monthlyCouponUsageAsync =
                          ref.watch(monthlyCouponUsageCountProvider(storeId));

                      return monthlyCouponUsageAsync.when(
                        data: (monthlyCouponUsage) {
                          return _buildMonthlyStatsRow([
                            {
                              'label': '月間来店者数',
                              'value': '$visitorCount',
                              'icon': Icons.people,
                              'color': const Color(0xFFFF6B35),
                            },
                            {
                              'label': '月間新規顧客数',
                              'value': '$newCustomers',
                              'icon': Icons.person_add,
                              'color': const Color(0xFFFF6B35),
                            },
                            {
                              'label': '月間クーポン使用者数',
                              'value': '$monthlyCouponUsage',
                              'icon': Icons.local_offer,
                              'color': const Color(0xFFFF6B35),
                            },
                          ]);
                        },
                        loading: () {
                          return _buildMonthlyStatsRow([
                            {
                              'label': '月間来店者数',
                              'value': '$visitorCount',
                              'icon': Icons.people,
                              'color': const Color(0xFFFF6B35),
                            },
                            {
                              'label': '月間新規顧客数',
                              'value': '$newCustomers',
                              'icon': Icons.person_add,
                              'color': const Color(0xFFFF6B35),
                            },
                            {
                              'label': '月間クーポン使用者数',
                              'value': '...',
                              'icon': Icons.local_offer,
                              'color': const Color(0xFFFF6B35),
                            },
                          ]);
                        },
                        error: (_, __) {
                          return _buildMonthlyStatsRow([
                            {
                              'label': '月間来店者数',
                              'value': '$visitorCount',
                              'icon': Icons.people,
                              'color': const Color(0xFFFF6B35),
                            },
                            {
                              'label': '月間新規顧客数',
                              'value': '$newCustomers',
                              'icon': Icons.person_add,
                              'color': const Color(0xFFFF6B35),
                            },
                            {
                              'label': '月間クーポン使用者数',
                              'value': '0',
                              'icon': Icons.local_offer,
                              'color': const Color(0xFFFF6B35),
                            },
                          ]);
                        },
                      );
                    },
                    loading: () => _buildMonthlyStatsRow([
                      {
                        'label': '月間来店者数',
                        'value': '...',
                        'icon': Icons.people,
                        'color': const Color(0xFFFF6B35),
                      },
                      {
                        'label': '月間新規顧客数',
                        'value': '...',
                        'icon': Icons.person_add,
                        'color': const Color(0xFFFF6B35),
                      },
                      {
                        'label': '月間クーポン使用者数',
                        'value': '...',
                        'icon': Icons.local_offer,
                        'color': const Color(0xFFFF6B35),
                      },
                    ]),
                    error: (error, stackTrace) => _buildMonthlyStatsRow([
                      {
                        'label': '月間来店者数',
                        'value': '0',
                        'icon': Icons.people,
                        'color': const Color(0xFFFF6B35),
                      },
                      {
                        'label': '月間新規顧客数',
                        'value': '0',
                        'icon': Icons.person_add,
                        'color': const Color(0xFFFF6B35),
                      },
                      {
                        'label': '月間クーポン使用者数',
                        'value': '0',
                        'icon': Icons.local_offer,
                        'color': const Color(0xFFFF6B35),
                      },
                    ]),
                  );
                },
                loading: () => _buildMonthlyStatsRow([
                  {
                    'label': '月間来店者数',
                    'value': '...',
                    'icon': Icons.people,
                    'color': const Color(0xFFFF6B35),
                  },
                  {
                    'label': '月間新規顧客数',
                    'value': '...',
                    'icon': Icons.person_add,
                    'color': const Color(0xFFFF6B35),
                  },
                  {
                    'label': '月間クーポン使用者数',
                    'value': '...',
                    'icon': Icons.local_offer,
                    'color': const Color(0xFFFF6B35),
                  },
                ]),
                error: (error, stackTrace) => _buildMonthlyStatsRow([
                  {
                    'label': '月間来店者数',
                    'value': '0',
                    'icon': Icons.people,
                    'color': const Color(0xFFFF6B35),
                  },
                  {
                    'label': '月間新規顧客数',
                    'value': '0',
                    'icon': Icons.person_add,
                    'color': const Color(0xFFFF6B35),
                  },
                  {
                    'label': '月間クーポン使用者数',
                    'value': '0',
                    'icon': Icons.local_offer,
                    'color': const Color(0xFFFF6B35),
                  },
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    List<Map<String, dynamic>> stats, {
    double childAspectRatio = 1.5,
    int crossAxisCount = 2,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final subValue = stat['subValue'] as String?;
        final description = stat['description'] as String?;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stat['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: stat['color'] as Color,
                ),
              ),
              if (subValue != null && subValue.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGridPlaceholder({
    int count = 4,
    int crossAxisCount = 2,
    double childAspectRatio = 1.5,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyStatsRow(List<Map<String, dynamic>> stats) {
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

  Widget _buildDataSection(WidgetRef ref) {
    final isAdminOwner = ref.watch(userIsAdminOwnerProvider).maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );

    final dataItems = [
      {
        'title': '店舗利用者推移',
        'icon': Icons.people_outline,
      },
      {
        'title': '新規顧客推移',
        'icon': Icons.person_add_outlined,
      },
      {
        'title': 'クーポン利用者推移',
        'icon': Icons.local_offer_outlined,
      },
      {
        'title': 'おすすめ表示推移',
        'icon': Icons.recommend_outlined,
      },
      if (isAdminOwner)
        {
          'title': '全ユーザー数推移',
          'icon': Icons.group_outlined,
        },
      if (isAdminOwner)
        {
          'title': '全ユーザーログイン数推移',
          'icon': Icons.login_outlined,
        },
      if (isAdminOwner)
        {
          'title': 'ランキング',
          'icon': Icons.emoji_events_outlined,
        },
    ];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                'データ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dataItems.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = dataItems[index];

              return InkWell(
                onTap: () {
                  // 各データ項目の詳細画面への遷移処理
                  _navigateToDataDetail(context, item['title'] as String);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: const Color(0xFFFF6B35),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.black38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToDataDetail(BuildContext context, String dataType) {
    // 各データタイプに応じた詳細画面への遷移処理
    switch (dataType) {
      case '店舗利用者推移':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StoreUserTrendView(),
          ),
        );
        break;
      case '新規顧客推移':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NewCustomerTrendView(),
          ),
        );
        break;
      case 'クーポン利用者推移':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CouponUsageTrendView(),
          ),
        );
        break;
      case 'おすすめ表示推移':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RecommendationTrendView(),
          ),
        );
        break;
      case '全ユーザー数推移':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AllUserTrendView(),
          ),
        );
        break;
      case '全ユーザーログイン数推移':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AllLoginTrendView(),
          ),
        );
        break;
      case 'ランキング':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LeaderboardView(),
          ),
        );
        break;
      default:
        // その他のデータタイプはスナックバーで確認メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$dataType の詳細画面を開きます'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFFFF6B35),
          ),
        );
    }
  }

  Widget _buildAllVisitPieChartsSection(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final storeIdAsync = ref.watch(userStoreIdProvider);

        return storeIdAsync.when(
          data: (storeId) {
            if (storeId == null) {
              return _buildPieChartPlaceholder();
            }

            final pieDataAsync = ref.watch(allVisitPieChartDataProvider(storeId));

            return pieDataAsync.when(
              data: (pieData) {
                final genderData = (pieData['gender'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num).toInt()),
                ) ?? <String, int>{};
                final ageGroupData = (pieData['ageGroup'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num).toInt()),
                ) ?? <String, int>{};
                final newRepeatData = (pieData['newRepeat'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num).toInt()),
                ) ?? <String, int>{};

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pie_chart, color: Color(0xFFFF6B35), size: 24),
                          SizedBox(width: 8),
                          Text(
                            '全来店記録',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 男女比
                      _buildPieChartWithLegend(
                        title: '男女比',
                        data: genderData,
                        colorMap: const {
                          '男性': Color(0xFF4FC3F7),
                          '女性': Color(0xFFFF8A80),
                          'その他': Color(0xFFCE93D8),
                          '未設定': Color(0xFFBDBDBD),
                        },
                      ),
                      const SizedBox(height: 24),

                      // 年齢別
                      _buildPieChartWithLegend(
                        title: '年齢別',
                        data: ageGroupData,
                        colorMap: const {
                          '~19': Color(0xFF81D4FA),
                          '20s': Color(0xFF4FC3F7),
                          '30s': Color(0xFF29B6F6),
                          '40s': Color(0xFFFFB74D),
                          '50s': Color(0xFFFF8A65),
                          '60+': Color(0xFFEF5350),
                          '未設定': Color(0xFFBDBDBD),
                        },
                      ),
                      const SizedBox(height: 24),

                      // 新規/リピート
                      _buildPieChartWithLegend(
                        title: '新規 / リピート',
                        data: newRepeatData,
                        colorMap: const {
                          '新規': Color(0xFF66BB6A),
                          'リピート': Color(0xFFFF6B35),
                        },
                      ),
                    ],
                  ),
                );
              },
              loading: () => _buildPieChartPlaceholder(),
              error: (error, stackTrace) {
                debugPrint('Error loading pie chart data: $error');
                return _buildPieChartPlaceholder();
              },
            );
          },
          loading: () => _buildPieChartPlaceholder(),
          error: (error, stackTrace) => _buildPieChartPlaceholder(),
        );
      },
    );
  }

  Widget _buildPieChartWithLegend({
    required String title,
    required Map<String, int> data,
    required Map<String, Color> colorMap,
  }) {
    final total = data.values.fold<int>(0, (sum, v) => sum + v);
    final filteredData = Map.fromEntries(
      data.entries.where((e) => e.value > 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (total == 0)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'データがありません',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          )
        else
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: filteredData.entries.map((entry) {
                      final percentage = (entry.value / total * 100);
                      return PieChartSectionData(
                        color: colorMap[entry.key] ?? Colors.grey,
                        value: entry.value.toDouble(),
                        title: '${percentage.round()}%',
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        radius: 45,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredData.entries.map((entry) {
                    final percentage = (entry.value / total * 100);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colorMap[entry.key] ?? Colors.grey,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.value}件 (${percentage.round()}%)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPieChartPlaceholder() {
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                '全来店記録',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              '読込中...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsSection(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final storeIdAsync = ref.watch(userStoreIdProvider);
        
        return storeIdAsync.when(
          data: (storeId) {
            if (storeId == null) {
              return _buildStatsSection(
                title: '週間統計',
                icon: Icons.calendar_view_week,
                stats: [
                  {'label': '新規来店者数', 'value': '-', 'change': '-'},
                  {'label': '週間来店者数', 'value': '-', 'change': '-'},
                  {'label': 'リピート率', 'value': '-', 'change': '-'},
                ],
              );
            }

            final weeklyStatsAsync = ref.watch(weeklyStatsProvider(storeId));

            return weeklyStatsAsync.when(
              data: (weeklyStats) {
                final newCustomers = weeklyStats['newCustomers'] ?? 0;
                final visitorCount = weeklyStats['visitorCount'] ?? 0;
                final repeatRate = weeklyStats['repeatRate'] ?? 0;

                return _buildStatsSection(
                  title: '週間統計',
                  icon: Icons.calendar_view_week,
                  stats: [
                    {'label': '新規来店者数', 'value': '$newCustomers', 'change': '-'},
                    {'label': '週間来店者数', 'value': '$visitorCount', 'change': '-'},
                    {'label': 'リピート率', 'value': '$repeatRate%', 'change': '-'},
                  ],
                );
              },
              loading: () => _buildStatsSection(
                title: '週間統計',
                icon: Icons.calendar_view_week,
                stats: [
                  {'label': '新規来店者数', 'value': '読込中...', 'change': '-'},
                  {'label': '週間来店者数', 'value': '読込中...', 'change': '-'},
                  {'label': 'リピート率', 'value': '読込中...', 'change': '-'},
                ],
              ),
              error: (error, stackTrace) {
                debugPrint('Error loading weekly stats: $error');
                return _buildStatsSection(
                  title: '週間統計',
                  icon: Icons.calendar_view_week,
                  stats: [
                    {'label': '新規来店者数', 'value': '-', 'change': '-'},
                    {'label': '週間来店者数', 'value': '-', 'change': '-'},
                    {'label': 'リピート率', 'value': '-', 'change': '-'},
                  ],
                );
              },
            );
          },
          loading: () => _buildStatsSection(
            title: '週間統計',
            icon: Icons.calendar_view_week,
            stats: [
              {'label': '新規来店者数', 'value': '読込中...', 'change': '-'},
              {'label': '週間来店者数', 'value': '読込中...', 'change': '-'},
              {'label': 'リピート率', 'value': '読込中...', 'change': '-'},
            ],
          ),
          error: (error, stackTrace) => _buildStatsSection(
            title: '週間統計',
            icon: Icons.calendar_view_week,
            stats: [
              {'label': '新規来店者数', 'value': '-', 'change': '-'},
              {'label': '週間来店者数', 'value': '-', 'change': '-'},
              {'label': 'リピート率', 'value': '-', 'change': '-'},
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyStatsSection(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final storeIdAsync = ref.watch(userStoreIdProvider);
        
        return storeIdAsync.when(
          data: (storeId) {
            if (storeId == null) {
              return _buildStatsSection(
                title: '月間統計',
                icon: Icons.calendar_month,
                stats: [
                  {'label': '新規来店者数', 'value': '-', 'change': '-'},
                  {'label': '月間来店者数', 'value': '-', 'change': '-'},
                  {'label': 'リピート率', 'value': '-', 'change': '-'},
                ],
              );
            }

            final monthlyStatsAsync = ref.watch(monthlyStatsProvider(storeId));

            return monthlyStatsAsync.when(
              data: (monthlyStats) {
                final newCustomers = monthlyStats['newCustomers'] ?? 0;
                final visitorCount = monthlyStats['visitorCount'] ?? 0;
                final repeatRate = monthlyStats['repeatRate'] ?? 0;

                return _buildStatsSection(
                  title: '月間統計',
                  icon: Icons.calendar_month,
                  stats: [
                    {'label': '新規来店者数', 'value': '$newCustomers', 'change': '-'},
                    {'label': '月間来店者数', 'value': '$visitorCount', 'change': '-'},
                    {'label': 'リピート率', 'value': '$repeatRate%', 'change': '-'},
                  ],
                );
              },
              loading: () => _buildStatsSection(
                title: '月間統計',
                icon: Icons.calendar_month,
                stats: [
                  {'label': '新規来店者数', 'value': '読込中...', 'change': '-'},
                  {'label': '月間来店者数', 'value': '読込中...', 'change': '-'},
                  {'label': 'リピート率', 'value': '読込中...', 'change': '-'},
                ],
              ),
              error: (error, stackTrace) {
                debugPrint('Error loading monthly stats: $error');
                return _buildStatsSection(
                  title: '月間統計',
                  icon: Icons.calendar_month,
                  stats: [
                    {'label': '新規来店者数', 'value': '-', 'change': '-'},
                    {'label': '月間来店者数', 'value': '-', 'change': '-'},
                    {'label': 'リピート率', 'value': '-', 'change': '-'},
                  ],
                );
              },
            );
          },
          loading: () => _buildStatsSection(
            title: '月間統計',
            icon: Icons.calendar_month,
            stats: [
              {'label': '新規来店者数', 'value': '読込中...', 'change': '-'},
              {'label': '月間来店者数', 'value': '読込中...', 'change': '-'},
              {'label': 'リピート率', 'value': '読込中...', 'change': '-'},
            ],
          ),
          error: (error, stackTrace) => _buildStatsSection(
            title: '月間統計',
            icon: Icons.calendar_month,
            stats: [
              {'label': '新規来店者数', 'value': '-', 'change': '-'},
              {'label': '月間来店者数', 'value': '-', 'change': '-'},
              {'label': 'リピート率', 'value': '-', 'change': '-'},
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouponStatsSection(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final storeIdAsync = ref.watch(userStoreIdProvider);
        return storeIdAsync.when(
          data: (storeId) {
            if (storeId == null) {
              return _buildCouponStatsPlaceholder();
            }
            final couponsAsync = ref.watch(storeCouponsProvider(storeId));
            return couponsAsync.when(
              data: (coupons) {
                return _buildCouponStatsCard(context, coupons);
              },
              loading: () => _buildCouponStatsPlaceholder(),
              error: (error, stackTrace) => _buildCouponStatsPlaceholder(),
            );
          },
          loading: () => _buildCouponStatsPlaceholder(),
          error: (error, stackTrace) => _buildCouponStatsPlaceholder(),
        );
      },
    );
  }

  Widget _buildCouponStatsPlaceholder() {
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                'クーポン統計',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              '読込中...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponStatsCard(BuildContext context, List<Map<String, dynamic>> coupons) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_offer, color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                'クーポン統計',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (coupons.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '発行中のクーポンはありません',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            )
          else
            ...coupons.map((coupon) {
              final couponId = coupon['id'] as String?;
              final title = coupon['title'] ?? 'タイトルなし';
              final usedCount = coupon['usedCount'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: couponId != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IndividualCouponUsageTrendView(
                                couponId: couponId,
                                couponTitle: title,
                              ),
                            ),
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFCC80),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number,
                          color: Color(0xFFFF6B35),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '合計使用者数: $usedCount人',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReferralKpiSection(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final storeIdAsync = ref.watch(userStoreIdProvider);
        return storeIdAsync.when(
          data: (storeId) {
            if (storeId == null) {
              return _buildReferralKpiCard(
                stats: _buildReferralKpiPlaceholderStats(),
                sourceRanking: const [],
                targetRanking: const [],
              );
            }
            final kpiAsync = ref.watch(referralKpiProvider(storeId));
            final sourceRankingAsync = ref.watch(referralSourceRankingProvider(storeId));
            final targetRankingAsync = ref.watch(referralTargetRankingProvider(storeId));

            return kpiAsync.when(
              data: (kpiData) {
                final stats = _buildReferralKpiStats(kpiData);
                final sourceRanking = sourceRankingAsync.value ?? const [];
                final targetRanking = targetRankingAsync.value ?? const [];
                return _buildReferralKpiCard(
                  stats: stats,
                  sourceRanking: sourceRanking,
                  targetRanking: targetRanking,
                );
              },
              loading: () => _buildReferralKpiCard(
                stats: _buildReferralKpiPlaceholderStats(),
                sourceRanking: const [],
                targetRanking: const [],
              ),
              error: (error, stackTrace) => _buildReferralKpiCard(
                stats: _buildReferralKpiPlaceholderStats(),
                sourceRanking: const [],
                targetRanking: const [],
              ),
            );
          },
          loading: () => _buildReferralKpiCard(
            stats: _buildReferralKpiPlaceholderStats(),
            sourceRanking: const [],
            targetRanking: const [],
          ),
          error: (error, stackTrace) => _buildReferralKpiCard(
            stats: _buildReferralKpiPlaceholderStats(),
            sourceRanking: const [],
            targetRanking: const [],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _buildReferralKpiStats(Map<String, dynamic> data) {
    final firstVisits = data['firstVisits'] as int? ?? 0;
    final impressions = data['impressions'] as int? ?? 0;
    final visitRate = data['visitRate'] as double? ?? 0.0;
    final balance = data['balance'] as int? ?? 0;

    final visitRateText = impressions > 0 ? '${visitRate.toStringAsFixed(1)}%' : '-';
    final balanceText = balance >= 0 ? '+$balance' : '$balance';

    return [
      {
        'label': '送客起点初回来店数',
        'value': '$firstVisits',
        'description': 'おすすめ経由で初めて来店した人数',
        'icon': Icons.person_add_alt,
        'color': const Color(0xFFFF6B35),
      },
      {
        'label': '送客起点初回来店率',
        'value': visitRateText,
        'subValue': '表示 $impressions 件',
        'description': 'おすすめ表示→初回来店の転換率',
        'icon': Icons.trending_up,
        'color': const Color(0xFFFF6B35),
      },
      {
        'label': '送客バランス',
        'value': balanceText,
        'subValue': '受け-送客',
        'description': '受入来店数と送出来店数の差',
        'icon': Icons.compare_arrows,
        'color': const Color(0xFFFF6B35),
      },
    ];
  }

  List<Map<String, dynamic>> _buildReferralKpiPlaceholderStats() {
    return [
      {
        'label': '送客起点初回来店数',
        'value': '-',
        'description': 'おすすめ経由で初めて来店した人数',
        'icon': Icons.person_add_alt,
        'color': Colors.grey,
      },
      {
        'label': '送客起点初回来店率',
        'value': '-',
        'subValue': '表示→来店',
        'description': 'おすすめ表示→初回来店の転換率',
        'icon': Icons.trending_up,
        'color': Colors.grey,
      },
      {
        'label': '送客バランス',
        'value': '-',
        'subValue': '受け/送客差',
        'description': '受入来店数と送出来店数の差',
        'icon': Icons.compare_arrows,
        'color': Colors.grey,
      },
    ];
  }

  Widget _buildReferralKpiCard({
    required List<Map<String, dynamic>> stats,
    required List<Map<String, String>> sourceRanking,
    required List<Map<String, String>> targetRanking,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route, color: Color(0xFFFF6B35), size: 24),
              const SizedBox(width: 8),
              const Text(
                '送客KPI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  '直近30日間',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(stats, childAspectRatio: 1.2),
          const SizedBox(height: 16),
          _buildRankingSection(
            title: '送客元ランキング',
            icon: Icons.call_made,
            items: sourceRanking,
          ),
          const SizedBox(height: 12),
          _buildRankingSection(
            title: '送客先ランキング',
            icon: Icons.call_received,
            items: targetRanking,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingSection({
    required String title,
    required IconData icon,
    required List<Map<String, String>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFFF6B35), size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Text(
              'データ準備中',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['label'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        item['value'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsSection({
    required String title,
    required IconData icon,
    required List<Map<String, String>> stats,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFF6B35), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...stats.map((stat) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    stat['label']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      stat['value']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      stat['change']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _refreshData(WidgetRef ref) {
    final storeIdAsync = ref.read(userStoreIdProvider);
    storeIdAsync.when(
      data: (storeId) {
        if (storeId != null) {
          ref.invalidate(storeDataProvider(storeId));
          ref.invalidate(todayVisitorsProvider(storeId));
          ref.invalidate(storeStatsProvider(storeId));
          ref.invalidate(weeklyStatsProvider(storeId));
          ref.invalidate(monthlyStatsProvider(storeId));
          ref.invalidate(allVisitPieChartDataProvider(storeId));
        }
      },
      loading: () {},
      error: (error, stackTrace) {},
    );
  }
}
