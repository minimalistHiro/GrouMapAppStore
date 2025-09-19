import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart' as model;

// 通知サービスプロバイダー
final notificationProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ユーザーの通知一覧プロバイダー
final userNotificationsProvider = StreamProvider.family<List<model.NotificationModel>, String>((ref, userId) {
  final notificationService = ref.watch(notificationProvider);
  return notificationService.getUserNotifications(userId)
      .timeout(const Duration(seconds: 5))
      .handleError((error) {
    debugPrint('User notifications provider error: $error');
    // エラーが発生した場合は空のリストを返す
    return <model.NotificationModel>[];
  });
});

// 未読通知数プロバイダー
final unreadNotificationCountProvider = StreamProvider.family<int, String>((ref, userId) {
  final notificationService = ref.watch(notificationProvider);
  return notificationService.getUnreadNotificationCount(userId);
});

// 通知設定プロバイダー
final notificationSettingsProvider = StreamProvider.family<model.NotificationSettings?, String>((ref, userId) {
  final notificationService = ref.watch(notificationProvider);
  return notificationService.getNotificationSettings(userId);
});

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ユーザーの通知一覧を取得
  Stream<List<model.NotificationModel>> getUserNotifications(String userId) {
    try {
      // インデックスエラーを回避するため、orderByを削除してクライアント側でソート
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .limit(100)
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        final notifications = snapshot.docs.map((doc) {
          try {
            return model.NotificationModel.fromJson({
              'id': doc.id,
              ...doc.data(),
            });
          } catch (e) {
            debugPrint('Error parsing notification document ${doc.id}: $e');
            return null;
          }
        }).where((notification) => notification != null).cast<model.NotificationModel>().toList();
        
        // クライアント側で作成日時順にソート
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return notifications;
      }).handleError((error) {
        debugPrint('Error in notifications stream: $error');
        // インデックスエラーや権限エラーの場合は空のリストを返す
        if (error.toString().contains('failed-precondition') || 
            error.toString().contains('permission-denied') ||
            error.toString().contains('unavailable')) {
          return <model.NotificationModel>[];
        }
        // その他のエラーも空のリストを返す
        return <model.NotificationModel>[];
      });
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      // すべてのエラーに対して空のリストを返す
      return Stream.value([]);
    }
  }

  // 未読通知数を取得
  Stream<int> getUnreadNotificationCount(String userId) {
    try {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      debugPrint('Error getting unread notification count: $e');
      // Firestoreの権限エラーの場合は0を返す
      if (e.toString().contains('permission-denied')) {
        return Stream.value(0);
      }
      return Stream.value(0);
    }
  }

  // 通知設定を取得
  Stream<model.NotificationSettings?> getNotificationSettings(String userId) {
    try {
      return _firestore
          .collection('notification_settings')
          .doc(userId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists) {
          return model.NotificationSettings.fromJson(snapshot.data()!);
        }
        return null;
      });
    } catch (e) {
      debugPrint('Error getting notification settings: $e');
      return Stream.value(null);
    }
  }

  // 通知を作成
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required model.NotificationType type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    List<String> tags = const [],
  }) async {
    try {
      final notification = model.NotificationModel(
        id: _firestore.collection('notifications').doc().id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        tags: tags,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toJson());

      // プッシュ通知を送信
      await _sendPushNotification(notification);
    } catch (e) {
      debugPrint('Error creating notification: $e');
      throw Exception('通知の作成に失敗しました: $e');
    }
  }

  // 通知を既読にする
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      throw Exception('通知の既読化に失敗しました: $e');
    }
  }

  // すべての通知を既読にする
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      throw Exception('すべての通知の既読化に失敗しました: $e');
    }
  }

  // 通知を削除
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      throw Exception('通知の削除に失敗しました: $e');
    }
  }

  // 通知設定を更新
  Future<void> updateNotificationSettings({
    required String userId,
    required model.NotificationSettings settings,
  }) async {
    try {
      await _firestore
          .collection('notification_settings')
          .doc(userId)
          .set(settings.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      throw Exception('通知設定の更新に失敗しました: $e');
    }
  }

  // プッシュ通知を送信
  Future<void> _sendPushNotification(model.NotificationModel notification) async {
    try {
      // 実際のプッシュ通知送信ロジック
      // ここではFirebase Cloud Messagingを使用
      // 注意: sendMessageは実際のプッシュ通知送信には使用されません
      // 実際の実装では、Firebase Admin SDKを使用してサーバー側から送信する必要があります
      debugPrint('Push notification would be sent: ${notification.title}');
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      // プッシュ通知の送信に失敗してもアプリ内通知は作成済みなので、エラーを無視
    }
  }

  // ランキング通知を作成
  Future<void> createRankingNotification({
    required String userId,
    required int rank,
    required String period,
  }) async {
    await createNotification(
      userId: userId,
      title: 'ランキング更新！',
      body: '$periodのランキングで${rank}位になりました！',
      type: model.NotificationType.ranking,
      data: {
        'rank': rank,
        'period': period,
      },
    );
  }

  // バッジ獲得通知を作成
  Future<void> createBadgeNotification({
    required String userId,
    required String badgeName,
    required String badgeDescription,
  }) async {
    await createNotification(
      userId: userId,
      title: '新しいバッジを獲得！',
      body: '$badgeName: $badgeDescription',
      type: model.NotificationType.badge,
      data: {
        'badgeName': badgeName,
        'badgeDescription': badgeDescription,
      },
    );
  }

  // レベルアップ通知を作成
  Future<void> createLevelUpNotification({
    required String userId,
    required int newLevel,
    required List<String> rewards,
  }) async {
    await createNotification(
      userId: userId,
      title: 'レベルアップ！',
      body: 'レベル${newLevel}に到達しました！',
      type: model.NotificationType.levelUp,
      data: {
        'newLevel': newLevel,
        'rewards': rewards,
      },
    );
  }

  // ポイント獲得通知を作成
  Future<void> createPointEarnedNotification({
    required String userId,
    required int points,
    required String source,
  }) async {
    await createNotification(
      userId: userId,
      title: 'ポイント獲得！',
      body: '$sourceで${points}ポイントを獲得しました！',
      type: model.NotificationType.pointEarned,
      data: {
        'points': points,
        'source': source,
      },
    );
  }

}
