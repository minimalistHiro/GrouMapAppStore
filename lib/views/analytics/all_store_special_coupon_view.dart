import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/all_store_coupon_stats_provider.dart';
import '../../widgets/common_header.dart';

class AllStoreSpecialCouponView extends ConsumerWidget {
  const AllStoreSpecialCouponView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(allStoreSpecialCouponStatsProvider);

    return Scaffold(
      appBar: const CommonHeader(title: '全店舗 特別クーポン'),
      body: statsAsync.when(
        data: (statsList) {
          if (statsList.isEmpty) {
            return const Center(
              child: Text(
                'データがありません',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            );
          }
          // 全店舗合計を計算
          int totalIssued = 0;
          int totalUsed = 0;
          int totalDiscount = 0;
          for (final s in statsList) {
            final ce = s['coinExchange'] as Map<String, int>;
            totalIssued += ce['issued'] ?? 0;
            totalUsed += ce['used'] ?? 0;
            totalDiscount += ce['totalDiscount'] ?? 0;
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: statsList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildTotalCard(
                  totalIssued: totalIssued,
                  totalUsed: totalUsed,
                  totalDiscount: totalDiscount,
                );
              }
              final storeStats = statsList[index - 1];
              final storeName = storeStats['storeName'] as String;
              final coinExchange =
                  storeStats['coinExchange'] as Map<String, int>;
              return _buildStoreCard(storeName, coinExchange);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
        ),
        error: (error, _) => Center(
          child: Text(
            'エラーが発生しました',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard({
    required int totalIssued,
    required int totalUsed,
    required int totalDiscount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
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
                Icon(Icons.summarize_outlined,
                    color: Color(0xFFFF6B35), size: 24),
                SizedBox(width: 8),
                Text(
                  '全店舗合計',
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: '発行枚数',
                  value: '$totalIssued枚',
                ),
                _buildStatItem(
                  label: '使用済み',
                  value: '$totalUsed枚',
                ),
                _buildStatItem(
                  label: '割引合計',
                  value: '¥$totalDiscount',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(String storeName, Map<String, int> coinExchange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              storeName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/icon_coin.png',
                        width: 24, height: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'コイン交換クーポン',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      label: '発行枚数',
                      value: '${coinExchange['issued']}枚',
                    ),
                    _buildStatItem(
                      label: '使用済み',
                      value: '${coinExchange['used']}枚',
                    ),
                    _buildStatItem(
                      label: '割引合計',
                      value: '¥${coinExchange['totalDiscount']}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFA726),
          ),
        ),
      ],
    );
  }
}
