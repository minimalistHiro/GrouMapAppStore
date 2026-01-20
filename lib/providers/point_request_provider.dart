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
      .collection(userId)
      .doc('request')
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data()!;
      // 文字列またはTimestampをDateTimeに変換
      final convertedData = Map<String, dynamic>.from(data);
      if (data['createdAt'] != null) {
        if (data['createdAt'] is String) {
          convertedData['createdAt'] = DateTime.parse(data['createdAt']);
        } else {
          convertedData['createdAt'] = data['createdAt'].toDate();
        }
      }
      if (data['respondedAt'] != null) {
        if (data['respondedAt'] is String) {
          convertedData['respondedAt'] = DateTime.parse(data['respondedAt']);
        } else {
          convertedData['respondedAt'] = data['respondedAt'].toDate();
        }
      }
      
      return PointRequest.fromJson({
        'id': '${storeId}_${userId}',
        ...convertedData,
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
    print('=== PointRequestNotifier.createPointRequest 開始 ===');
    print('パラメータ:');
    print('  userId: $userId');
    print('  storeId: $storeId');
    print('  storeName: $storeName');
    print('  amount: $amount');
    print('  pointsToAward: $pointsToAward');
    print('  userPoints: $userPoints');
    print('  description: $description');
    
    try {
      final requestId = '${storeId}_${userId}';
      print('生成されたrequestId: $requestId');
      
      // 新しい構造に保存（店舗別のサブコレクション）
      final docRef = _firestore
          .collection('point_requests')
          .doc(storeId)
          .collection(userId)
          .doc('request');
      
      print('Firestore参照パス: ${docRef.path}');
      
      final newRequest = PointRequest(
        id: requestId,
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
      
      print('PointRequestオブジェクト作成完了');
      final jsonData = newRequest.toJson();
      print('JSON変換結果: $jsonData');
      
      // Firebase Consoleの実際のデータ構造に合わせて文字列のまま保存
      print('Firestoreへの保存開始');
      await docRef.set(jsonData);
      print('Firestoreへの保存完了');

      // 売上データを記録（ポイント付与ボタン押下時点）
      final now = DateTime.now();
      await _firestore.collection('sales').add({
        'storeId': storeId,
        'amount': amount,
        'requestId': requestId,
        'source': 'point_request',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': now,
      });
      
      print('ポイント付与リクエストを作成しました: $requestId');
      return requestId;
    } catch (e, stackTrace) {
      print('=== PointRequestNotifier.createPointRequest エラー ===');
      print('エラータイプ: ${e.runtimeType}');
      print('エラーメッセージ: $e');
      print('エラーの詳細: ${e.toString()}');
      print('スタックトレース: $stackTrace');
      
      // より詳細なエラー情報
      if (e is FirebaseException) {
        print('Firebaseエラー詳細:');
        print('  code: ${e.code}');
        print('  message: ${e.message}');
        print('  plugin: ${e.plugin}');
        print('  stackTrace: ${e.stackTrace}');
      }
      
      // その他のエラーの詳細
      if (e is Exception) {
        print('Exception詳細: ${e.toString()}');
      }
      
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
      
      final updateData = {
        'status': status.value,
        'respondedAt': FieldValue.serverTimestamp(),
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };
      
      // 新しい構造を更新（店舗別のサブコレクション）
      await _firestore
          .collection('point_requests')
          .doc(storeId)
          .collection(userId)
          .doc('request')
          .update(updateData);
      
      print('ポイント付与リクエストの状態を更新しました: $requestId -> ${status.value}');
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
