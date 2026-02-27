import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';
import 'account_deletion_provider.dart';

// 未承認店舗数プロバイダー
final pendingStoresCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('stores')
      .snapshots()
      .map((snapshot) {
    int count = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final isApproved = data['isApproved'] ?? false;
      final status = data['approvalStatus'] ?? 'pending';
      if (!isApproved && status == 'pending') {
        count++;
      }
    }
    return count;
  });
});

// 未読ライブチャット数プロバイダー
final unreadLiveChatCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collectionGroup('messages')
      .where('senderRole', isEqualTo: 'user')
      .where('readByOwnerAt', isNull: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.length)
      .handleError((_) => 0);
});

// 未確認フィードバック数プロバイダー
final pendingFeedbackCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('feedback')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs.length)
      .handleError((_) => 0);
});

// 設定画面の表示中項目のバッジ合計プロバイダー
// 新しい設定項目にバッジを追加した場合は、ここにもカウントを追加すること
final settingsTotalBadgeCountProvider = Provider<int>((ref) {
  final isAdminOwner = ref.watch(userIsAdminOwnerProvider).maybeWhen(
        data: (v) => v,
        orElse: () => false,
      );

  int total = 0;

  // オーナー管理セクションのバッジ（管理者オーナーのみ表示）
  if (isAdminOwner) {
    total += ref.watch(pendingStoresCountProvider).maybeWhen(
          data: (v) => v,
          orElse: () => 0,
        );
    total += ref.watch(unreadLiveChatCountProvider).maybeWhen(
          data: (v) => v,
          orElse: () => 0,
        );
    total += ref.watch(pendingDeletionRequestsCountProvider).maybeWhen(
          data: (v) => v,
          orElse: () => 0,
        );
    total += ref.watch(pendingFeedbackCountProvider).maybeWhen(
          data: (v) => v,
          orElse: () => 0,
        );
    total += ref.watch(unreadUserDeletionReasonsCountProvider);
  }

  // 全ユーザー共通セクションのバッジ
  // 今後、新しいバッジカウントを追加する場合はここに追記

  return total;
});
