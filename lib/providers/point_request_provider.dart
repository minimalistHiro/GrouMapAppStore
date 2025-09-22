import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/point_request_model.dart';

// ポイント付与リクエストのプロバイダー
final pointRequestProvider = StateNotifierProvider<PointRequestNotifier, AsyncValue<List<PointRequest>>>((ref) {
  return PointRequestNotifier();
});

// 特定の店舗のポイント付与リクエストを取得
final storePointRequestsProvider = StreamProvider.family<List<PointRequest>, String>((ref, storeId) {
  return FirebaseFirestore.instance
      .collection('point_requests')
      .where('storeId', isEqualTo: storeId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => PointRequest.fromJson({
          'id': doc.id,
          ...doc.data(),
        }))
        .toList();
  });
});

// 特定のユーザーのポイント付与リクエストを取得
final userPointRequestsProvider = StreamProvider.family<List<PointRequest>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('point_requests')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => PointRequest.fromJson({
          'id': doc.id,
          ...doc.data(),
        }))
        .toList();
  });
});

// 特定のリクエストの状態を監視
final pointRequestStatusProvider = StreamProvider.family<PointRequest?, String>((ref, requestId) {
  return FirebaseFirestore.instance
      .collection('point_requests')
      .doc(requestId)
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists) {
      return PointRequest.fromJson({
        'id': snapshot.id,
        ...snapshot.data()!,
      });
    }
    return null;
  });
});

class PointRequestNotifier extends StateNotifier<AsyncValue<List<PointRequest>>> {
  PointRequestNotifier() : super(const AsyncValue.loading());

  // ポイント付与リクエストを作成
  Future<String?> createPointRequest({
    required String userId,
    required String storeId,
    required String storeName,
    required int amount,
    required int pointsToAward,
    String? description,
  }) async {
    try {
      final requestId = FirebaseFirestore.instance.collection('point_requests').doc().id;
      
      final request = PointRequest(
        id: requestId,
        userId: userId,
        storeId: storeId,
        storeName: storeName,
        amount: amount,
        pointsToAward: pointsToAward,
        status: PointRequestStatus.pending.value,
        createdAt: DateTime.now(),
        description: description ?? 'ポイント付与リクエスト',
      );

      await FirebaseFirestore.instance
          .collection('point_requests')
          .doc(requestId)
          .set(request.toJson());

      debugPrint('ポイント付与リクエストを作成しました: $requestId');
      return requestId;
    } catch (e) {
      debugPrint('ポイント付与リクエスト作成エラー: $e');
      return null;
    }
  }

  // ポイント付与リクエストを承認
  Future<bool> acceptPointRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('point_requests')
          .doc(requestId)
          .update({
        'status': PointRequestStatus.accepted.value,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('ポイント付与リクエストを承認しました: $requestId');
      return true;
    } catch (e) {
      debugPrint('ポイント付与リクエスト承認エラー: $e');
      return false;
    }
  }

  // ポイント付与リクエストを拒否
  Future<bool> rejectPointRequest(String requestId, {String? reason}) async {
    try {
      await FirebaseFirestore.instance
          .collection('point_requests')
          .doc(requestId)
          .update({
        'status': PointRequestStatus.rejected.value,
        'respondedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });

      debugPrint('ポイント付与リクエストを拒否しました: $requestId');
      return true;
    } catch (e) {
      debugPrint('ポイント付与リクエスト拒否エラー: $e');
      return false;
    }
  }

  // リクエストを削除
  Future<bool> deletePointRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('point_requests')
          .doc(requestId)
          .delete();

      debugPrint('ポイント付与リクエストを削除しました: $requestId');
      return true;
    } catch (e) {
      debugPrint('ポイント付与リクエスト削除エラー: $e');
      return false;
    }
  }
}
