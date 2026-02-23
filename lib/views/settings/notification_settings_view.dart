import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_switch_tile.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/common_header.dart';

class NotificationSettingsView extends ConsumerStatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  ConsumerState<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends ConsumerState<NotificationSettingsView> {
  // プッシュ通知設定
  bool _newVisitor = true;
  bool _couponUsage = true;
  bool _feedback = true;

  // メール通知設定
  bool _system = true;
  bool _promotions = false;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final storeId = ref.read(userStoreIdProvider).value;
      if (storeId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final snapshot = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
      final data = snapshot.data();

      final pushSettings = data?['notificationSettings'] as Map<String, dynamic>?;
      final emailSettings = data?['emailNotificationSettings'] as Map<String, dynamic>?;

      setState(() {
        _newVisitor = pushSettings?['newVisitor'] as bool? ?? true;
        _couponUsage = pushSettings?['couponUsage'] as bool? ?? true;
        _feedback = pushSettings?['feedback'] as bool? ?? true;
        _system = emailSettings?['system'] as bool? ?? true;
        _promotions = emailSettings?['promotions'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ErrorDialog.show(
        context,
        title: '読み込みに失敗しました',
        message: '通知設定の取得に失敗しました。時間をおいて再度お試しください。',
        details: e.toString(),
      );
    }
  }

  Future<void> _savePushSettings() async {
    final storeId = ref.read(userStoreIdProvider).value;
    if (storeId == null) {
      ErrorDialog.show(
        context,
        title: '保存できません',
        message: '店舗情報を確認できませんでした。再ログイン後にお試しください。',
      );
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('stores').doc(storeId).set({
        'notificationSettings': {
          'newVisitor': _newVisitor,
          'couponUsage': _couponUsage,
          'feedback': _feedback,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ErrorDialog.show(
        context,
        title: '保存に失敗しました',
        message: '通知設定の保存に失敗しました。時間をおいて再度お試しください。',
        details: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveEmailSettings() async {
    final storeId = ref.read(userStoreIdProvider).value;
    if (storeId == null) {
      ErrorDialog.show(
        context,
        title: '保存できません',
        message: '店舗情報を確認できませんでした。再ログイン後にお試しください。',
      );
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('stores').doc(storeId).set({
        'emailNotificationSettings': {
          'system': _system,
          'promotions': _promotions,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ErrorDialog.show(
        context,
        title: '保存に失敗しました',
        message: 'メール通知設定の保存に失敗しました。時間をおいて再度お試しください。',
        details: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: '通知設定'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionLabel('プッシュ通知'),
                const SizedBox(height: 8),
                _buildCard([
                  CustomSwitchListTile(
                    title: const Text('新規来店者通知'),
                    subtitle: const Text('お客様が来店した時に通知'),
                    value: _newVisitor,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _newVisitor = value);
                            _savePushSettings();
                          },
                  ),
                  const Divider(height: 0),
                  CustomSwitchListTile(
                    title: const Text('クーポン使用通知'),
                    subtitle: const Text('クーポンが使用された時に通知'),
                    value: _couponUsage,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _couponUsage = value);
                            _savePushSettings();
                          },
                  ),
                  const Divider(height: 0),
                  CustomSwitchListTile(
                    title: const Text('フィードバック通知'),
                    subtitle: const Text('お客様からのフィードバックが届いた時に通知'),
                    value: _feedback,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _feedback = value);
                            _savePushSettings();
                          },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionLabel('メール通知'),
                const SizedBox(height: 8),
                _buildCard([
                  CustomSwitchListTile(
                    title: const Text('システム通知'),
                    subtitle: const Text('アプリの更新やメンテナンス情報'),
                    value: _system,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _system = value);
                            _saveEmailSettings();
                          },
                  ),
                  const Divider(height: 0),
                  CustomSwitchListTile(
                    title: const Text('プロモーション通知'),
                    subtitle: const Text('新機能やキャンペーンのお知らせ'),
                    value: _promotions,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _promotions = value);
                            _saveEmailSettings();
                          },
                  ),
                ]),
                const SizedBox(height: 16),
              ],
            ),
      backgroundColor: const Color(0xFFFBF6F2),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(children: children),
    );
  }
}
