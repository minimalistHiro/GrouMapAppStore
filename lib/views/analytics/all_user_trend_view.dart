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
      onFetchWithDate: (ref, storeId, period, anchorDate) {
        return ref
            .read(allUserTrendNotifierProvider.notifier)
            .fetchTrendData(storeId, period, anchorDate: anchorDate);
      },
      minAvailableDateResolver: (ref) =>
          ref.read(allUserTrendNotifierProvider.notifier).minAvailableDate,
      periodOptions: const [
        TrendPeriodOption('日', 'day'),
        TrendPeriodOption('月', 'month'),
        TrendPeriodOption('年', 'year'),
      ],
      initialPeriod: 'day',
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
        totalColor: Color(0xFFFF6B35),
        maxColor: Color(0xFFFF6B35),
        minColor: Color(0xFFFF6B35),
        avgColor: Color(0xFFFF6B35),
      ),
      primaryChartStats: const ChartStatsConfig(
        items: [
          TrendStatItem(type: TrendStatType.max, label: '最大ユーザー数', icon: Icons.trending_up, color: Color(0xFFFF6B35)),
          TrendStatItem(type: TrendStatType.min, label: '最小ユーザー数', icon: Icons.trending_down, color: Color(0xFFFF6B35)),
          TrendStatItem(type: TrendStatType.avg, label: '平均ユーザー数', icon: Icons.analytics, color: Color(0xFFFF6B35)),
        ],
      ),
      secondaryChartStats: const ChartStatsConfig(
        items: [
          TrendStatItem(type: TrendStatType.lastValue, label: '総ユーザー数', icon: Icons.group, color: Color(0xFFFF6B35)),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> _buildCumulativeTrendData(List<Map<String, dynamic>> trendData) {
    // fetchTrendData で事前計算済みの cumulativeUsers をそのまま使用
    return trendData.map((data) {
      final value = data['cumulativeUsers'];
      int cumulative;
      if (value is int) {
        cumulative = value;
      } else if (value is double) {
        cumulative = value.round();
      } else if (value is num) {
        cumulative = value.toInt();
      } else {
        cumulative = 0;
      }
      return {
        'date': data['date'],
        'cumulativeUsers': cumulative,
      };
    }).toList();
  }
}
