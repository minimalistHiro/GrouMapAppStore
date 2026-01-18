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
        'usedCount': 0,
        'minOrderAmount': minOrderAmount,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'applicableItems': applicableItems ?? [],
        'conditions': conditions ?? {},
        'viewCount': 0,
      };

      // ネストされた構造で保存: coupons/{storeId}/coupons/{couponId}
      await couponDoc.set(couponData);

      // 公開クーポンも作成
      await _firestore
          .collection('public_coupons')
          .doc('$storeId::$couponId')
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
          .doc('$storeId::$couponId')
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
          .doc('$storeId::$couponId')
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
          .doc('$storeId::$couponId')
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
