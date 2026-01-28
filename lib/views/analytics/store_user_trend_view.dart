import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_provider.dart';
import 'trend_base_view.dart';

class StoreUserTrendView extends StatelessWidget {
  const StoreUserTrendView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TrendBaseView(
      title: '店舗利用者推移',
      chartTitle: '利用者推移グラフ',
      emptyDetail: '利用者データがありません',
      valueKey: 'userCount',
      trendProvider: storeUserTrendNotifierProvider,
      onFetch: (ref, storeId, period) {
        return ref.read(storeUserTrendNotifierProvider.notifier).fetchTrendData(storeId, period);
      },
      onFetchWithDate: (ref, storeId, period, anchorDate) {
        return ref
            .read(storeUserTrendNotifierProvider.notifier)
            .fetchTrendData(storeId, period, anchorDate: anchorDate);
      },
      minAvailableDateResolver: (ref) =>
          ref.read(storeUserTrendNotifierProvider.notifier).minAvailableDate,
      periodOptions: const [
        TrendPeriodOption('日', 'day'),
        TrendPeriodOption('月', 'month'),
        TrendPeriodOption('年', 'year'),
      ],
      initialPeriod: 'day',
      statsConfig: const TrendStatsConfig(
        totalLabel: '総利用者数',
        maxLabel: '最大利用者数',
        minLabel: '最小利用者数',
        avgLabel: '平均利用者数',
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
