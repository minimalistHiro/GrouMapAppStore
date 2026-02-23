import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/stats_card.dart';

class TrendStatsConfig {
  const TrendStatsConfig({
    required this.totalLabel,
    required this.maxLabel,
    required this.minLabel,
    required this.avgLabel,
    required this.totalIcon,
    required this.maxIcon,
    required this.minIcon,
    required this.avgIcon,
    required this.totalColor,
    required this.maxColor,
    required this.minColor,
    required this.avgColor,
  });

  final String totalLabel;
  final String maxLabel;
  final String minLabel;
  final String avgLabel;
  final IconData totalIcon;
  final IconData maxIcon;
  final IconData minIcon;
  final IconData avgIcon;
  final Color totalColor;
  final Color maxColor;
  final Color minColor;
  final Color avgColor;
}

enum TrendStatType { total, max, min, avg, lastValue }

class TrendStatItem {
  const TrendStatItem({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });
  final TrendStatType type;
  final String label;
  final IconData icon;
  final Color color;
}

class ChartStatsConfig {
  const ChartStatsConfig({required this.items});
  final List<TrendStatItem> items;
}

class TrendPeriodOption {
  const TrendPeriodOption(this.label, this.value);

  final String label;
  final String value;
}

typedef TrendFetch = FutureOr<void> Function(WidgetRef ref, String storeId, String period);
typedef TrendFetchWithDate = FutureOr<void> Function(WidgetRef ref, String storeId, String period, DateTime anchorDate);

class TrendBaseView extends ConsumerStatefulWidget {
  const TrendBaseView({
    Key? key,
    required this.title,
    required this.chartTitle,
    required this.emptyDetail,
    required this.valueKey,
    required this.trendProvider,
    required this.onFetch,
    required this.statsConfig,
    this.valueFormatter,
    this.secondaryChartTitle,
    this.secondaryEmptyDetail,
    this.secondaryValueKey,
    this.secondaryDataBuilder,
    this.periodOptions = const [
      TrendPeriodOption('週', 'week'),
      TrendPeriodOption('月', 'month'),
      TrendPeriodOption('年', 'year'),
    ],
    this.initialPeriod,
    this.onFetchWithDate,
    this.minAvailableDateResolver,
    this.filterWidget,
    this.primaryChartStats,
    this.secondaryChartStats,
    this.overrideStoreId,
  }) : super(key: key);

  final String title;
  final String chartTitle;
  final String emptyDetail;
  final String valueKey;
  final ProviderListenable<AsyncValue<List<Map<String, dynamic>>>> trendProvider;
  final TrendFetch onFetch;
  final TrendStatsConfig statsConfig;
  final String Function(int value)? valueFormatter;
  final String? secondaryChartTitle;
  final String? secondaryEmptyDetail;
  final String? secondaryValueKey;
  final List<Map<String, dynamic>> Function(List<Map<String, dynamic>> trendData)? secondaryDataBuilder;
  final List<TrendPeriodOption> periodOptions;
  final String? initialPeriod;
  final TrendFetchWithDate? onFetchWithDate;
  final DateTime? Function(WidgetRef ref)? minAvailableDateResolver;
  final Widget? filterWidget;
  final ChartStatsConfig? primaryChartStats;
  final ChartStatsConfig? secondaryChartStats;
  final String? overrideStoreId;

  @override
  ConsumerState<TrendBaseView> createState() => _TrendBaseViewState();
}

class _TrendBaseViewState extends ConsumerState<TrendBaseView> {
  String _selectedPeriod = 'week';
  bool _hasInitialized = false;
  DateTime _anchorDate = DateTime.now();

  bool get _hasSecondaryChart => widget.secondaryChartTitle != null && widget.secondaryValueKey != null;
  bool get _showsPeriodHeader =>
      widget.onFetchWithDate != null && (_selectedPeriod == 'day' || _selectedPeriod == 'month');

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod ?? _selectedPeriod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: widget.title,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final storeIdAsync = widget.overrideStoreId != null
              ? AsyncValue.data(widget.overrideStoreId)
              : ref.watch(userStoreIdProvider);

