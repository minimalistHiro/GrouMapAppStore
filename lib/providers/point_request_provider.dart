import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/point_request_model.dart';

// ポイント付与リクエストのプロバイダー
final pointRequestProvider = StateNotifierProvider<PointRequestNotifier, void>((ref) {
  return PointRequestNotifier();
});

// 特定の店舗のポイント付与リクエストを取得
final storePointRequestsProvider = StreamProvider.family<List<PointRequest>, String>((ref, storeId) {
  return FirebaseFirestore.instance
      .collection('point_requests')
      .doc(storeId)
      .collection('user_requests')
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
      .collectionGroup('user_requests')
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

// 特定のリクエストの状態を監視（新しい構造に対応）
final pointRequestStatusProvider = StreamProvider.family<PointRequest?, String>((ref, requestId) {
  // requestIdの形式: "storeId_userId"
  final parts = requestId.split('_');
  if (parts.length != 2) {
    return Stream.value(null);
  }
  
  final storeId = parts[0];
  final userId = parts[1];
  
  return FirebaseFirestore.instance
      .collection('point_requests')
      .doc(storeId)
      .collection('user_requests')
      .doc(userId)
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

class PointRequestNotifier extends StateNotifier<void> {
  PointRequestNotifier() : super(null);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ポイント付与リクエストを作成
  Future<String?> createPointRequest({
    required String userId,
    required String storeId,
    required String storeName,
    required int amount,
    required int pointsToAward,
    required int userPoints,
    required String description,
  }) async {
    try {
      final docRef = _firestore
          .collection('point_requests')
          .doc(storeId)
          .collection('user_requests')
          .doc(userId);
      
      final newRequest = PointRequest(
        id: docRef.id,
        userId: userId,
        storeId: storeId,
        storeName: storeName,
        amount: amount,
        pointsToAward: pointsToAward,
        userPoints: userPoints,
        description: description,
        status: PointRequestStatus.pending.value,
        createdAt: DateTime.now(),
      );
      await docRef.set(newRequest.toJson());
      return '${storeId}_${userId}'; // 新しいID形式を返す
    } catch (e) {
      print('Error creating point request: $e');
      return null;
    }
  }

  // ポイント付与リクエストの状態を更新
  Future<void> updatePointRequestStatus({
    required String requestId,
    required PointRequestStatus status,
    String? rejectionReason,
  }) async {
    try {
      // requestIdの形式: "storeId_userId"
      final parts = requestId.split('_');
      if (parts.length != 2) {
        throw Exception('Invalid request ID format');
      }
      
      final storeId = parts[0];
      final userId = parts[1];
      
      await _firestore
          .collection('point_requests')
          .doc(storeId)
          .collection('user_requests')
          .doc(userId)
          .update({
        'status': status.value,
        'respondedAt': FieldValue.serverTimestamp(),
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      });
    } catch (e) {
      print('Error updating point request status: $e');
      rethrow;
    }
  }

  // ポイント付与リクエストを承認
  Future<bool> acceptPointRequest(String requestId) async {
    try {
      await updatePointRequestStatus(
        requestId: requestId,
        status: PointRequestStatus.accepted,
      );
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
      await updatePointRequestStatus(
        requestId: requestId,
        status: PointRequestStatus.rejected,
        rejectionReason: reason,
      );
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
      // requestIdの形式: "storeId_userId"
      final parts = requestId.split('_');
      if (parts.length != 2) {
        throw Exception('Invalid request ID format');
      }
      
      final storeId = parts[0];
      final userId = parts[1];
      
      await _firestore
          .collection('point_requests')
          .doc(storeId)
          .collection('user_requests')
          .doc(userId)
          .delete();

      debugPrint('ポイント付与リクエストを削除しました: $requestId');
      return true;
    } catch (e) {
      debugPrint('ポイント付与リクエスト削除エラー: $e');
      return false;
    }
  }
}