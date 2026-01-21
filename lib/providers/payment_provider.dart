import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentProvider extends StateNotifier<PaymentState> {
  PaymentProvider() : super(const PaymentState());

  /// 支払い処理を実行
  Future<PaymentResult> processPayment({
    required String userId,
    required String storeId,
    required int amount,
    required String paymentMethod,
    required String description,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 店舗情報を取得
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      if (!storeDoc.exists) {
        throw Exception('店舗情報が見つかりません');
      }

      final storeData = storeDoc.data()!;
      final storeName = storeData['name'] ?? '店舗名不明';

      // ユーザー情報を取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('ユーザー情報が見つかりません');
      }

      final userData = userDoc.data()!;
      final userName = userData['displayName'] ?? userData['email'] ?? 'お客様';

      // 付与ポイントを計算（100円で1ポイント）
      final pointsToAward = amount ~/ 100;

      // 取引IDを生成
      final transactionId = FirebaseFirestore.instance.collection('transactions').doc().id;
      final now = DateTime.now();

      // 取引履歴を作成
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(transactionId)
          .set({
        'transactionId': transactionId,
        'userId': userId,
        'userName': userName,
        'storeId': storeId,
        'storeName': storeName,
        'amount': amount,
        'pointsAwarded': pointsToAward,
        'paymentMethod': paymentMethod,
        'status': 'completed',
        'description': description,
        'createdAt': now,
        'updatedAt': now,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ユーザーのポイントを更新
      if (pointsToAward > 0) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'points': FieldValue.increment(pointsToAward),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // ポイント履歴を記録
      if (pointsToAward > 0) {
        await _recordPointHistory(
          userId: userId,
          storeId: storeId,
          points: pointsToAward,
          reason: '支払いによるポイント付与',
          transactionId: transactionId,
        );
      }

      // 店舗の統計を更新
      await _updateStoreStats(storeId, amount, pointsToAward);

      // 売上データを記録
      await _recordSalesData(storeId, amount, transactionId);

      // 統一取引ログを記録
      await _recordStoreTransaction(
        transactionId: transactionId,
        userId: userId,
        userName: userName,
        storeId: storeId,
        storeName: storeName,
        amountYen: amount,
        pointsAwarded: pointsToAward,
        paymentMethod: paymentMethod,
        source: 'store_payment',
      );

      state = state.copyWith(
        isLoading: false,
        lastTransactionId: transactionId,
        lastAmount: amount,
        lastPointsAwarded: pointsToAward,
      );

      return PaymentResult.success(
        transactionId: transactionId,
        amount: amount,
        pointsAwarded: pointsToAward,
        userName: userName,
        storeName: storeName,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return PaymentResult.error(e.toString());
    }
  }

  /// ポイント履歴を記録
  Future<void> _recordPointHistory({
    required String userId,
    required String storeId,
    required int points,
    required String reason,
    required String transactionId,
  }) async {
    await FirebaseFirestore.instance
        .collection('point_history')
        .add({
      'userId': userId,
      'storeId': storeId,
      'points': points,
      'type': 'earned',
      'reason': reason,
      'transactionId': transactionId,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': DateTime.now(),
    });
  }

  /// 店舗の統計を更新
  Future<void> _updateStoreStats(String storeId, int amount, int pointsAwarded) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await FirebaseFirestore.instance
        .collection('store_stats')
        .doc(storeId)
        .collection('daily')
        .doc(todayStr)
        .set({
      'date': todayStr,
      'totalSales': FieldValue.increment(amount),
      'totalPointsAwarded': FieldValue.increment(pointsAwarded),
      'pointsIssued': FieldValue.increment(pointsAwarded),
      'totalTransactions': FieldValue.increment(1),
      'visitorCount': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 売上データを記録
  Future<void> _recordSalesData(String storeId, int amount, String transactionId) async {
    await FirebaseFirestore.instance
        .collection('sales')
        .add({
      'storeId': storeId,
      'amount': amount,
      'transactionId': transactionId,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': DateTime.now(),
    });
  }

  Future<void> _recordStoreTransaction({
    required String transactionId,
    required String userId,
    required String userName,
    required String storeId,
    required String storeName,
    required int amountYen,
    required int pointsAwarded,
    required String paymentMethod,
    required String source,
  }) async {
    await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .collection('transactions')
        .doc(transactionId)
        .set({
      'transactionId': transactionId,
      'storeId': storeId,
      'storeName': storeName,
      'userId': userId,
      'userName': userName,
      'type': 'sale',
      'amountYen': amountYen,
      'points': pointsAwarded,
      'paymentMethod': paymentMethod,
      'status': 'completed',
      'source': source,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': DateTime.now(),
    });
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

class PaymentState {
  final bool isLoading;
  final String? error;
  final String? lastTransactionId;
  final int? lastAmount;
  final int? lastPointsAwarded;

  const PaymentState({
    this.isLoading = false,
    this.error,
    this.lastTransactionId,
    this.lastAmount,
    this.lastPointsAwarded,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    String? lastTransactionId,
    int? lastAmount,
    int? lastPointsAwarded,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastTransactionId: lastTransactionId ?? this.lastTransactionId,
      lastAmount: lastAmount ?? this.lastAmount,
      lastPointsAwarded: lastPointsAwarded ?? this.lastPointsAwarded,
    );
  }
}

class PaymentResult {
  final bool isSuccess;
  final String? error;
  final String? transactionId;
  final int? amount;
  final int? pointsAwarded;
  final String? userName;
  final String? storeName;

  const PaymentResult._({
    required this.isSuccess,
    this.error,
    this.transactionId,
    this.amount,
    this.pointsAwarded,
    this.userName,
    this.storeName,
  });

  factory PaymentResult.success({
    required String transactionId,
    required int amount,
    required int pointsAwarded,
    required String userName,
    required String storeName,
  }) {
    return PaymentResult._(
      isSuccess: true,
      transactionId: transactionId,
      amount: amount,
      pointsAwarded: pointsAwarded,
      userName: userName,
      storeName: storeName,
    );
  }

  factory PaymentResult.error(String error) {
    return PaymentResult._(
      isSuccess: false,
      error: error,
    );
  }
}

final paymentProvider = StateNotifierProvider<PaymentProvider, PaymentState>((ref) {
  return PaymentProvider();
});