          return storeIdAsync.when(
            data: (storeId) {
              if (storeId == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '店舗情報が見つかりません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final trendDataAsync = ref.watch(widget.trendProvider);

              if (!_hasInitialized) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _triggerFetch(ref, storeId);
                  _hasInitialized = true;
                });
              }

              return trendDataAsync.when(
                data: (trendData) {
                  final secondaryData = _hasSecondaryChart
                      ? (widget.secondaryDataBuilder?.call(trendData) ?? trendData)
                      : <Map<String, dynamic>>[];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeriodSelector(storeId),
                        if (widget.filterWidget != null) ...[
                          const SizedBox(height: 16),
                          widget.filterWidget!,
                        ],
                        const SizedBox(height: 24),
                        _buildChartSectionWithData(
                          trendData,
                          chartTitle: widget.chartTitle,
                          emptyDetail: widget.emptyDetail,
                          valueKey: widget.valueKey,
                          storeId: storeId,
                        ),
                        if (_hasInlineStats && widget.primaryChartStats != null) ...[
                          const SizedBox(height: 16),
                          _buildInlineStats(trendData, widget.valueKey, widget.primaryChartStats!),
                        ],
                        if (_hasSecondaryChart) ...[
                          const SizedBox(height: 24),
                          _buildChartSectionWithData(
                            secondaryData,
                            chartTitle: widget.secondaryChartTitle!,
                            emptyDetail: widget.secondaryEmptyDetail ?? widget.emptyDetail,
                            valueKey: widget.secondaryValueKey!,
                            storeId: storeId,
                          ),
                          if (_hasInlineStats && widget.secondaryChartStats != null) ...[
                            const SizedBox(height: 16),
                            _buildInlineStats(secondaryData, widget.secondaryValueKey!, widget.secondaryChartStats!),
                          ],
                        ],
                        if (!_hasInlineStats) ...[
                          const SizedBox(height: 24),
                          _buildStatsSectionWithData(trendData),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(storeId),
                      if (widget.filterWidget != null) ...[
                        const SizedBox(height: 16),
                        widget.filterWidget!,
                      ],
                      const SizedBox(height: 24),
                      _buildLoadingChart(storeId, widget.chartTitle),
                      if (_hasSecondaryChart) ...[
                        const SizedBox(height: 24),
                        _buildLoadingChart(storeId, widget.secondaryChartTitle!),
                      ],
                      if (!_hasInlineStats) ...[
                        const SizedBox(height: 24),
                        _buildLoadingStatsCard(),
                      ],
                    ],
                  ),
                ),
                error: (error, stackTrace) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(storeId),
                      if (widget.filterWidget != null) ...[
                        const SizedBox(height: 16),
                        widget.filterWidget!,
                      ],
                      const SizedBox(height: 24),
                      _buildErrorChart(storeId, widget.chartTitle),
                      if (_hasSecondaryChart) ...[
                        const SizedBox(height: 24),
                        _buildErrorChart(storeId, widget.secondaryChartTitle!),
                      ],
                      if (!_hasInlineStats) ...[
                        const SizedBox(height: 24),
                        _buildErrorStatsCard(),
                      ],
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
              ),
            ),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '店舗情報の読み込みに失敗しました',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(userStoreIdProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(String storeId) {
    final options = widget.periodOptions;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                '期間選択',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                _buildPeriodButton(options[i].label, options[i].value, storeId),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period, String storeId) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedPeriod != period) {
            setState(() {
              _selectedPeriod = period;
              _anchorDate = DateTime.now();
            });
            _triggerFetch(ref, storeId);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSectionWithData(
    List<Map<String, dynamic>> trendData, {
    required String chartTitle,
    required String emptyDetail,
    required String valueKey,
    required String storeId,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showsPeriodHeader) ...[
            _buildPeriodHeader(storeId),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFFFF6B35), size: 24),
              const SizedBox(width: 8),
              Text(
                chartTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          trendData.isEmpty
              ? _buildEmptyChart(emptyDetail)
              : _buildChartWithData(trendData, valueKey: valueKey),
        ],
      ),
    );
  }

  Widget _buildChartWithData(
    List<Map<String, dynamic>> trendData, {
    required String valueKey,
  }) {
    // すべての期間で折れ線グラフを使用
    return _buildLineChart(trendData, valueKey: valueKey);
  }

  Widget _buildBarChart(
    List<Map<String, dynamic>> trendData, {
    required String valueKey,
  }) {
    final maxValue = trendData.isNotEmpty
        ? trendData.map((data) => _getValue(data, valueKey)).reduce((a, b) => a > b ? a : b)
        : 1;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: maxValue == 0 ? 1 : maxValue.toDouble() * 1.1,
          minY: 0,
          barTouchData: BarTouchData(enabled: true),
          gridData: FlGridData(
            show: true,
            horizontalInterval: maxValue > 10 ? (maxValue / 5).ceil().toDouble() : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _calculateInterval(trendData.length),
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trendData.length) {
                    return const SizedBox.shrink();
                  }
                  final date = trendData[index]['date'] as String;
                  return _buildBottomTitle(date);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxValue > 10 ? (maxValue / 5).ceil().toDouble() : 1,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          barGroups: trendData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: _getValue(entry.value, valueKey).toDouble(),
                  color: const Color(0xFFFF6B35),
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineChart(
    List<Map<String, dynamic>> trendData, {
    required String valueKey,
  }) {
    final maxValue = trendData.isNotEmpty
        ? trendData.map((data) => _getValue(data, valueKey)).reduce((a, b) => a > b ? a : b)
        : 1;

    final spots = trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), _getValue(entry.value, valueKey).toDouble());
    }).toList();

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: maxValue > 10 ? (maxValue / 5).ceil().toDouble() : 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _calculateInterval(trendData.length),
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trendData.length) {
                    return const SizedBox.shrink();
                  }
                  final date = trendData[index]['date'] as String;
                  return _buildBottomTitle(date);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxValue > 10 ? (maxValue / 5).ceil().toDouble() : 1,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= trendData.length) return null;

                  final data = trendData[index];
                  final date = data['date'] as String;
                  final value = _getValue(data, valueKey);
                  final formattedDate = _formatDateForTooltip(date);

                  return LineTooltipItem(
                    '$formattedDate\n${_formatValue(value)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
              getTooltipColor: (LineBarSpot spot) => const Color(0xFFFF6B35).withOpacity(0.9),
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
            ),
            handleBuiltInTouches: true,
          ),
          minX: 0,
          maxX: trendData.length <= 1 ? 0.0 : (trendData.length - 1).toDouble(),
          minY: 0,
          maxY: maxValue == 0 ? 1 : maxValue.toDouble() * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B35),
                  Color(0xFFFF8A65),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFFFF6B35),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.3),
                    const Color(0xFFFF6B35).withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTitle(String date) {
    String displayText;
    switch (_selectedPeriod) {
      case 'day':
        final parts = date.split('-');
        displayText = int.parse(parts[2]).toString();
        break;
      case 'week':
        final parts = date.split('-');
        displayText = '${parts[1]}/${parts[2]}';
        break;
      case 'month':
        final parts = date.split('-');
        displayText = int.parse(parts[1]).toString();
        break;
      case 'year':
        displayText = date;
        break;
      default:
        displayText = date;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        displayText,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String emptyDetail) {
    String periodText;
    switch (_selectedPeriod) {
      case 'day':
        periodText = '今月';
        break;
      case 'week':
        periodText = '過去7日間';
        break;
      case 'month':
        periodText = '過去1ヶ月間';
        break;
      case 'year':
        periodText = '過去1年間';
        break;
      default:
        periodText = '選択した期間';
    }

    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'データがありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$periodTextに',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              emptyDetail,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    '別の期間を選択してみてください',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingChart(String storeId, String chartTitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showsPeriodHeader) ...[
            _buildPeriodHeader(storeId),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFFFF6B35), size: 24),
              const SizedBox(width: 8),
              Text(
                chartTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorChart(String storeId, String chartTitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showsPeriodHeader) ...[
            _buildPeriodHeader(storeId),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFFFF6B35), size: 24),
              const SizedBox(width: 8),
              Text(
                chartTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'データの読み込みに失敗しました',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ネットワーク接続を確認してください',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onFetch(ref, storeId, _selectedPeriod);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('再試行'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSectionWithData(List<Map<String, dynamic>> trendData) {
    if (trendData.isEmpty) {
      return StatsCard(
        title: '統計情報',
        titleIcon: Icons.analytics,
        items: const [],
        child: _buildEmptyStats(),
      );
    }
    return _buildStatsCardsAsStatsCard(trendData);
  }

  Widget _buildPeriodHeader(String storeId) {
    final label = _getPeriodLabel();
    final canGoPrev = _canMovePrev();
    final canGoNext = _canMoveNext();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: canGoPrev
              ? () {
                  _shiftPeriod(storeId, -1);
                }
              : null,
          child: const Text('<'),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        TextButton(
          onPressed: canGoNext
              ? () {
                  _shiftPeriod(storeId, 1);
                }
              : null,
          child: const Text('>'),
        ),
      ],
    );
  }

  void _shiftPeriod(String storeId, int offset) {
    setState(() {
      switch (_selectedPeriod) {
        case 'day':
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + offset, 1);
          break;
        case 'month':
          _anchorDate = DateTime(_anchorDate.year + offset, 1, 1);
          break;
        default:
          _anchorDate = DateTime(_anchorDate.year + offset, _anchorDate.month, _anchorDate.day);
          break;
      }
    });
    _triggerFetch(ref, storeId);
  }

  bool _canMoveNext() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'day':
        return _anchorDate.year < now.year ||
            (_anchorDate.year == now.year && _anchorDate.month < now.month);
      case 'month':
        return _anchorDate.year < now.year;
      default:
        return true;
    }
  }

  bool _canMovePrev() {
    final minDate = widget.minAvailableDateResolver?.call(ref);
    if (minDate == null) {
      return true;
    }
    switch (_selectedPeriod) {
      case 'day':
        final currentMonth = DateTime(_anchorDate.year, _anchorDate.month, 1);
        final minMonth = DateTime(minDate.year, minDate.month, 1);
        return currentMonth.isAfter(minMonth);
      case 'month':
        return _anchorDate.year > minDate.year;
      default:
        return true;
    }
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'day':
        return '${_anchorDate.year}年${_anchorDate.month}月';
      case 'month':
        return '${_anchorDate.year}年';
      default:
        return '';
    }
  }

  void _triggerFetch(WidgetRef ref, String storeId) {
    final fetchWithDate = widget.onFetchWithDate;
    if (fetchWithDate != null) {
      fetchWithDate(ref, storeId, _selectedPeriod, _anchorDate);
    } else {
      widget.onFetch(ref, storeId, _selectedPeriod);
    }
  }

  bool get _hasInlineStats => widget.primaryChartStats != null || widget.secondaryChartStats != null;

  int _computeStatValue(TrendStatType type, List<Map<String, dynamic>> data, String valueKey) {
    if (data.isEmpty) return 0;
    switch (type) {
      case TrendStatType.total:
        return data.fold<int>(0, (sum, d) => sum + _getValue(d, valueKey));
      case TrendStatType.max:
        return data.map((d) => _getValue(d, valueKey)).reduce((a, b) => a > b ? a : b);
      case TrendStatType.min:
        return data.map((d) => _getValue(d, valueKey)).reduce((a, b) => a < b ? a : b);
      case TrendStatType.avg:
        final total = data.fold<int>(0, (sum, d) => sum + _getValue(d, valueKey));
        return (total / data.length).round();
      case TrendStatType.lastValue:
        return _getValue(data.last, valueKey);
    }
  }

  Widget _buildInlineStats(List<Map<String, dynamic>> trendData, String valueKey, ChartStatsConfig config) {
    if (trendData.isEmpty) return const SizedBox.shrink();

    final items = config.items.map((item) {
      final value = _computeStatValue(item.type, trendData, valueKey);
      return StatItem(
        label: item.label,
        value: _formatValue(value),
        icon: item.icon,
        color: item.color,
      );
    }).toList();

    return StatsCard(
      title: '統計情報',
      titleIcon: Icons.analytics,
      items: items,
    );
  }

  Widget _buildStatsCardsAsStatsCard(List<Map<String, dynamic>> trendData) {
    final total = trendData.fold<int>(0, (sum, data) => sum + _getValue(data, widget.valueKey));
    final maxValue = trendData.isNotEmpty
        ? trendData.map((data) => _getValue(data, widget.valueKey)).reduce((a, b) => a > b ? a : b)
        : 0;
    final minValue = trendData.isNotEmpty
        ? trendData.map((data) => _getValue(data, widget.valueKey)).reduce((a, b) => a < b ? a : b)
        : 0;
    final avgValue = trendData.isNotEmpty ? (total / trendData.length).round() : 0;

    return StatsCard(
      title: '統計情報',
      titleIcon: Icons.analytics,
      items: [
        StatItem(
          label: widget.statsConfig.totalLabel,
          value: _formatValue(total),
          icon: widget.statsConfig.totalIcon,
          color: widget.statsConfig.totalColor,
        ),
        StatItem(
          label: widget.statsConfig.maxLabel,
          value: _formatValue(maxValue),
          icon: widget.statsConfig.maxIcon,
          color: widget.statsConfig.maxColor,
        ),
        StatItem(
          label: widget.statsConfig.minLabel,
          value: _formatValue(minValue),
          icon: widget.statsConfig.minIcon,
          color: widget.statsConfig.minColor,
        ),
        StatItem(
          label: widget.statsConfig.avgLabel,
          value: _formatValue(avgValue),
          icon: widget.statsConfig.avgIcon,
          color: widget.statsConfig.avgColor,
        ),
      ],
    );
  }

  Widget _buildEmptyStats() {
    String periodText;
    switch (_selectedPeriod) {
      case 'day':
        periodText = '今月';
        break;
      case 'week':
        periodText = '過去7日間';
        break;
      case 'month':
        periodText = '過去1ヶ月間';
        break;
      case 'year':
        periodText = '過去1年間';
        break;
      default:
        periodText = '選択した期間';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '統計データがありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$periodTextにデータが存在しません',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
      ),
    );
  }

  Widget _buildLoadingStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                '統計情報',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLoadingStats(),
        ],
      ),
    );
  }

  Widget _buildErrorStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                '統計情報',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildErrorStats(),
        ],
      ),
    );
  }

  Widget _buildErrorStats() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              '統計データの読み込みに失敗しました',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'リフレッシュボタンで再試行してください',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // データポイント数に応じて適切なintervalを計算
  double _calculateInterval(int dataLength) {
    if (dataLength <= 1) {
      // データが1つ以下の場合、intervalを無効化
      return double.maxFinite;
    } else if (dataLength <= 3) {
      // データが2-3個の場合、すべて表示
      return 1.0;
    } else if (dataLength <= 7) {
      // データが4-7個の場合、間隔1
      return 1.0;
    } else if (dataLength <= 14) {
      // データが8-14個の場合、2つおき
      return 2.0;
    } else if (dataLength <= 31) {
      // データが15-31個の場合、3つおき
      return 3.0;
    } else {
      // それ以上の場合、適切な間隔を計算
      return (dataLength / 10).ceilToDouble();
    }
  }

  int _getValue(Map<String, dynamic> data, String valueKey) {
    final value = data[valueKey];
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    return 0;
  }

  String _formatValue(int value) {
    if (widget.valueFormatter != null) {
      return widget.valueFormatter!(value);
    }
    return value.toString();
  }

  String _formatDateForTooltip(String date) {
    switch (_selectedPeriod) {
      case 'day':
        // 例: "2025-02-10" → "2月10日"
        final parts = date.split('-');
        return '${int.parse(parts[1])}月${int.parse(parts[2])}日';

      case 'week':
        // 例: "2025-02-10" → "2月10日"
        final parts = date.split('-');
        return '${int.parse(parts[1])}月${int.parse(parts[2])}日';

      case 'month':
        // 例: "2025-02" → "2月"
        final parts = date.split('-');
        return '${int.parse(parts[1])}月';

      case 'year':
        // 例: "2025" → "2025年"
        return '${date}年';

      default:
        return date;
    }
  }
}
