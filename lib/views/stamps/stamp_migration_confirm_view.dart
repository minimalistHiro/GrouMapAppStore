import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../widgets/common_header.dart';
import 'stamp_migration_complete_view.dart';

class StampMigrationConfirmView extends StatefulWidget {
  final String userId;
  final String storeId;
  final Map<String, dynamic> userProfile;
  final int currentStamps;

  const StampMigrationConfirmView({
    super.key,
    required this.userId,
    required this.storeId,
    required this.userProfile,
    required this.currentStamps,
  });

  @override
  State<StampMigrationConfirmView> createState() =>
      _StampMigrationConfirmViewState();
}

class _StampMigrationConfirmViewState
    extends State<StampMigrationConfirmView> {
  final _stampCountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _previewStampsAfter = 0;

  @override
  void initState() {
    super.initState();
    _previewStampsAfter = widget.currentStamps;
    _stampCountController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _stampCountController.removeListener(_updatePreview);
    _stampCountController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final value = int.tryParse(_stampCountController.text) ?? 0;
    setState(() {
      _previewStampsAfter = widget.currentStamps + value;
    });
  }

  int get _completedCardsPreview {
    int count = 0;
    for (int s = widget.currentStamps + 1; s <= _previewStampsAfter; s++) {
      if (s % 10 == 0) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        (widget.userProfile['displayName'] as String?) ?? 'お客様';
    final profileImageUrl = widget.userProfile['profileImageUrl'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: const CommonHeader(title: '物理スタンプカード移行'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserCard(displayName, profileImageUrl),
              const SizedBox(height: 16),
              _buildWarningCard(),
              const SizedBox(height: 16),
              _buildCurrentStampsCard(),
              const SizedBox(height: 16),
              _buildStampInputCard(),
              if (_stampCountController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPreviewCard(),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _confirmAndMigrate,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '移行を実行する',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(String displayName, String? profileImageUrl) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFFF6B35),
              backgroundImage:
                  profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
              child: profileImageUrl == null || profileImageUrl.isEmpty
                  ? Text(
                      displayName.isNotEmpty ? displayName[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '移行対象ユーザー',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '物理スタンプカードを目視確認した上で移行してください。\n移行は1ユーザーにつき1回のみ実行できます。',
              style: TextStyle(fontSize: 13, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStampsCard() {
    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('現在のデジタルスタンプ数', style: TextStyle(fontSize: 15)),
            Text(
              '${widget.currentStamps} 個',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampInputCard() {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '物理カードのスタンプ数を入力',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stampCountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: const InputDecoration(
                labelText: 'スタンプ数（1〜99）',
                hintText: '例: 7',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
                helperText: '物理スタンプカードに押されているスタンプの数',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'スタンプ数を入力してください';
                }
                final n = int.tryParse(value);
                if (n == null || n < 1 || n > 99) {
                  return '1〜99の整数を入力してください';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final physicalStamps = int.tryParse(_stampCountController.text) ?? 0;
    return Card(
      elevation: 1,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '移行後のプレビュー',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('現在'),
                Text('${widget.currentStamps} 個'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('物理カード'),
                Text('+ $physicalStamps 個'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '移行後合計',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_previewStampsAfter 個',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (_completedCardsPreview > 0) ...[
              const SizedBox(height: 8),
              Text(
                'スタンプカード $_completedCardsPreview 枚達成！（スタンプ特典クーポンを付与します）',
                style: const TextStyle(color: Colors.green, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndMigrate() async {
    if (!_formKey.currentState!.validate()) return;

    final physicalStamps = int.parse(_stampCountController.text);
    final displayName =
        (widget.userProfile['displayName'] as String?) ?? 'お客様';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('移行を実行しますか？'),
        content: Text(
          '$displayName さんの物理スタンプカード $physicalStamps 枚をデジタルに移行します。\n'
          'この操作は取り消せません。\n\n'
          '物理スタンプカードのスタンプ数を目視で確認しましたか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('確認済み・移行する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final functions =
          FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      final callable = functions.httpsCallable(
        'migrateStampCard',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final result = await callable.call({
        'userId': widget.userId,
        'storeId': widget.storeId,
        'physicalStamps': physicalStamps,
      });

      final data = result.data as Map<String, dynamic>;

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StampMigrationCompleteView(
            displayName: displayName,
            stampsBefore:
                data['stampsBefore'] as int? ?? widget.currentStamps,
            stampsAfter: data['stampsAfter'] as int? ?? _previewStampsAfter,
            completedCards:
                data['completedCards'] as int? ?? _completedCardsPreview,
          ),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      String message;
      switch (e.code) {
        case 'already-exists':
          message = 'このユーザーへの移行は既に完了しています。';
        case 'permission-denied':
          message = 'この操作を実行する権限がありません。';
        case 'not-found':
          message = 'ユーザーまたは店舗が見つかりません。';
        case 'invalid-argument':
          message = '入力値が不正です: ${e.message}';
        default:
          message = 'エラーが発生しました: ${e.message}';
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('移行エラー'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('エラー'),
          content: Text('予期しないエラーが発生しました: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }
}
