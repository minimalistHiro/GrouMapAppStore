import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/store_provider.dart';

class TodayVisitorsView extends ConsumerWidget {
  const TodayVisitorsView({Key? key, required this.storeId}) : super(key: key);

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の訪問者'),
      ),
      body: ref.watch(todayVisitorsProvider(storeId)).when(
            data: (visitors) {
              if (visitors.isEmpty) {
                return const Center(
                  child: Text(
                    '今日の訪問者はいません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: visitors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final visitor = visitors[index];
                  return _VisitorListItem(visitor: visitor);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
            error: (error, _) => const Center(
              child: Text(
                '訪問者情報の取得に失敗しました',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ),
    );
  }
}

class _VisitorListItem extends StatelessWidget {
  const _VisitorListItem({required this.visitor});

  final Map<String, dynamic> visitor;

  String _formatVisitTime() {
    try {
      final timestamp = visitor['timestamp'];
      if (timestamp == null) return '時間不明';

      final date = timestamp is DateTime ? timestamp : (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(date).inMinutes;

      if (difference < 1) return 'たった今';
      if (difference < 60) return '${difference}分前';
      if (difference < 1440) return '${(difference / 60).floor()}時間前';

      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '時間不明';
    }
  }

  Widget _buildAvatar() {
    final photoUrl = visitor['userPhotoUrl'];
    if (photoUrl is String && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Container(
          width: 44,
          height: 44,
          color: Colors.grey[200],
          child: Image.network(
            photoUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 44,
                height: 44,
                color: Colors.blue[100],
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: 24,
                ),
              );
            },
          ),
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.blue[100],
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.blue,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = visitor['userName'] ?? 'ゲストユーザー';
    final pointsEarned = visitor['pointsEarned'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatVisitTime(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+$pointsEarned pt',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
