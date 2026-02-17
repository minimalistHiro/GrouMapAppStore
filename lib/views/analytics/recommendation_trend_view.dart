import 'package:flutter/material.dart';
import '../../providers/recommendation_provider.dart';
import 'trend_base_view.dart';

class RecommendationTrendView extends StatelessWidget {
  const RecommendationTrendView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TrendBaseView(
      title: 'おすすめ表示推移',
      chartTitle: 'おすすめ表示数推移グラフ',
      emptyDetail: 'おすすめ表示の履歴がありません',
      valueKey: 'impressionCount',
      trendProvider: recommendationTrendNotifierProvider,
      onFetch: (ref, storeId, period) {
        return ref
            .read(recommendationTrendNotifierProvider.notifier)
            .fetchTrendData(storeId, period);
      },
      onFetchWithDate: (ref, storeId, period, anchorDate) {
        return ref
            .read(recommendationTrendNotifierProvider.notifier)
            .fetchTrendData(storeId, period, anchorDate: anchorDate);
      },
      minAvailableDateResolver: (ref) => ref
          .read(recommendationTrendNotifierProvider.notifier)
          .minAvailableDate,
      periodOptions: const [
        TrendPeriodOption('日', 'day'),
        TrendPeriodOption('月', 'month'),
        TrendPeriodOption('年', 'year'),
      ],
      initialPeriod: 'day',
      secondaryChartTitle: 'おすすめクリック数推移グラフ',
      secondaryEmptyDetail: 'おすすめクリックの履歴がありません',
      secondaryValueKey: 'clickCount',
      secondaryDataBuilder: _buildClickTrendData,
      statsConfig: const TrendStatsConfig(
        totalLabel: '総表示数',
        maxLabel: '最大表示数',
        minLabel: '最小表示数',
        avgLabel: '平均表示数',
        totalIcon: Icons.visibility,
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
          TrendStatItem(
            type: TrendStatType.total,
            label: '総表示数',
            icon: Icons.visibility,
            color: Color(0xFFFF6B35),
          ),
          TrendStatItem(
            type: TrendStatType.max,
            label: '最大表示数',
            icon: Icons.trending_up,
            color: Color(0xFFFF6B35),
          ),
          TrendStatItem(
            type: TrendStatType.avg,
            label: '平均表示数',
            icon: Icons.analytics,
            color: Color(0xFFFF6B35),
          ),
        ],
      ),
      secondaryChartStats: const ChartStatsConfig(
        items: [
          TrendStatItem(
            type: TrendStatType.total,
            label: '総クリック数',
            icon: Icons.touch_app,
            color: Color(0xFFFF6B35),
          ),
          TrendStatItem(
            type: TrendStatType.max,
            label: '最大クリック数',
            icon: Icons.trending_up,
            color: Color(0xFFFF6B35),
          ),
          TrendStatItem(
            type: TrendStatType.avg,
            label: '平均クリック数',
            icon: Icons.analytics,
            color: Color(0xFFFF6B35),
          ),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> _buildClickTrendData(
      List<Map<String, dynamic>> trendData) {
    return trendData.map((data) {
      final value = data['clickCount'];
      int clickCount;
      if (value is int) {
        clickCount = value;
      } else if (value is double) {
        clickCount = value.round();
      } else if (value is num) {
        clickCount = value.toInt();
      } else {
        clickCount = 0;
      }
      return {
        'date': data['date'],
        'clickCount': clickCount,
      };
    }).toList();
  }
}
