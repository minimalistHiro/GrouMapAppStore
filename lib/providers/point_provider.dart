import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PointProvider extends StateNotifier<PointState> {
  PointProvider() : super(const PointState());

  /// ユーザーにポイントを付与
  Future<PointResult> awardPoints({
    required String userId,
    required String storeId,
    required int points,
    required String reason,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // ユーザーの現在のポイントを取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('ユーザーが見つかりません');
      }

      final userData = userDoc.data()!;
      final currentPoints = userData['points'] ?? 0;
      final newPoints = currentPoints + points;

      // ユーザーのポイントを更新
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'points': newPoints,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // ポイント履歴を記録
      await _recordPointHistory(
        userId: userId,
        storeId: storeId,
        points: points,
        reason: reason,
        type: 'earned',
      );

      // 店舗の統計を更新
      await _updateStoreStats(storeId, points);

      state = state.copyWith(
        isLoading: false,
        lastAwardedPoints: points,
        lastAwardedUserId: userId,
      );

      return PointResult.success(
        userId: userId,
        pointsAwarded: points,
        newTotalPoints: newPoints,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return PointResult.error(e.toString());
    }
  }

  /// ポイント履歴を記録
  Future<void> _recordPointHistory({
    required String userId,
    required String storeId,
    required int points,
    required String reason,
    required String type,
  }) async {
    await FirebaseFirestore.instance
        .collection('point_history')
        .add({
      'userId': userId,
      'storeId': storeId,
      'points': points,
      'type': type, // 'earned', 'spent', 'expired'
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': DateTime.now(),
    });
  }

  /// 店舗の統計を更新
  Future<void> _updateStoreStats(String storeId, int points) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await FirebaseFirestore.instance
        .collection('store_stats')
        .doc(storeId)
        .collection('daily')
        .doc(todayStr)
        .set({
      'date': todayStr,
      'totalPointsAwarded': FieldValue.increment(points),
      'pointsIssued': FieldValue.increment(points),
      'totalVisits': FieldValue.increment(1),
      'visitorCount': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

class PointState {
  final bool isLoading;
  final String? error;
  final int? lastAwardedPoints;
  final String? lastAwardedUserId;

  const PointState({
    this.isLoading = false,
    this.error,
    this.lastAwardedPoints,
    this.lastAwardedUserId,
  });

  PointState copyWith({
    bool? isLoading,
    String? error,
    int? lastAwardedPoints,
    String? lastAwardedUserId,
  }) {
    return PointState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastAwardedPoints: lastAwardedPoints ?? this.lastAwardedPoints,
      lastAwardedUserId: lastAwardedUserId ?? this.lastAwardedUserId,
    );
  }
}

class PointResult {
  final bool isSuccess;
  final String? error;
  final String? userId;
  final int? pointsAwarded;
  final int? newTotalPoints;

  const PointResult._({
    required this.isSuccess,
    this.error,
    this.userId,
    this.pointsAwarded,
    this.newTotalPoints,
  });

  factory PointResult.success({
    required String userId,
    required int pointsAwarded,
    required int newTotalPoints,
  }) {
    return PointResult._(
      isSuccess: true,
      userId: userId,
      pointsAwarded: pointsAwarded,
      newTotalPoints: newTotalPoints,
    );
  }

  factory PointResult.error(String error) {
    return PointResult._(
      isSuccess: false,
      error: error,
    );
  }
}

final pointProvider = StateNotifierProvider<PointProvider, PointState>((ref) {
  return PointProvider();
});
