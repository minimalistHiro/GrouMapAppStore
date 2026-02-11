import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_provider.dart';
import 'trend_base_view.dart';

class NewCustomerTrendView extends StatelessWidget {
  const NewCustomerTrendView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TrendBaseView(
      title: '新規顧客推移',
      chartTitle: '新規顧客推移グラフ',
      emptyDetail: '新規顧客の履歴がありません',
      valueKey: 'newCustomerCount',
      trendProvider: newCustomerTrendNotifierProvider,
      onFetch: (ref, storeId, period) {
        return ref.read(newCustomerTrendNotifierProvider.notifier).fetchTrendData(storeId, period);
      },
      onFetchWithDate: (ref, storeId, period, anchorDate) {
        return ref
            .read(newCustomerTrendNotifierProvider.notifier)
            .fetchTrendData(storeId, period, anchorDate: anchorDate);
      },
      minAvailableDateResolver: (ref) =>
          ref.read(newCustomerTrendNotifierProvider.notifier).minAvailableDate,
      periodOptions: const [
        TrendPeriodOption('日', 'day'),
        TrendPeriodOption('月', 'month'),
        TrendPeriodOption('年', 'year'),
      ],
      initialPeriod: 'day',
      statsConfig: const TrendStatsConfig(
        totalLabel: '総新規顧客数',
        maxLabel: '最大新規顧客数',
        minLabel: '最小新規顧客数',
        avgLabel: '平均新規顧客数',
        totalIcon: Icons.person_add,
        maxIcon: Icons.trending_up,
        minIcon: Icons.trending_down,
        avgIcon: Icons.analytics,
        totalColor: Color(0xFFFF6B35),
        maxColor: Color(0xFFFF6B35),
        minColor: Color(0xFFFF6B35),
        avgColor: Color(0xFFFF6B35),
      ),
    );
  }
}
