import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart' as model;
import '../../widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'announcement_detail_view.dart';
import 'notification_detail_view.dart';

// ユーザーデータプロバイダー（usersコレクションから直接取得）
final userDataProvider = StreamProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, userId) {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      return Stream.value(null);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    }).handleError((error) {
      debugPrint('Error fetching user data: $error');
      return null;
    });
  } catch (e) {
    debugPrint('Error creating user data stream: $e');
    return Stream.value(null);
  }
});

// 統合通知アイテム
class _UnifiedNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime dateTime;
  final bool isRead;
  // 元データへの参照（詳細遷移用）
  final Map<String, dynamic>? announcementData;
  final model.NotificationModel? notificationData;

  _UnifiedNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.dateTime,
    required this.isRead,
    this.announcementData,
    this.notificationData,
  });

  bool get isAnnouncement => announcementData != null;
}

class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(announcementsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: authState.when(
        data: (user) {
          if (user != null) {
            return _buildUnifiedList(context, ref, user.uid);
          } else {
            return const Center(
              child: Text('ログインが必要です'),
            );
          }
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  Widget _buildUnifiedList(BuildContext context, WidgetRef ref, String userId) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider(userId));
    final userDataAsync = ref.watch(userDataProvider(userId));

    // 両方のデータがロード中の場合
    if (announcementsAsync.isLoading && notificationsAsync.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('読み込み中...'),
          ],
        ),
      );
    }

    // エラーチェック（両方エラーの場合のみエラー表示）
    if (announcementsAsync.hasError && notificationsAsync.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '読み込めませんでした',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ネットワーク接続を確認してください',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(announcementsProvider);
                ref.invalidate(userNotificationsProvider(userId));
              },
            ),
          ],
        ),
      );
    }

    final announcements = announcementsAsync.valueOrNull ?? [];
    final notifications = notificationsAsync.valueOrNull ?? [];
    final readNotifications = List<String>.from(
      userDataAsync.valueOrNull?['readNotifications'] ?? [],
    );

    // 統合リストを構築
    final unifiedItems = <_UnifiedNotificationItem>[];

    // お知らせを変換
    for (final announcement in announcements) {
      final publishedAt = announcement['publishedAt'];
      DateTime dateTime;
      if (publishedAt is Timestamp) {
        dateTime = publishedAt.toDate();
      } else {
        dateTime = DateTime.now();
      }

      unifiedItems.add(_UnifiedNotificationItem(
        id: announcement['id'] ?? '',
        title: announcement['title'] ?? 'タイトルなし',
        body: announcement['content'] ?? '',
        dateTime: dateTime,
        isRead: readNotifications.contains(announcement['id']),
        announcementData: announcement,
      ));
    }

    // 通知を変換
    for (final notification in notifications) {
      unifiedItems.add(_UnifiedNotificationItem(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        dateTime: notification.createdAt,
        isRead: notification.isRead,
        notificationData: notification,
      ));
    }

    // 日時で降順ソート
    unifiedItems.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    if (unifiedItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('お知らせはありません'),
            SizedBox(height: 8),
            Text(
              '新しいお知らせがあるとここに表示されます',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: unifiedItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = unifiedItems[index];
        return _buildListItem(context, item);
      },
    );
  }

  Widget _buildListItem(BuildContext context, _UnifiedNotificationItem item) {
    return Container(
      color: item.isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: item.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(item.dateTime),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          if (item.isAnnouncement) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AnnouncementDetailView(
                  announcement: item.announcementData!,
                ),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NotificationDetailView(
                  notification: item.notificationData!,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}
