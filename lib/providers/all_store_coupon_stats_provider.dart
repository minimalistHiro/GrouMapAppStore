import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 全店舗の特別クーポン統計を取得するプロバイダー（オーナー自身の店舗を除外）
final allStoreSpecialCouponStatsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    // 1. 現在のユーザーのcreatedStoresを取得してオーナー店舗を特定
    final currentUser = FirebaseAuth.instance.currentUser;
    Set<String> ownerStoreIds = {};
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        final createdStores = userDoc.data()?['createdStores'];
        if (createdStores is List) {
          ownerStoreIds = createdStores.map((e) => e.toString()).toSet();
        }
      }
    }

    // 2. 全店舗を取得（オーナーの店舗を除外）
    final storesSnapshot =
        await FirebaseFirestore.instance.collection('stores').get();
    final storeNames = <String, String>{};
    for (final doc in storesSnapshot.docs) {
      if (ownerStoreIds.contains(doc.id)) continue;
      final data = doc.data();
      storeNames[doc.id] = (data['name'] as String?) ?? '不明な店舗';
    }

    // 2. 全コイン交換クーポンを取得
    final couponsSnapshot = await FirebaseFirestore.instance
        .collection('user_coupons')
        .where('type', isEqualTo: 'coin_exchange')
        .get();

    // 3. storeIdごとに集計
    final Map<String, Map<String, int>> statsMap = {};
    for (final doc in couponsSnapshot.docs) {
      final data = doc.data();
      final storeId = data['storeId'] as String?;
      if (storeId == null) continue;

      statsMap.putIfAbsent(storeId, () => {
        'issued': 0,
        'used': 0,
        'totalDiscount': 0,
      });

      statsMap[storeId]!['issued'] = statsMap[storeId]!['issued']! + 1;
      if (data['isUsed'] == true) {
        statsMap[storeId]!['used'] = statsMap[storeId]!['used']! + 1;
        final discountValue = data['discountValue'];
        if (discountValue is num) {
          statsMap[storeId]!['totalDiscount'] =
              statsMap[storeId]!['totalDiscount']! + discountValue.toInt();
        }
      }
    }

    // 4. 結果リストを構築
    final result = <Map<String, dynamic>>[];
    for (final entry in storeNames.entries) {
      final storeId = entry.key;
      final storeName = entry.value;
      final stats = statsMap[storeId] ??
          {'issued': 0, 'used': 0, 'totalDiscount': 0};

      result.add({
        'storeId': storeId,
        'storeName': storeName,
        'coinExchange': stats,
      });
    }

    // 割引合計の降順でソート
    result.sort((a, b) {
      final aDiscount =
          (a['coinExchange'] as Map<String, int>)['totalDiscount'] ?? 0;
      final bDiscount =
          (b['coinExchange'] as Map<String, int>)['totalDiscount'] ?? 0;
      return bDiscount.compareTo(aDiscount);
    });

    return result;
  } catch (e) {
    debugPrint('Error fetching all store special coupon stats: $e');
    return [];
  }
});
