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
        'requestType': 'store',
        'sourceApp': 'store',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error submitting deletion request: $e');
      rethrow;
    }
  }

  // 申請一覧を取得（管理者用）
  Stream<List<Map<String, dynamic>>> getDeletionRequestList({
    String? requestType,
  }) {
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
        }).where((data) {
          if (requestType == null) return true;
          final type = data['requestType'] as String?;
          if (requestType == 'store') {
            // 既存データ互換: requestType 未設定は店舗申請として扱う
            return type == null || type == 'store';
          }
          return type == requestType;
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

  // ユーザー退会理由を既読にする（オーナー管理用）
  Future<void> markUserDeletionReasonAsRead({
    required String requestId,
    required String processedByUid,
  }) async {
    try {
      await _firestore
          .collection('account_deletion_requests')
          .doc(requestId)
          .update({
        'readByOwnerAt': FieldValue.serverTimestamp(),
        'readByOwnerUid': processedByUid.isEmpty ? null : processedByUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking user deletion reason as read: $e');
      rethrow;
    }
  }
}

// 申請一覧ストリームプロバイダー
final deletionRequestListProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.read(accountDeletionProvider);
  return service.getDeletionRequestList(requestType: 'store');
});

// ユーザー退会理由一覧ストリームプロバイダー（管理者閲覧用）
final userDeletionReasonListProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.read(accountDeletionProvider);
  return service.getDeletionRequestList(requestType: 'user');
});

// ユーザー退会理由の未読件数（設定画面バッジ用）
final unreadUserDeletionReasonsCountProvider = Provider<int>((ref) {
  return ref.watch(userDeletionReasonListProvider).maybeWhen(
        data: (items) {
          return items.where((item) => item['readByOwnerAt'] == null).length;
        },
        orElse: () => 0,
      );
});

// pending申請数プロバイダー（バッジ表示用）
final pendingDeletionRequestsCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('account_deletion_requests')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.where((doc) {
      final data = doc.data();
      final type = data['requestType'] as String?;
      return type == null || type == 'store';
    }).length;
  }).handleError((_) => 0);
});
