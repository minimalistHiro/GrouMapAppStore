import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_provider.dart';
import 'trend_base_view.dart';

class AllUserTrendView extends StatelessWidget {
  const AllUserTrendView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TrendBaseView(
      title: '全ユーザー推移',
      chartTitle: '新規ユーザー数推移グラフ',
      emptyDetail: 'ユーザー登録の履歴がありません',
      valueKey: 'totalUsers',
      trendProvider: allUserTrendNotifierProvider,
      onFetch: (ref, storeId, period) {
        return ref.read(allUserTrendNotifierProvider.notifier).fetchTrendData(storeId, period);
      },
      secondaryChartTitle: '累計ユーザー数推移グラフ',
      secondaryEmptyDetail: 'ユーザー登録の履歴がありません',
      secondaryValueKey: 'cumulativeUsers',
      secondaryDataBuilder: _buildCumulativeTrendData,
      statsConfig: const TrendStatsConfig(
        totalLabel: '総ユーザー数',
        maxLabel: '最大ユーザー数',
        minLabel: '最小ユーザー数',
        avgLabel: '平均ユーザー数',
        totalIcon: Icons.group,
        maxIcon: Icons.trending_up,
        minIcon: Icons.trending_down,
        avgIcon: Icons.analytics,
        totalColor: Colors.blue,
        maxColor: Colors.green,
        minColor: Colors.orange,
        avgColor: Colors.purple,
      ),
    );
  }

  static List<Map<String, dynamic>> _buildCumulativeTrendData(List<Map<String, dynamic>> trendData) {
    final sortedData = List<Map<String, dynamic>>.from(trendData)
      ..sort((a, b) => (a['date'] as String? ?? '').compareTo(b['date'] as String? ?? ''));

    var cumulative = 0;
    return sortedData.map((data) {
      final value = data['totalUsers'];
      int count;
      if (value is int) {
        count = value;
      } else if (value is double) {
        count = value.round();
      } else if (value is num) {
        count = value.toInt();
      } else {
        count = 0;
      }
      cumulative += count;
      return {
        'date': data['date'],
        'cumulativeUsers': cumulative,
      };
    }).toList();
  }
}
