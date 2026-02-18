import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 店舗のクーポンプロバイダー
final storeCouponsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('coupons')
        .doc(storeId)
        .collection('coupons')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList()
        ..sort((a, b) {
          final aTime = a['createdAt']?.toDate() ?? DateTime(1970);
          final bTime = b['createdAt']?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime); // 降順ソート
        });
    }).handleError((error) {
      debugPrint('Error fetching store coupons: $error');
      return [];
    });
  } catch (e) {
    debugPrint('Error creating store coupons stream: $e');
    return Stream.value([]);
  }
});

// アクティブなクーポンプロバイダー
final activeCouponsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('coupons')
        .doc(storeId)
        .collection('coupons')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final validUntil = data['validUntil']?.toDate();
            final isActive = data['isActive'] ?? true;
            return isActive && validUntil != null && validUntil.isAfter(now);
          })
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList()
        ..sort((a, b) {
          final aTime = a['createdAt']?.toDate() ?? DateTime(1970);
          final bTime = b['createdAt']?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime); // 降順ソート
        });
    }).handleError((error) {
      debugPrint('Error fetching active coupons: $error');
      return [];
    });
  } catch (e) {
    debugPrint('Error creating active coupons stream: $e');
    return Stream.value([]);
  }
});

// クーポン使用統計プロバイダー
final couponUsageStatsProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .collection('stats')
        .doc('coupon_usage')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return {
        'totalUsed': 0,
        'todayUsed': 0,
        'thisWeekUsed': 0,
        'thisMonthUsed': 0,
      };
    }).handleError((error) {
      debugPrint('Error fetching coupon usage stats: $error');
      return {
        'totalUsed': 0,
        'todayUsed': 0,
        'thisWeekUsed': 0,
        'thisMonthUsed': 0,
      };
    });
  } catch (e) {
    debugPrint('Error creating coupon usage stats stream: $e');
    return Stream.value({
      'totalUsed': 0,
      'todayUsed': 0,
      'thisWeekUsed': 0,
      'thisMonthUsed': 0,
    });
  }
});

