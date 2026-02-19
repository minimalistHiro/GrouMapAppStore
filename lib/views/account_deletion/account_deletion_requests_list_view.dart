import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/account_deletion_provider.dart';

class AccountDeletionRequestsListView extends ConsumerStatefulWidget {
  const AccountDeletionRequestsListView({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountDeletionRequestsListView> createState() =>
      _AccountDeletionRequestsListViewState();
}

class _AccountDeletionRequestsListViewState
    extends ConsumerState<AccountDeletionRequestsListView> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(deletionRequestListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント削除申請'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'アカウント削除申請はありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final pendingRequests =
              requests.where((r) => r['status'] == 'pending').toList();
          final approvedRequests =
              requests.where((r) => r['status'] == 'approved').toList();
          final rejectedRequests =
              requests.where((r) => r['status'] == 'rejected').toList();

          return Column(
            children: [
              // 統計ヘッダー
              _buildStatsHeader(
                  pendingRequests.length, approvedRequests.length, rejectedRequests.length),
              // リスト
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(requests[index]);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(int pendingCount, int approvedCount, int rejectedCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              '未処理',
              pendingCount.toString(),
              Colors.orange,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
            child: _buildStatItem(
              '承認済み',
              approvedCount.toString(),
              Colors.green,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
            child: _buildStatItem(
              '拒否',
              rejectedCount.toString(),
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final storeName = request['storeName'] as String? ?? '店舗名未設定';
    final storeCategory = request['storeCategory'] as String? ?? 'その他';
    final storeIconImageUrl = request['storeIconImageUrl'] as String?;
    final reason = request['reason'] as String? ?? '';
    final status = request['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final createdAt = request['createdAt'] as Timestamp?;

    String dateStr = '';
    if (createdAt != null) {
      final dt = createdAt.toDate();
      dateStr = '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 店舗情報行
            Row(
              children: [
                // 店舗アイコン
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: storeIconImageUrl != null
                      ? NetworkImage(storeIconImageUrl)
                      : null,
                  child: storeIconImageUrl == null
                      ? Icon(Icons.store, color: Colors.grey[600], size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                // 店舗名・カテゴリ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        storeCategory,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // ステータスバッジ
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withOpacity(0.1)
                        : status == 'rejected'
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPending ? '未処理' : status == 'rejected' ? '拒否' : '承認済み',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPending
                          ? Colors.orange[700]
                          : status == 'rejected'
                              ? Colors.red[700]
                              : Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // 退会理由
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
                height: 1.4,
              ),
            ),

            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '申請日: $dateStr',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],

            // 承認・拒否ボタン（未処理の場合のみ）
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isProcessing ? null : () => _rejectRequest(request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '拒否する',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isProcessing ? null : () => _approveRequest(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '退会を承認する',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    final storeName = request['storeName'] as String? ?? '店舗名未設定';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('拒否の確認'),
        content: Text(
          '$storeName のアカウント削除申請を拒否しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('拒否する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      await ref.read(accountDeletionProvider).rejectDeletionRequest(
            request['id'] as String,
            currentUser?.uid ?? '',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$storeName の削除申請を拒否しました'),
            backgroundColor: Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('処理に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    final storeName = request['storeName'] as String? ?? '店舗名未設定';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('承認の確認'),
        content: Text(
          '$storeName のアカウント削除申請を承認しますか？\n\n店舗は無効化されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('承認する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      await ref.read(accountDeletionProvider).approveDeletionRequest(
            request['id'] as String,
            request['storeId'] as String,
            currentUser?.uid ?? '',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$storeName を無効化しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('処理に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
