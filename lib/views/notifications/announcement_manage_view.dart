import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/announcement_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import 'create_announcement_view.dart';
import 'announcement_edit_view.dart';

class AnnouncementManageView extends ConsumerWidget {
  const AnnouncementManageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementManageListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: SafeArea(
        child: Column(
          children: [
            const CommonHeader(title: 'お知らせ管理'),
            Expanded(
              child: announcementsAsync.when(
                data: (announcements) {
                  if (announcements.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.announcement, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'お知らせがありません',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '新しいお知らせを作成してみましょう！',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return _buildAnnouncementCard(context, ref, announcement);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('データの取得に失敗しました'),
                    ],
                  ),
                ),
              ),
            ),
            // 新規作成ボタン
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                text: '新規お知らせを作成',
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateAnnouncementView(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, WidgetRef ref, Map<String, dynamic> announcement) {
    // ステータスの判定
    final bool isPublished = announcement['isPublished'] ?? false;
    final bool isActive = announcement['isActive'] ?? true;
    final dynamic scheduledDate = announcement['scheduledDate'];

    String statusText;
    Color statusColor;
    if (isPublished && isActive) {
      statusText = '公開中';
      statusColor = Colors.green;
    } else if (!isPublished && scheduledDate != null) {
      statusText = '予約中';
      statusColor = Colors.orange;
    } else {
      statusText = '非公開';
      statusColor = Colors.grey;
    }

    String formatDate(dynamic timestamp) {
      if (timestamp == null) return '';
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return '';
      }
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AnnouncementEditView(announcement: announcement),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // アイコン
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  child: const Icon(Icons.announcement, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              // 情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ステータスバッジ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // タイトル
                    Text(
                      announcement['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 作成日
                    Text(
                      formatDate(announcement['createdAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 削除ボタン
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                onPressed: () => _showDeleteDialog(context, ref, announcement),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('お知らせを削除'),
          content: const Text('このお知らせを削除しますか？この操作は取り消せません。'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteAnnouncement(context, ref, announcement);
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(BuildContext context, WidgetRef ref, Map<String, dynamic> announcement) async {
    try {
      final announcementService = ref.read(announcementProvider);
      await announcementService.deleteAnnouncement(announcement['id']);
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('エラー'),
            content: Text('お知らせの削除に失敗しました: $e'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