// 今日のクーポン使用数プロバイダー（usedByサブコレクションから取得）
final todayCouponUsageCountProvider = FutureProvider.family<int, String>((ref, storeId) async {
  try {
    // 今日の開始時刻と終了時刻を取得
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    // 店舗の全クーポンを取得
    final couponsSnapshot = await FirebaseFirestore.instance
        .collection('coupons')
        .doc(storeId)
        .collection('coupons')
        .get();
    
    int totalUsedToday = 0;
    
    // 各クーポンのusedByサブコレクションをチェック
    for (final couponDoc in couponsSnapshot.docs) {
      try {
        final usedBySnapshot = await FirebaseFirestore.instance
            .collection('coupons')
            .doc(storeId)
            .collection('coupons')
            .doc(couponDoc.id)
            .collection('usedBy')
            .where('usedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('usedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get();
        
        totalUsedToday += usedBySnapshot.docs.length;
      } catch (e) {
        debugPrint('Error fetching usedBy for coupon ${couponDoc.id}: $e');
      }
    }
    
    return totalUsedToday;
  } catch (e) {
    debugPrint('Error fetching today coupon usage count: $e');
    return 0;
  }
});

// 月間クーポン使用数プロバイダー（usedByサブコレクションから取得）
final monthlyCouponUsageCountProvider = FutureProvider.family<int, String>((ref, storeId) async {
  try {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final couponsSnapshot = await FirebaseFirestore.instance
        .collection('coupons')
        .doc(storeId)
        .collection('coupons')
        .get();

    int totalUsedThisMonth = 0;
    for (final couponDoc in couponsSnapshot.docs) {
      try {
        final usedBySnapshot = await FirebaseFirestore.instance
            .collection('coupons')
            .doc(storeId)
            .collection('coupons')
            .doc(couponDoc.id)
            .collection('usedBy')
            .where('usedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('usedAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
            .get();

        totalUsedThisMonth += usedBySnapshot.docs.length;
      } catch (e) {
        debugPrint('Error fetching usedBy for coupon ${couponDoc.id}: $e');
      }
    }

    return totalUsedThisMonth;
  } catch (e) {
    debugPrint('Error fetching monthly coupon usage count: $e');
    return 0;
  }
});

// クーポン利用者推移の状態管理
class CouponUsageTrendNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  CouponUsageTrendNotifier() : super(const AsyncValue.loading());

  DateTime? _minAvailableDate;
  DateTime? get minAvailableDate => _minAvailableDate;

  Future<void> fetchTrendData(String storeId, String period, {DateTime? anchorDate}) async {
    try {
      debugPrint('=== CouponUsageTrendNotifier START ===');
      debugPrint('StoreId: $storeId, Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      DateTime endDate;
      final baseDate = anchorDate ?? DateTime.now();

      switch (period) {
        case 'day':
          startDate = DateTime(baseDate.year, baseDate.month, 1);
          endDate = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);
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
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
      }

      debugPrint('Date Range: ${startDate.toLocal()} to ${endDate.toLocal()}');

      // 店舗の全クーポンを取得
      final couponsSnapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .get();

      debugPrint('Found ${couponsSnapshot.docs.length} coupons');

      final Map<String, int> groupedData = {};
      DateTime? earliestDate;

      // 各クーポンのusedByサブコレクションからデータを取得
      for (final couponDoc in couponsSnapshot.docs) {
        try {
          final usedBySnapshot = await FirebaseFirestore.instance
              .collection('coupons')
              .doc(storeId)
              .collection('coupons')
              .doc(couponDoc.id)
              .collection('usedBy')
              .get();

          for (final usedDoc in usedBySnapshot.docs) {
            final data = usedDoc.data();
            final usedAt = data['usedAt'];
            if (usedAt == null) continue;

            DateTime docDate;
            if (usedAt is Timestamp) {
              docDate = usedAt.toDate();
            } else if (usedAt is DateTime) {
              docDate = usedAt;
            } else {
              continue;
            }

            if (earliestDate == null || docDate.isBefore(earliestDate!)) {
              earliestDate = docDate;
            }

            final isWithinRange = period == 'day' || period == 'month'
                ? !docDate.isBefore(startDate) && !docDate.isAfter(endDate)
                : docDate.isAfter(startDate) && docDate.isBefore(endDate);
            if (!isWithinRange) continue;

            String groupKey;
            switch (period) {
              case 'day':
              case 'week':
                groupKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}-${docDate.day.toString().padLeft(2, '0')}';
                break;
              case 'month':
                groupKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}';
                break;
              case 'year':
                groupKey = '${docDate.year}';
                break;
              default:
                groupKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}-${docDate.day.toString().padLeft(2, '0')}';
            }

            groupedData[groupKey] = (groupedData[groupKey] ?? 0) + 1;
          }
        } catch (e) {
          debugPrint('Error fetching usedBy for coupon ${couponDoc.id}: $e');
        }
      }

      final List<Map<String, dynamic>> result;
      if (period == 'day') {
        final days = <Map<String, dynamic>>[];
        for (var date = startDate;
            !date.isAfter(endDate);
            date = date.add(const Duration(days: 1))) {
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          days.add({
            'date': key,
            'couponUsageCount': groupedData[key] ?? 0,
          });
        }
        result = days;
      } else if (period == 'month') {
        final months = <Map<String, dynamic>>[];
        final now = DateTime.now();
        final maxMonth = baseDate.year == now.year ? now.month : 12;
        for (var month = 1; month <= maxMonth; month++) {
          final key = '${baseDate.year}-${month.toString().padLeft(2, '0')}';
          months.add({
            'date': key,
            'couponUsageCount': groupedData[key] ?? 0,
          });
        }
        result = months;
      } else {
        result = groupedData.entries.map((entry) {
          return {
            'date': entry.key,
            'couponUsageCount': entry.value,
          };
        }).toList();
      }

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      if (result.isNotEmpty) {
        debugPrint('Sample data: ${result.take(3)}');
      }
      debugPrint('=== CouponUsageTrendNotifier END ===');

      _minAvailableDate = earliestDate;
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      debugPrint('Error fetching coupon usage trend data: $e');
      debugPrint('StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// クーポン利用者推移プロバイダー（StateNotifier版）
final couponUsageTrendNotifierProvider = StateNotifierProvider<CouponUsageTrendNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return CouponUsageTrendNotifier();
});

