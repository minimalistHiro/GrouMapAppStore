import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feedback_provider.dart';
import '../../widgets/custom_button.dart';

class FeedbackSendView extends ConsumerStatefulWidget {
  const FeedbackSendView({Key? key}) : super(key: key);

  @override
  ConsumerState<FeedbackSendView> createState() => _FeedbackSendViewState();
}

class _FeedbackSendViewState extends ConsumerState<FeedbackSendView> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedCategory = 'general';
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'value': 'general', 'label': '一般的なフィードバック'},
    {'value': 'bug', 'label': 'バグ報告'},
    {'value': 'feature', 'label': '機能要望'},
    {'value': 'ui', 'label': 'UI/UX改善'},
    {'value': 'performance', 'label': 'パフォーマンス'},
    {'value': 'other', 'label': 'その他'},
  ];

  @override
  void initState() {
    super.initState();
    // ユーザー情報を取得してメールアドレスを設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider);
      authState.whenData((user) {
        if (user != null && user.email != null) {
          _emailController.text = user.email!;
        }
      });
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('フィードバック送信'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ログインが必要です'),
            );
          }
          return _buildFeedbackForm(context, ref, user.uid, user.displayName ?? 'ユーザー');
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildFeedbackForm(BuildContext context, WidgetRef ref, String userId, String userName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'フィードバックを送信',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'アプリの改善のため、ご意見・ご要望をお聞かせください。',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // カテゴリ選択
            const Text(
              'カテゴリ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['value'],
                      child: Text(category['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 件名
            const Text(
              '件名',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: '件名を入力してください',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '件名を入力してください';
                }
                if (value.trim().length < 3) {
                  return '件名は3文字以上で入力してください';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // メールアドレス
            const Text(
              'メールアドレス',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'メールアドレスを入力してください',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'メールアドレスを入力してください';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                  return '有効なメールアドレスを入力してください';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // メッセージ
            const Text(
              'メッセージ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'フィードバックの内容を詳しく入力してください',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'メッセージを入力してください';
                }
                if (value.trim().length < 10) {
                  return 'メッセージは10文字以上で入力してください';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // 送信ボタン
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: _isSubmitting ? '送信中...' : 'フィードバックを送信',
                onPressed: _isSubmitting ? () {} : () => _submitFeedback(context, ref, userId, userName),
              ),
            ),

            const SizedBox(height: 16),

            // 注意事項
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '注意事項',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• フィードバックは開発チームに送信されます\n'
                    '• 回答が必要な場合は、メールアドレスにご連絡いたします\n'
                    '• 不適切な内容は削除される場合があります',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback(BuildContext context, WidgetRef ref, String userId, String userName) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(feedbackProvider).submitFeedback(
        userId: userId,
        userName: userName,
        userEmail: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        category: _selectedCategory,
      );

      if (mounted) {
        // 成功ダイアログを表示
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('送信完了'),
            content: const Text('フィードバックを送信しました。\nご協力ありがとうございます。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // フィードバック画面も閉じる
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
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
