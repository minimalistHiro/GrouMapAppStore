import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/coupon_provider.dart';
import 'trend_base_view.dart';

class CouponUsageTrendView extends StatelessWidget {
  const CouponUsageTrendView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TrendBaseView(
      title: 'クーポン利用者推移',
      chartTitle: 'クーポン利用者推移グラフ',
      emptyDetail: 'クーポン利用の履歴がありません',
      valueKey: 'couponUsageCount',
      trendProvider: couponUsageTrendNotifierProvider,
      onFetch: (ref, storeId, period) {
        return ref.read(couponUsageTrendNotifierProvider.notifier).fetchTrendData(storeId, period);
      },
      onFetchWithDate: (ref, storeId, period, anchorDate) {
        return ref
            .read(couponUsageTrendNotifierProvider.notifier)
            .fetchTrendData(storeId, period, anchorDate: anchorDate);
      },
      minAvailableDateResolver: (ref) =>
          ref.read(couponUsageTrendNotifierProvider.notifier).minAvailableDate,
      periodOptions: const [
        TrendPeriodOption('日', 'day'),
        TrendPeriodOption('月', 'month'),
        TrendPeriodOption('年', 'year'),
      ],
      initialPeriod: 'day',
      statsConfig: const TrendStatsConfig(
        totalLabel: '総クーポン利用数',
        maxLabel: '最大クーポン利用数',
        minLabel: '最小クーポン利用数',
        avgLabel: '平均クーポン利用数',
        totalIcon: Icons.local_offer,
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