// 個別クーポン利用推移の状態管理
class IndividualCouponUsageTrendNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  IndividualCouponUsageTrendNotifier() : super(const AsyncValue.loading());

  DateTime? _minAvailableDate;
  DateTime? get minAvailableDate => _minAvailableDate;

  Future<void> fetchTrendData(String storeId, String couponId, String period, {DateTime? anchorDate}) async {
    try {
      state = const AsyncValue.loading();

      DateTime startDate;
      DateTime endDate;
      final baseDate = anchorDate ?? DateTime.now();

      switch (period) {
        case 'day':
          startDate = DateTime(baseDate.year, baseDate.month, 1);
          endDate = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);
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
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
      }

      // 対象クーポンのusedByサブコレクションからデータを取得
      final usedBySnapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(couponId)
          .collection('usedBy')
          .get();

      final Map<String, int> groupedData = {};
      DateTime? earliestDate;

      for (final usedDoc in usedBySnapshot.docs) {
        final data = usedDoc.data();
        final usedAt = data['usedAt'];
        if (usedAt == null) continue;

        DateTime docDate;
        if (usedAt is Timestamp) {
          docDate = usedAt.toDate();
        } else if (usedAt is DateTime) {
          docDate = usedAt;
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

        String groupKey;
        switch (period) {
          case 'day':
          case 'week':
            groupKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}-${docDate.day.toString().padLeft(2, '0')}';
            break;
          case 'month':
            groupKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}';
            break;
          case 'year':
            groupKey = '${docDate.year}';
            break;
          default:
            groupKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}-${docDate.day.toString().padLeft(2, '0')}';
        }

        groupedData[groupKey] = (groupedData[groupKey] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> result;
      if (period == 'day') {
        final days = <Map<String, dynamic>>[];
        for (var date = startDate;
            !date.isAfter(endDate);
            date = date.add(const Duration(days: 1))) {
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          days.add({
            'date': key,
            'couponUsageCount': groupedData[key] ?? 0,
          });
        }
        result = days;
      } else if (period == 'month') {
        final months = <Map<String, dynamic>>[];
        final now = DateTime.now();
        final maxMonth = baseDate.year == now.year ? now.month : 12;
        for (var month = 1; month <= maxMonth; month++) {
          final key = '${baseDate.year}-${month.toString().padLeft(2, '0')}';
          months.add({
            'date': key,
            'couponUsageCount': groupedData[key] ?? 0,
          });
        }
        result = months;
      } else {
        result = groupedData.entries.map((entry) {
          return {
            'date': entry.key,
            'couponUsageCount': entry.value,
          };
        }).toList();
      }

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      _minAvailableDate = earliestDate;
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      debugPrint('Error fetching individual coupon usage trend data: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// 個別クーポン利用推移プロバイダー
final individualCouponUsageTrendNotifierProvider = StateNotifierProvider<IndividualCouponUsageTrendNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return IndividualCouponUsageTrendNotifier();
});

