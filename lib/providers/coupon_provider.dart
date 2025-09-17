import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 店舗のクーポンプロバイダー
final storeCouponsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('coupons')
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
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
    final now = Timestamp.now();
    return FirebaseFirestore.instance
        .collection('coupons')
        .where('storeId', isEqualTo: storeId)
        .where('validUntil', isGreaterThan: now)
        .orderBy('validUntil')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
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
