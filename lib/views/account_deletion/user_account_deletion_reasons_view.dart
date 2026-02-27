import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/account_deletion_provider.dart';
import '../../widgets/common_header.dart';

class UserAccountDeletionReasonsView extends ConsumerStatefulWidget {
  const UserAccountDeletionReasonsView({super.key});

  @override
  ConsumerState<UserAccountDeletionReasonsView> createState() =>
      _UserAccountDeletionReasonsViewState();
}

class _UserAccountDeletionReasonsViewState
    extends ConsumerState<UserAccountDeletionReasonsView> {
  final Set<String> _processingIds = <String>{};

  Future<void> _markAsRead(String requestId) async {
    if (_processingIds.contains(requestId)) return;

    setState(() => _processingIds.add(requestId));
    try {
      final ownerUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await ref.read(accountDeletionProvider).markUserDeletionReasonAsRead(
            requestId: requestId,
            processedByUid: ownerUid,
          );
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('既読更新に失敗しました'),
          content: Text('通信環境を確認して再度お試しください。\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(requestId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasonsAsync = ref.watch(userDeletionReasonListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: const CommonHeader(
        title: 'ユーザー退会理由一覧',
      ),
      body: reasonsAsync.when(
        data: (reasons) {
          if (reasons.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 52,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'ユーザーの退会理由はまだありません',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final unreadCount =
              reasons.where((item) => item['readByOwnerAt'] == null).length;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reasons.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSummaryCard(reasons.length, unreadCount);
              }
              final item = reasons[index - 1];
              return _buildReasonCard(item);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text(
            '読み込みに失敗しました: $error',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int count, int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '退会理由件数: $count 件（未読: $unreadCount 件）',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonCard(Map<String, dynamic> data) {
    final displayName = _safeString(data['userDisplayName']) ?? 'ユーザー';
    final username = _safeString(data['username']);
    final userEmail = _safeString(data['userEmail']) ?? 'メール未設定';
    final userId = _safeString(data['userId']) ?? '-';
    final reason = _safeString(data['reason']) ?? '（理由未入力）';
    final profileImageUrl = _safeString(data['userProfileImageUrl']);
    final requestId = _safeString(data['id']);
    final createdAt = data['createdAt'] as Timestamp?;
    final readByOwnerAt = data['readByOwnerAt'] as Timestamp?;
    final isUnread = readByOwnerAt == null;
    final isUpdatingRead =
        requestId != null && _processingIds.contains(requestId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username != null ? '@$username' : 'ユーザーID未設定',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUnread
                      ? Colors.red.withOpacity(0.12)
                      : Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isUnread ? '未読' : '既読',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUnread ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'UID: $userId',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '退会日時: ${_formatDate(createdAt)}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          if (!isUnread) ...[
            const SizedBox(height: 4),
            Text(
              '既読日時: ${_formatDate(readByOwnerAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            '退会理由',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (isUnread && requestId != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isUpdatingRead ? null : () => _markAsRead(requestId),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: isUpdatingRead
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('既読にする'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final dt = timestamp.toDate();
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $h:$min';
  }

  String? _safeString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
