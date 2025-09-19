import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';

class AnnouncementDetailView extends ConsumerWidget {
  final Map<String, dynamic> announcement;

  const AnnouncementDetailView({
    Key? key,
    required this.announcement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 画面を開いた時に自動的に既読にする
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsReadAutomatically(context, ref);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ詳細'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareAnnouncement(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カテゴリと優先度のバッジ
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(announcement['category']),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    announcement['category'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(announcement['priority']),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    announcement['priority'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // タイトル
            Text(
              announcement['title'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 公開日時
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(announcement['publishedAt']),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                // 閲覧数
                Icon(
                  Icons.visibility,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${announcement['totalViews']} 回閲覧',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 内容
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                announcement['content'],
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 統計情報
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '統計情報',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('閲覧数', '${announcement['totalViews']} 回'),
                  _buildStatRow('既読数', '${announcement['readCount']} 人'),
                  if (announcement['tags'] != null && (announcement['tags'] as List).isNotEmpty)
                    _buildStatRow('タグ', (announcement['tags'] as List).join(', ')),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markAsReadAutomatically(BuildContext context, WidgetRef ref) {
    // 自動的に既読にする（usersコレクションのreadNotificationsフィールドに追加）
    try {
      final authState = ref.read(authStateProvider);
      authState.whenData((user) async {
        if (user != null) {
          final announcementId = announcement['id'];
          if (announcementId != null) {
            // 現在のユーザーデータを取得
            final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
            final userSnapshot = await userDoc.get();
            
            if (userSnapshot.exists) {
              final userData = userSnapshot.data()!;
              final readNotifications = List<String>.from(userData['readNotifications'] ?? []);
              
              // 既に既読でない場合のみ追加
              if (!readNotifications.contains(announcementId)) {
                readNotifications.add(announcementId);
                await userDoc.update({
                  'readNotifications': readNotifications,
                });
                print('お知らせを自動的に既読にしました: $announcementId');
              }
            }
          }
        }
      });
    } catch (e) {
      print('自動既読処理でエラーが発生しました: $e');
    }
  }

  void _shareAnnouncement(BuildContext context) {
    // シェア機能（実装例）
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お知らせをシェア'),
        content: const Text('シェア機能は準備中です'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '一般':
        return Colors.blue;
      case 'システム':
        return Colors.grey;
      case 'メンテナンス':
        return Colors.orange;
      case 'キャンペーン':
        return Colors.pink;
      case 'アップデート':
        return Colors.green;
      case 'その他':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case '低':
        return Colors.grey;
      case '通常':
        return Colors.blue;
      case '高':
        return Colors.orange;
      case '緊急':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return '日時不明';
    
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '日時不明';
    }
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
