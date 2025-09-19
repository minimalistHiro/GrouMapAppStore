import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

// お知らせサービスプロバイダー
final announcementProvider = Provider<AnnouncementService>((ref) {
  return AnnouncementService();
});

// お知らせ一覧プロバイダー
final announcementsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final announcementService = ref.watch(announcementProvider);
  return announcementService.getAnnouncements()
      .timeout(const Duration(seconds: 5))
      .handleError((error) {
    debugPrint('Announcements provider error: $error');
    return <Map<String, dynamic>>[];
  });
});

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // お知らせ一覧を取得
  Stream<List<Map<String, dynamic>>> getAnnouncements() {
    try {
      return _firestore
          .collection('notifications')
          .where('isActive', isEqualTo: true)
          .where('isPublished', isEqualTo: true)
          .snapshots()
          .timeout(const Duration(seconds: 5))
          .map((snapshot) {
        final announcements = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'notificationId': data['notificationId'] ?? doc.id,
            'title': data['title'] ?? 'タイトルなし',
            'content': data['content'] ?? '内容なし',
            'category': data['category'] ?? '一般',
            'priority': data['priority'] ?? '通常',
            'createdBy': data['createdBy'] ?? '',
            'createdAt': data['createdAt'],
            'publishedAt': data['publishedAt'],
            'readCount': data['readCount'] ?? 0,
            'totalViews': data['totalViews'] ?? 0,
            'tags': data['tags'] ?? <String>[],
          };
        }).toList();
        
        // クライアント側で公開日時順にソート（新しい順）
        announcements.sort((a, b) {
          final aPublishedAt = a['publishedAt'] as Timestamp?;
          final bPublishedAt = b['publishedAt'] as Timestamp?;
          if (aPublishedAt == null && bPublishedAt == null) return 0;
          if (aPublishedAt == null) return 1;
          if (bPublishedAt == null) return -1;
          return bPublishedAt.compareTo(aPublishedAt);
        });
        
        return announcements;
      }).handleError((error) {
        debugPrint('Error in announcements stream: $error');
        if (error.toString().contains('failed-precondition') || 
            error.toString().contains('permission-denied') ||
            error.toString().contains('unavailable')) {
          return <Map<String, dynamic>>[];
        }
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      debugPrint('Error getting announcements: $e');
      return Stream.value([]);
    }
  }

  // お知らせの閲覧数を更新
  Future<void> updateViewCount(String announcementId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(announcementId)
          .update({
        'totalViews': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error updating view count: $e');
    }
  }

  // お知らせの既読数を更新
  Future<void> updateReadCount(String announcementId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(announcementId)
          .update({
        'readCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error updating read count: $e');
    }
  }
}
