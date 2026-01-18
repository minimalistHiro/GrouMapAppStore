import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_provider.dart';
import 'trend_base_view.dart';

class TotalPointIssueTrendView extends StatelessWidget {
  const TotalPointIssueTrendView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TrendBaseView(
      title: '全ポイント発行数推移',
      chartTitle: '全ポイント発行数推移グラフ',
      emptyDetail: 'ポイント付与の履歴がありません',
      valueKey: 'totalPointsIssued',
      trendProvider: totalPointIssueTrendNotifierProvider,
      onFetch: (ref, storeId, period) {
        return ref.read(totalPointIssueTrendNotifierProvider.notifier).fetchTrendData(storeId, period);
      },
      statsConfig: const TrendStatsConfig(
        totalLabel: '総ポイント発行数',
        maxLabel: '最大ポイント発行数',
        minLabel: '最小ポイント発行数',
        avgLabel: '平均ポイント発行数',
        totalIcon: Icons.monetization_on,
        maxIcon: Icons.trending_up,
        minIcon: Icons.trending_down,
        avgIcon: Icons.analytics,
        totalColor: Colors.blue,
        maxColor: Colors.green,
        minColor: Colors.orange,
        avgColor: Colors.purple,
      ),
      valueFormatter: _formatNumber,
    );
  }

  static String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
