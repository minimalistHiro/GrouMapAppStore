import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_model.dart' as model;
import '../../providers/notification_provider.dart';

class NotificationDetailView extends ConsumerWidget {
  final model.NotificationModel notification;

  const NotificationDetailView({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsReadAutomatically(ref);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知詳細'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    notification.type.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notification.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              notification.body,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            if (notification.imageUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(notification.imageUrl!),
              ),
            ],
            if (notification.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: notification.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.grey[100],
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _markAsReadAutomatically(WidgetRef ref) {
    if (notification.isRead) return;
    final source = notification.data?['source'] as String?;
    ref.read(notificationProvider).markAsRead(notification.userId, notification.id, source: source);
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}'
        ' ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getNotificationColor(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.ranking:
        return Colors.amber;
      case model.NotificationType.badge:
        return Colors.orange;
      case model.NotificationType.levelUp:
        return Colors.green;
      case model.NotificationType.pointEarned:
        return Colors.teal;
      case model.NotificationType.social:
        return Colors.blue;
      case model.NotificationType.marketing:
        return Colors.purple;
      case model.NotificationType.system:
        return Colors.grey;
      case model.NotificationType.storeAnnouncement:
        return Colors.blue;
      case model.NotificationType.couponUpdate:
        return Colors.orange;
      case model.NotificationType.customerVisit:
        return Colors.green;
    }
  }
}
