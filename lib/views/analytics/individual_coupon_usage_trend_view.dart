import 'package:flutter/material.dart';
import '../../providers/coupon_provider.dart';
import 'trend_base_view.dart';

class IndividualCouponUsageTrendView extends StatelessWidget {
  final String couponId;
  final String couponTitle;

  const IndividualCouponUsageTrendView({
    Key? key,
    required this.couponId,
    required this.couponTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TrendBaseView(
      title: '$couponTitle の利用推移',
      chartTitle: '$couponTitle の利用推移グラフ',
      emptyDetail: 'このクーポンの利用履歴がありません',
      valueKey: 'couponUsageCount',
      trendProvider: individualCouponUsageTrendNotifierProvider,
      onFetch: (ref, storeId, period) {
        return ref.read(individualCouponUsageTrendNotifierProvider.notifier).fetchTrendData(storeId, couponId, period);
      },
      onFetchWithDate: (ref, storeId, period, anchorDate) {
        return ref
            .read(individualCouponUsageTrendNotifierProvider.notifier)
            .fetchTrendData(storeId, couponId, period, anchorDate: anchorDate);
      },
      minAvailableDateResolver: (ref) =>
          ref.read(individualCouponUsageTrendNotifierProvider.notifier).minAvailableDate,
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
