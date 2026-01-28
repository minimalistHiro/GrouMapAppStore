import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_provider.dart';
import 'trend_base_view.dart';

class PointUsageUserTrendView extends StatelessWidget {
  const PointUsageUserTrendView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TrendBaseView(
      title: 'ポイント利用者推移',
      chartTitle: 'ポイント利用者推移グラフ',
      emptyDetail: 'ポイント利用の履歴がありません',
      valueKey: 'pointUsageUsers',
      trendProvider: pointUsageUserTrendNotifierProvider,
      onFetch: (ref, storeId, period) {
        return ref.read(pointUsageUserTrendNotifierProvider.notifier).fetchTrendData(storeId, period);
      },
      onFetchWithDate: (ref, storeId, period, anchorDate) {
        return ref
            .read(pointUsageUserTrendNotifierProvider.notifier)
            .fetchTrendData(storeId, period, anchorDate: anchorDate);
      },
      minAvailableDateResolver: (ref) =>
          ref.read(pointUsageUserTrendNotifierProvider.notifier).minAvailableDate,
      periodOptions: const [
        TrendPeriodOption('日', 'day'),
        TrendPeriodOption('月', 'month'),
        TrendPeriodOption('年', 'year'),
      ],
      initialPeriod: 'day',
      statsConfig: const TrendStatsConfig(
        totalLabel: '総ポイント利用者数',
        maxLabel: '最大ポイント利用者数',
        minLabel: '最小ポイント利用者数',
        avgLabel: '平均ポイント利用者数',
        totalIcon: Icons.people,
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
}
