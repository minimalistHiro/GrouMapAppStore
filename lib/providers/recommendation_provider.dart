import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// おすすめ表示推移プロバイダー（StateNotifier版）
class RecommendationTrendNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  RecommendationTrendNotifier() : super(const AsyncValue.loading());

  DateTime? _minAvailableDate;
  DateTime? get minAvailableDate => _minAvailableDate;

  Future<void> fetchTrendData(String storeId, String period,
      {DateTime? anchorDate}) async {
    try {
      debugPrint('=== RecommendationTrendNotifier START ===');
      debugPrint('StoreId: $storeId, Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      DateTime endDate;
      final baseDate = anchorDate ?? DateTime.now();

      switch (period) {
        case 'day':
          startDate = DateTime(baseDate.year, baseDate.month, 1);
          endDate =
              DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);
          break;
        case 'week':
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(baseDate.year, 1, 1);
          endDate = DateTime(baseDate.year, 12, 31, 23, 59, 59, 999);
          break;
        case 'year':
          endDate = baseDate;
          startDate =
              DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
      }

      debugPrint('Date Range: ${startDate.toLocal()} to ${endDate.toLocal()}');

      // recommendation_impressions からインプレッション数を取得
      final impressionsSnapshot = await FirebaseFirestore.instance
          .collection('recommendation_impressions')
          .where('targetStoreId', isEqualTo: storeId)
          .where('shownAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('shownAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // recommendation_clicks からクリック数を取得
      final clicksSnapshot = await FirebaseFirestore.instance
          .collection('recommendation_clicks')
          .where('targetStoreId', isEqualTo: storeId)
          .where('clickedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('clickedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      debugPrint(
          'Found ${impressionsSnapshot.docs.length} impressions, ${clicksSnapshot.docs.length} clicks');

      final Map<String, int> impressionGrouped = {};
      final Map<String, int> clickGrouped = {};
      DateTime? earliestDate;

      // インプレッションデータを集計
      for (final doc in impressionsSnapshot.docs) {
        final data = doc.data();
        final shownAt = data['shownAt'];
        if (shownAt == null) continue;

        DateTime docDate;
        if (shownAt is Timestamp) {
          docDate = shownAt.toDate();
        } else if (shownAt is DateTime) {
          docDate = shownAt;
        } else {
          continue;
        }

        if (earliestDate == null || docDate.isBefore(earliestDate)) {
          earliestDate = docDate;
        }

        final isWithinRange = period == 'day' || period == 'month'
            ? !docDate.isBefore(startDate) && !docDate.isAfter(endDate)
            : docDate.isAfter(startDate) && docDate.isBefore(endDate);
        if (!isWithinRange) continue;

        final groupKey = _buildGroupKey(docDate, period);
        impressionGrouped[groupKey] =
            (impressionGrouped[groupKey] ?? 0) + 1;
      }

      // クリックデータを集計
      for (final doc in clicksSnapshot.docs) {
        final data = doc.data();
        final clickedAt = data['clickedAt'];
        if (clickedAt == null) continue;

        DateTime docDate;
        if (clickedAt is Timestamp) {
          docDate = clickedAt.toDate();
        } else if (clickedAt is DateTime) {
          docDate = clickedAt;
        } else {
          continue;
        }

        if (earliestDate == null || docDate.isBefore(earliestDate)) {
          earliestDate = docDate;
        }

        final isWithinRange = period == 'day' || period == 'month'
            ? !docDate.isBefore(startDate) && !docDate.isAfter(endDate)
            : docDate.isAfter(startDate) && docDate.isBefore(endDate);
        if (!isWithinRange) continue;

        final groupKey = _buildGroupKey(docDate, period);
        clickGrouped[groupKey] = (clickGrouped[groupKey] ?? 0) + 1;
      }

      // 結果を構築（期間ごとに全日付を埋める）
      final List<Map<String, dynamic>> result;
      if (period == 'day') {
        final days = <Map<String, dynamic>>[];
        for (var date = startDate;
            !date.isAfter(endDate);
            date = date.add(const Duration(days: 1))) {
          final key = _buildGroupKey(date, period);
          days.add({
            'date': key,
            'impressionCount': impressionGrouped[key] ?? 0,
            'clickCount': clickGrouped[key] ?? 0,
          });
        }
        result = days;
      } else if (period == 'month') {
        final months = <Map<String, dynamic>>[];
        final now = DateTime.now();
        final maxMonth = baseDate.year == now.year ? now.month : 12;
        for (var month = 1; month <= maxMonth; month++) {
          final key =
              '${baseDate.year}-${month.toString().padLeft(2, '0')}';
          months.add({
            'date': key,
            'impressionCount': impressionGrouped[key] ?? 0,
            'clickCount': clickGrouped[key] ?? 0,
          });
        }
        result = months;
      } else {
        final allKeys = {
          ...impressionGrouped.keys,
          ...clickGrouped.keys
        };
        result = allKeys.map((key) {
          return {
            'date': key,
            'impressionCount': impressionGrouped[key] ?? 0,
            'clickCount': clickGrouped[key] ?? 0,
          };
        }).toList();
      }

      result.sort(
          (a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      if (result.isNotEmpty) {
        debugPrint('Sample data: ${result.take(3)}');
      }
      debugPrint('=== RecommendationTrendNotifier END ===');

      _minAvailableDate = earliestDate;
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      debugPrint('Error fetching recommendation trend data: $e');
      debugPrint('StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  String _buildGroupKey(DateTime date, String period) {
    switch (period) {
      case 'day':
      case 'week':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case 'month':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case 'year':
        return '${date.year}';
      default:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}

final recommendationTrendNotifierProvider = StateNotifierProvider<
    RecommendationTrendNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return RecommendationTrendNotifier();
});
