import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';

class StoreUserTrendView extends ConsumerStatefulWidget {
  const StoreUserTrendView({Key? key}) : super(key: key);

  @override
  ConsumerState<StoreUserTrendView> createState() => _StoreUserTrendViewState();
}

class _StoreUserTrendViewState extends ConsumerState<StoreUserTrendView> {
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗利用者推移'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userStoreIdProvider);
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final storeIdAsync = ref.watch(userStoreIdProvider);
          
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
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 期間選択セクション
                    _buildPeriodSelector(),
                    
                    const SizedBox(height: 24),
                    
                    // グラフセクション
                    _buildChartSection(storeId),
                    
                    const SizedBox(height: 24),
                    
                    // 統計情報セクション
                    _buildStatsSection(storeId),
                  ],
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

  Widget _buildPeriodSelector() {
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
              _buildPeriodButton('週', 'week'),
              const SizedBox(width: 12),
              _buildPeriodButton('月', 'month'),
              const SizedBox(width: 12),
              _buildPeriodButton('年', 'year'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
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

  Widget _buildChartSection(String storeId) {
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
              Icon(Icons.show_chart, color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                '利用者推移グラフ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer(
            builder: (context, ref, child) {
              final trendDataAsync = ref.watch(storeUserTrendProvider({
                'storeId': storeId,
                'period': _selectedPeriod,
              }));
              
              return trendDataAsync.when(
                data: (trendData) {
                  if (trendData.isEmpty) {
                    return _buildEmptyChart();
                  }
                  
                  return _buildLineChart(trendData);
                },
                loading: () => _buildLoadingChart(),
                error: (error, stackTrace) => _buildErrorChart(storeId),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> trendData) {
    final maxValue = trendData.isNotEmpty 
        ? trendData.map((e) => e['userCount'] as int).reduce((a, b) => a > b ? a : b)
        : 1;
    
    final spots = trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['userCount'] as int).toDouble());
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
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() < trendData.length) {
                    final date = trendData[value.toInt()]['date'] as String;
                    return _buildBottomTitle(date);
                  }
                  return const Text('');
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
          minX: 0,
          maxX: (trendData.length - 1).toDouble(),
          minY: 0,
          maxY: maxValue.toDouble() * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
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
      case 'week':
        final parts = date.split('-');
        displayText = '${parts[1]}/${parts[2]}';
        break;
      case 'month':
        final parts = date.split('-');
        displayText = '${parts[0]}/${parts[1]}';
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

  Widget _buildEmptyChart() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'データがありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '選択した期間に利用者データが存在しません',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingChart() {
    return SizedBox(
      height: 300,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
        ),
      ),
    );
  }

  Widget _buildErrorChart(String storeId) {
    return SizedBox(
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(storeUserTrendProvider({
                  'storeId': storeId,
                  'period': _selectedPeriod,
                }));
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
  }

  Widget _buildStatsSection(String storeId) {
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
          Consumer(
            builder: (context, ref, child) {
              final trendDataAsync = ref.watch(storeUserTrendProvider({
                'storeId': storeId,
                'period': _selectedPeriod,
              }));
              
              return trendDataAsync.when(
                data: (trendData) {
                  if (trendData.isEmpty) {
                    return _buildEmptyStats();
                  }
                  
                  return _buildStatsCards(trendData);
                },
                loading: () => _buildLoadingStats(),
                error: (error, stackTrace) => _buildErrorStats(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(List<Map<String, dynamic>> trendData) {
    final totalUsers = trendData.fold<int>(0, (sum, data) => sum + (data['userCount'] as int));
    final maxUsers = trendData.isNotEmpty 
        ? trendData.map((e) => e['userCount'] as int).reduce((a, b) => a > b ? a : b)
        : 0;
    final minUsers = trendData.isNotEmpty 
        ? trendData.map((e) => e['userCount'] as int).reduce((a, b) => a < b ? a : b)
        : 0;
    final avgUsers = trendData.isNotEmpty ? (totalUsers / trendData.length).round() : 0;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('総利用者数', totalUsers.toString(), Icons.people, Colors.blue),
        _buildStatCard('最大利用者数', maxUsers.toString(), Icons.trending_up, Colors.green),
        _buildStatCard('最小利用者数', minUsers.toString(), Icons.trending_down, Colors.orange),
        _buildStatCard('平均利用者数', avgUsers.toString(), Icons.analytics, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStats() {
    return const Center(
      child: Text(
        '統計データがありません',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
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

  Widget _buildErrorStats() {
    return const Center(
      child: Text(
        '統計データの読み込みに失敗しました',
        style: TextStyle(
          fontSize: 16,
          color: Colors.red,
        ),
      ),
    );
  }
}
