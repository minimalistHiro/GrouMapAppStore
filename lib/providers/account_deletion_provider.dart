import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// アカウント削除申請サービスプロバイダー
final accountDeletionProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService();
});

class AccountDeletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 申請を送信
  Future<void> submitDeletionRequest({
    required String storeId,
    required String storeName,
    String? storeIconImageUrl,
    required String storeCategory,
    required String userId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('account_deletion_requests').add({
        'storeId': storeId,
        'storeName': storeName,
        'storeIconImageUrl': storeIconImageUrl,
        'storeCategory': storeCategory,
        'userId': userId,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error submitting deletion request: $e');
      rethrow;
    }
  }

  // 申請一覧を取得（管理者用）
  Stream<List<Map<String, dynamic>>> getDeletionRequestList() {
    try {
      return _firestore
          .collection('account_deletion_requests')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }).handleError((error) {
        debugPrint('Error fetching deletion request list: $error');
        return [];
      });
    } catch (e) {
      debugPrint('Error creating deletion request stream: $e');
      return Stream.value([]);
    }
  }

  // 申請を承認（店舗のisActiveをfalseに設定）
  Future<void> approveDeletionRequest(
    String requestId,
    String storeId,
    String processedByUid,
  ) async {
    try {
      // 1. 店舗のisActiveをfalseに設定
      await _firestore.collection('stores').doc(storeId).update({
        'isActive': false,
      });
      // 2. 申請のステータスを更新
      await _firestore
          .collection('account_deletion_requests')
          .doc(requestId)
          .update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': processedByUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error approving deletion request: $e');
      rethrow;
    }
  }

  // 申請を拒否
  Future<void> rejectDeletionRequest(
    String requestId,
    String processedByUid,
  ) async {
    try {
      await _firestore
          .collection('account_deletion_requests')
          .doc(requestId)
          .update({
        'status': 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': processedByUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error rejecting deletion request: $e');
      rethrow;
    }
  }
}

// 申請一覧ストリームプロバイダー
final deletionRequestListProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.read(accountDeletionProvider);
  return service.getDeletionRequestList();
});

// pending申請数プロバイダー（バッジ表示用）
final pendingDeletionRequestsCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('account_deletion_requests')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs.length)
      .handleError((_) => 0);
});
