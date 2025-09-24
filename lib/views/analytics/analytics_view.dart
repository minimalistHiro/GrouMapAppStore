import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import 'store_user_trend_view.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // データを再読み込み
              _refreshData(ref);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 店舗情報ヘッダー
            _buildStoreHeader(ref),
            
            const SizedBox(height: 24),
            
            // 今日の統計カード
            _buildTodayStatsCard(ref),
            
            const SizedBox(height: 24),
            
            // データセクション
            _buildDataSection(ref),
            
            const SizedBox(height: 24),
            
            // 週間統計セクション
            _buildWeeklyStatsSection(ref),
            
            const SizedBox(height: 24),
            
            // 月間統計セクション
            _buildMonthlyStatsSection(ref),
            
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

  Widget _buildTodayStatsCard(WidgetRef ref) {
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
              Icon(Icons.today, color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                '今日の統計',
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
                    return _buildStatsGridPlaceholder();
                  }
                  
                  final todayVisitorsAsync = ref.watch(todayVisitorsProvider(storeId));
                  
                  return todayVisitorsAsync.when(
                    data: (visitorData) {
                      // visitorDataから来店者数を取得
                      int visitorCount = 0;
                      if (visitorData.isNotEmpty) {
                        visitorCount = visitorData.first['count'] ?? 0;
                      }
                      
                      return _buildStatsGrid([
                        {'label': '今日の来店者', 'value': visitorCount.toString(), 'icon': Icons.people, 'color': Colors.blue},
                        {'label': '今日の新規顧客', 'value': '${(visitorCount * 0.2).round()}', 'icon': Icons.person_add, 'color': Colors.purple},
                        {'label': '今日の配布ポイント', 'value': '${visitorCount * 10}', 'icon': Icons.monetization_on, 'color': Colors.green},
                        {'label': '今日のクーポン使用', 'value': '${(visitorCount * 0.3).round()}', 'icon': Icons.local_offer, 'color': Colors.orange},
                      ]);
                    },
                    loading: () => _buildStatsGridPlaceholder(),
                    error: (error, stackTrace) => _buildStatsGridPlaceholder(),
                  );
                },
                loading: () => _buildStatsGridPlaceholder(),
                error: (error, stackTrace) => _buildStatsGridPlaceholder(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(List<Map<String, dynamic>> stats) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
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
              const SizedBox(height: 8),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: stat['color'] as Color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGridPlaceholder() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: 4,
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

  Widget _buildDataSection(WidgetRef ref) {
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final dataItems = [
                {
                  'title': '店舗利用者推移',
                  'icon': Icons.people_outline,
                  'color': Colors.blue,
                },
                {
                  'title': '新規顧客推移',
                  'icon': Icons.person_add_outlined,
                  'color': Colors.purple,
                },
                {
                  'title': 'ポイント発行推移',
                  'icon': Icons.monetization_on_outlined,
                  'color': Colors.green,
                },
                {
                  'title': 'ポイント利用推移',
                  'icon': Icons.shopping_cart_outlined,
                  'color': Colors.orange,
                },
                {
                  'title': '全ユーザー数推移',
                  'icon': Icons.group_outlined,
                  'color': Colors.teal,
                },
                {
                  'title': '全ポイント発行数推移',
                  'icon': Icons.trending_up_outlined,
                  'color': Colors.red,
                },
              ];
              
              final item = dataItems[index];
              
              return GestureDetector(
                onTap: () {
                  // 各データ項目の詳細画面への遷移処理
                  _navigateToDataDetail(context, item['title'] as String);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (item['color'] as Color).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item['color'] as Color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildWeeklyStatsSection(WidgetRef ref) {
    return _buildStatsSection(
      title: '週間統計',
      icon: Icons.calendar_view_week,
      stats: [
        {'label': '週間来店者数', 'value': '1,247', 'change': '+12%'},
        {'label': '週間売上', 'value': '¥1,496,400', 'change': '+8%'},
        {'label': '平均客単価', 'value': '¥1,200', 'change': '+5%'},
        {'label': 'リピート率', 'value': '68%', 'change': '+3%'},
      ],
    );
  }

  Widget _buildMonthlyStatsSection(WidgetRef ref) {
    return _buildStatsSection(
      title: '月間統計',
      icon: Icons.calendar_month,
      stats: [
        {'label': '月間来店者数', 'value': '4,892', 'change': '+15%'},
        {'label': '月間売上', 'value': '¥5,870,400', 'change': '+18%'},
        {'label': '新規顧客数', 'value': '978', 'change': '+22%'},
        {'label': '顧客満足度', 'value': '4.7/5.0', 'change': '+0.2'},
      ],
    );
  }

  Widget _buildCouponStatsSection(WidgetRef ref) {
    return _buildStatsSection(
      title: 'クーポン統計',
      icon: Icons.local_offer,
      stats: [
        {'label': '発行済みクーポン', 'value': '1,234', 'change': '+25%'},
        {'label': '使用済みクーポン', 'value': '987', 'change': '+18%'},
        {'label': '使用率', 'value': '80%', 'change': '+5%'},
        {'label': '平均割引額', 'value': '¥180', 'change': '+2%'},
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
        }
      },
      loading: () {},
      error: (error, stackTrace) {},
    );
  }
}
