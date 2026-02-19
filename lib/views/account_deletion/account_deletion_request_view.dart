import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/account_deletion_provider.dart';
import '../../widgets/custom_button.dart';

class AccountDeletionRequestView extends ConsumerStatefulWidget {
  const AccountDeletionRequestView({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountDeletionRequestView> createState() =>
      _AccountDeletionRequestViewState();
}

class _AccountDeletionRequestViewState
    extends ConsumerState<AccountDeletionRequestView> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final storeIdAsync = ref.watch(userStoreIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント削除申請'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: storeIdAsync.when(
        data: (storeId) {
          if (user == null || storeId == null) {
            return const Center(child: Text('店舗情報が取得できません'));
          }
          final storeDataAsync = ref.watch(storeDataProvider(storeId));
          return storeDataAsync.when(
            data: (storeData) {
              if (storeData == null) {
                return const Center(child: Text('店舗情報が取得できません'));
              }
              return _buildForm(context, user.uid, storeId, storeData);
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('エラーが発生しました')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('エラーが発生しました')),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    String userId,
    String storeId,
    Map<String, dynamic> storeData,
  ) {
    final storeName = storeData['name'] as String? ?? '店舗名未設定';
    final storeCategory = storeData['category'] as String? ?? 'その他';
    final storeIconImageUrl = storeData['iconImageUrl'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 警告ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'アカウント削除申請を行うと、管理者による審査後に店舗が無効化されます。この操作は管理者の承認が必要です。',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 店舗情報表示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: storeIconImageUrl != null
                        ? NetworkImage(storeIconImageUrl)
                        : null,
                    child: storeIconImageUrl == null
                        ? Icon(Icons.store,
                            color: Colors.grey[600], size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 4),
                        Text(
                          storeCategory,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 退会理由
            const Text(
              '退会を希望する理由',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: '退会の理由をご記入ください',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '退会理由を入力してください';
                }
                if (value.trim().length < 10) {
                  return '退会理由は10文字以上で入力してください';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // 送信ボタン
            CustomButton(
              text: _isSubmitting ? '送信中...' : '送信する',
              onPressed: _isSubmitting
                  ? null
                  : () => _submitRequest(
                        context,
                        userId,
                        storeId,
                        storeName,
                        storeIconImageUrl,
                        storeCategory,
                      ),
              backgroundColor: Colors.red,
              textColor: Colors.white,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest(
    BuildContext context,
    String userId,
    String storeId,
    String storeName,
    String? storeIconImageUrl,
    String storeCategory,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(accountDeletionProvider).submitDeletionRequest(
            storeId: storeId,
            storeName: storeName,
            storeIconImageUrl: storeIconImageUrl,
            storeCategory: storeCategory,
            userId: userId,
            reason: _reasonController.text.trim(),
          );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('申請完了'),
            content: const Text(
              'アカウント削除申請を送信しました。\n管理者が確認後、処理いたします。',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
