import 'package:flutter/material.dart';
import '../../providers/store_provider.dart';
import 'trend_base_view.dart';

class AllLoginTrendView extends StatelessWidget {
  const AllLoginTrendView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TrendBaseView(
      title: '全ユーザーログイン数推移',
      chartTitle: 'ログイン数推移グラフ',
      emptyDetail: 'ログインの記録がありません',
      valueKey: 'loginCount',
      trendProvider: allLoginTrendNotifierProvider,
      onFetch: (ref, storeId, period) {
        return ref.read(allLoginTrendNotifierProvider.notifier).fetchTrendData(storeId, period);
      },
      onFetchWithDate: (ref, storeId, period, anchorDate) {
        return ref
            .read(allLoginTrendNotifierProvider.notifier)
            .fetchTrendData(storeId, period, anchorDate: anchorDate);
      },
      minAvailableDateResolver: (ref) =>
          ref.read(allLoginTrendNotifierProvider.notifier).minAvailableDate,
      periodOptions: const [
        TrendPeriodOption('日', 'day'),
      ],
      initialPeriod: 'day',
      statsConfig: const TrendStatsConfig(
        totalLabel: '月間総ログイン数',
        maxLabel: '最大ログイン数',
        minLabel: '最小ログイン数',
        avgLabel: '平均ログイン数',
        totalIcon: Icons.login,
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
          TrendStatItem(type: TrendStatType.max, label: '最大ログイン数', icon: Icons.trending_up, color: Color(0xFFFF6B35)),
          TrendStatItem(type: TrendStatType.min, label: '最小ログイン数', icon: Icons.trending_down, color: Color(0xFFFF6B35)),
          TrendStatItem(type: TrendStatType.avg, label: '平均ログイン数', icon: Icons.analytics, color: Color(0xFFFF6B35)),
        ],
      ),
    );
  }
}