// クーポンサービスクラス
class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // クーポンを作成
  Future<void> createCoupon({
    required String storeId,
    required String title,
    required String description,
    required String couponType,
    required double discountValue,
    required String discountType,
    required DateTime validFrom,
    required DateTime validUntil,
    required int usageLimit,
    int requiredStampCount = 10,
    bool noExpiry = false,
    int minOrderAmount = 0,
    String? imageUrl,
    List<String>? applicableItems,
    Map<String, dynamic>? conditions,
  }) async {
    try {
      final couponDoc = _firestore
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc();
      final couponId = couponDoc.id;
      final couponData = {
        'couponId': couponId,
        'storeId': storeId,
        'title': title,
        'description': description,
        'couponType': couponType,
        'discountValue': discountValue,
        'discountType': discountType,
        'validFrom': Timestamp.fromDate(validFrom),
        'validUntil': Timestamp.fromDate(validUntil),
        'usageLimit': usageLimit,
        'requiredStampCount': requiredStampCount,
        'usedCount': 0,
        'minOrderAmount': minOrderAmount,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'applicableItems': applicableItems ?? [],
        'conditions': conditions ?? {},
        'viewCount': 0,
        'noExpiry': noExpiry,
      };

      // ネストされた構造で保存: coupons/{storeId}/coupons/{couponId}
      await couponDoc.set(couponData);

      // 公開クーポンも作成
      await _firestore
          .collection('public_coupons')
          .doc(couponId)
          .set({
        'key': '$storeId::$couponId',
        ...couponData,
      });
    } catch (e) {
      debugPrint('Error creating coupon: $e');
      throw Exception('クーポンの作成に失敗しました: $e');
    }
  }

  // クーポンを更新
  Future<void> updateCoupon({
    required String storeId,
    required String couponId,
    required String title,
    required String description,
    required String couponType,
    required double discountValue,
    required String discountType,
    required DateTime validFrom,
    required DateTime validUntil,
    required int usageLimit,
    int? requiredStampCount,
    bool? noExpiry,
    int? minOrderAmount,
    String? imageUrl,
    List<String>? applicableItems,
    Map<String, dynamic>? conditions,
  }) async {
    try {
      final updateData = {
        'title': title,
        'description': description,
        'couponType': couponType,
        'discountValue': discountValue,
        'discountType': discountType,
        'validFrom': Timestamp.fromDate(validFrom),
        'validUntil': Timestamp.fromDate(validUntil),
        'usageLimit': usageLimit,
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      };

      if (requiredStampCount != null) {
        updateData['requiredStampCount'] = requiredStampCount;
      }
      if (noExpiry != null) {
        updateData['noExpiry'] = noExpiry;
      }
      if (minOrderAmount != null) {
        updateData['minOrderAmount'] = minOrderAmount;
      }
      if (applicableItems != null) {
        updateData['applicableItems'] = applicableItems;
      }
      if (conditions != null) {
        updateData['conditions'] = conditions;
      }

      await _firestore
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(couponId)
          .update(updateData);

      await _firestore
          .collection('public_coupons')
          .doc(couponId)
          .update(updateData);
    } catch (e) {
      debugPrint('Error updating coupon: $e');
      throw Exception('クーポンの更新に失敗しました: $e');
    }
  }

  // クーポンを削除
  Future<void> deleteCoupon({
    required String storeId,
    required String couponId,
  }) async {
    try {
      await _firestore
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(couponId)
          .delete();
      await _firestore
          .collection('public_coupons')
          .doc(couponId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting coupon: $e');
      throw Exception('クーポンの削除に失敗しました: $e');
    }
  }

  // クーポンの有効/無効を切り替え
  Future<void> toggleCouponActive({
    required String storeId,
    required String couponId,
    required bool isActive,
  }) async {
    try {
      await _firestore
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(couponId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _firestore
          .collection('public_coupons')
          .doc(couponId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error toggling coupon active state: $e');
      throw Exception('クーポンの状態変更に失敗しました: $e');
    }
  }
}

// クーポンサービスプロバイダー
final couponServiceProvider = Provider<CouponService>((ref) {
  return CouponService();
});
