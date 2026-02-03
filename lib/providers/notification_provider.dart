import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart' as model;

// 通知サービスプロバイダー
final notificationProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ユーザーの通知一覧プロバイダー
final userNotificationsProvider = StreamProvider.autoDispose.family<List<model.NotificationModel>, String>((ref, userId) {
  final notificationService = ref.watch(notificationProvider);
  return notificationService.getUserNotifications(userId);
});

// 未読通知数プロバイダー
final unreadNotificationCountProvider = StreamProvider.autoDispose.family<int, String>((ref, userId) {
  final notificationService = ref.watch(notificationProvider);
  return notificationService.getUnreadNotificationCount(userId);
});

// 通知設定プロバイダー
final notificationSettingsProvider = StreamProvider.autoDispose.family<model.NotificationSettings?, String>((ref, userId) {
  final notificationService = ref.watch(notificationProvider);
  return notificationService.getNotificationSettings(userId);
});

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ユーザーの通知一覧を取得
  Stream<List<model.NotificationModel>> getUserNotifications(String userId) {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        return Stream.value([]);
      }
      // インデックスエラーを回避するため、orderByを削除してクライアント側でソート
      final controller = StreamController<List<model.NotificationModel>>.broadcast();
      List<model.NotificationModel> topLevel = [];
      List<model.NotificationModel> userScoped = [];

      void emitMerged() {
        final merged = [...topLevel, ...userScoped];
        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(merged);
      }

      final topLevelSub = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .limit(100)
          .snapshots()
          .listen((snapshot) {
        topLevel = _parseNotificationsSnapshot(snapshot, source: 'global');
        emitMerged();
      }, onError: (error) {
        debugPrint('Error in top-level notifications stream: $error');
        emitMerged();
      });

      final userScopedSub = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .limit(100)
          .snapshots()
          .listen((snapshot) {
        userScoped = _parseNotificationsSnapshot(snapshot, source: 'user');
        emitMerged();
      }, onError: (error) {
        debugPrint('Error in user notifications stream: $error');
        emitMerged();
      });

      controller.onCancel = () {
        topLevelSub.cancel();
        userScopedSub.cancel();
        controller.close();
      };

      return controller.stream;
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      // すべてのエラーに対して空のリストを返す
      return Stream.value([]);
    }
  }

  // 未読通知数を取得
  Stream<int> getUnreadNotificationCount(String userId) {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        return Stream.value(0);
      }
      final controller = StreamController<int>.broadcast();
      int topCount = 0;
      int userCount = 0;

      void emitCount() {
        controller.add(topCount + userCount);
      }

      final topSub = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        topCount = snapshot.docs.length;
        emitCount();
      }, onError: (error) {
        debugPrint('Error getting top-level unread count: $error');
        topCount = 0;
        emitCount();
      });

      final userSub = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        userCount = snapshot.docs.length;
        emitCount();
      }, onError: (error) {
        debugPrint('Error getting user unread count: $error');
        userCount = 0;
        emitCount();
      });

      controller.onCancel = () {
        topSub.cancel();
        userSub.cancel();
        controller.close();
      };

      return controller.stream;
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

  // ユーザー配下の通知を作成
  Future<void> createUserNotification({
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
      final notificationId = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc()
          .id;
      final notification = model.NotificationModel(
        id: notificationId,
        userId: userId,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        data: {
          'source': 'user',
          ...?data,
        },
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        tags: tags,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toJson());
    } catch (e) {
      debugPrint('Error creating user notification: $e');
      throw Exception('通知の作成に失敗しました: $e');
    }
  }

  // 通知を既読にする
  Future<void> markAsRead(String userId, String notificationId, {String? source}) async {
    try {
      final resolvedSource = source ?? 'global';
      debugPrint('通知既読更新: id=$notificationId, userId=$userId, source=$resolvedSource');
      if (resolvedSource == 'user') {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      } else {
        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        // source が不正な場合に備えて反対側へフォールバック更新
        try {
          if (source == 'user') {
            await _firestore
                .collection('notifications')
                .doc(notificationId)
                .update({'isRead': true});
          } else {
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .doc(notificationId)
                .update({'isRead': true});
          }
          debugPrint('通知既読更新: not-found フォールバック成功 id=$notificationId');
          return;
        } catch (fallbackError) {
          debugPrint('通知既読更新: フォールバック失敗 id=$notificationId, error=$fallbackError');
          rethrow;
        }
      }
      rethrow;
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

      final userScopedNotifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in userScopedNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      throw Exception('すべての通知の既読化に失敗しました: $e');
    }
  }

  // 通知を削除
  Future<void> deleteNotification(String userId, String notificationId, {String? source}) async {
    try {
      final resolvedSource = source ?? 'global';
      if (resolvedSource == 'user') {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .delete();
      } else {
        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .delete();
      }
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

  List<model.NotificationModel> _parseNotificationsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    required String source,
  }) {
    final notifications = snapshot.docs.map((doc) {
      try {
        final data = doc.data();
        final rawType = data['type'];
        final normalizedType = rawType == 'store_request' ? 'store_announcement' : rawType;
        final rawCreatedAt = data['createdAt'];
        String? createdAtIso;
        if (rawCreatedAt is Timestamp) {
          createdAtIso = rawCreatedAt.toDate().toIso8601String();
        } else if (rawCreatedAt is DateTime) {
          createdAtIso = rawCreatedAt.toIso8601String();
        } else if (rawCreatedAt is String) {
          createdAtIso = rawCreatedAt;
        }
        final mergedData = {
          ...data,
          'type': normalizedType,
          if (createdAtIso != null) 'createdAt': createdAtIso,
          'data': {
            'source': source,
            ...?(data['data'] as Map<String, dynamic>?),
          },
        };
        return model.NotificationModel.fromJson({
          'id': doc.id,
          ...mergedData,
        });
      } catch (e) {
        debugPrint('Error parsing notification document ${doc.id}: $e');
        return null;
      }
    }).where((notification) => notification != null).cast<model.NotificationModel>().toList();
    return notifications;
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
