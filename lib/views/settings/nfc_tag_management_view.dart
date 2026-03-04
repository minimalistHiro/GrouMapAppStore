import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';

/// 対象店舗のアクティブなNFCタグを取得するプロバイダー
final activeNfcTagProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, storeId) {
  return FirebaseFirestore.instance
      .collection('nfc_tags')
      .where('storeId', isEqualTo: storeId)
      .where('isActive', isEqualTo: true)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty ? null : snap.docs.first.data());
});

class NfcTagManagementView extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;

  const NfcTagManagementView({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  ConsumerState<NfcTagManagementView> createState() =>
      _NfcTagManagementViewState();
}

class _NfcTagManagementViewState extends ConsumerState<NfcTagManagementView> {
  bool _isGenerating = false;

  String _generateTagSecret() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(24, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$labelをコピーしました'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _registerNfcTag() async {
    setState(() => _isGenerating = true);
    try {
      final tagSecret = _generateTagSecret();
      final functions =
          FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      final callable = functions.httpsCallable('registerNfcTag');
      await callable.call({
        'storeId': widget.storeId,
        'tagSecret': tagSecret,
      });
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message ?? 'NFCタグの生成に失敗しました');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('NFCタグの生成に失敗しました: $e');
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _showConfirmDialog(
    BuildContext context, {
    required bool hasExistingTag,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hasExistingTag ? 'NFCタグを再生成しますか？' : 'NFCタグを生成しますか？'),
        content: Text(
          hasExistingTag
              ? '新しいタグを生成すると、現在のタグは無効になります。\n書き込み済みのNFCシールが使えなくなるのでご注意ください。'
              : 'このお店用の新しいNFCタグを生成します。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              hasExistingTag ? '再生成する' : '生成する',
              style: TextStyle(
                color:
                    hasExistingTag ? Colors.red : const Color(0xFFFF6B35),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _registerNfcTag();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagAsync = ref.watch(activeNfcTagProvider(widget.storeId));

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: const CommonHeader(title: 'NFCタグ管理'),
      body: tagAsync.when(
        data: (tagData) => _buildBody(context, tagData),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'エラーが発生しました: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic>? tagData) {
    final hasTag = tagData != null;

    final storeId = widget.storeId;
    final tagSecret = hasTag ? (tagData['tagSecret'] as String? ?? '') : '';
    final nfcUrl = hasTag
        ? 'https://groumapapp.web.app/checkin?storeId=$storeId&secret=$tagSecret'
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          if (hasTag) ...[
            _buildTagInfoCard(
              context,
              nfcUrl: nfcUrl!,
              storeId: storeId,
              tagSecret: tagSecret,
            ),
          ] else ...[
            _buildNoTagCard(),
          ],
          const SizedBox(height: 32),
          _buildGenerateButton(context, hasExistingTag: hasTag),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF6B35).withOpacity(0.3),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFF6B35), size: 20),
              SizedBox(width: 8),
              Text(
                'NFCタグについて',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'NTAG215などのNFCシールに以下のURLを書き込むことで、ユーザーがスマートフォンをかざすだけでチェックインできます。NFC Toolsアプリ等でURL型NDEFレコードとして書き込んでください。',
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTagCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
      child: const Column(
        children: [
          Icon(Icons.nfc, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'NFCタグが未登録です',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '下のボタンからタグを生成してください',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTagInfoCard(
    BuildContext context, {
    required String nfcUrl,
    required String storeId,
    required String tagSecret,
  }) {
    return Container(
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
      child: Column(
        children: [
          _buildCopyRow(
            context,
            label: 'NFC URL（タグに書き込む文字列）',
            value: nfcUrl,
            isUrl: true,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildCopyRow(
            context,
            label: '店舗ID (storeId)',
            value: storeId,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildCopyRow(
            context,
            label: 'シークレット (tagSecret)',
            value: tagSecret,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isUrl = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isUrl ? 12 : 14,
                    color: Colors.black87,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20, color: Color(0xFFFF6B35)),
            onPressed: () => _copyToClipboard(context, value, label),
            tooltip: 'コピー',
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(
    BuildContext context, {
    required bool hasExistingTag,
  }) {
    return CustomButton(
      text: hasExistingTag ? '新しいNFCタグを再生成する' : '新しいNFCタグを生成する',
      isLoading: _isGenerating,
      backgroundColor:
          hasExistingTag ? Colors.red[600] : const Color(0xFFFF6B35),
      icon: const Icon(Icons.add_card, color: Colors.white, size: 20),
      onPressed: () => _showConfirmDialog(context, hasExistingTag: hasExistingTag),
    );
  }
}
