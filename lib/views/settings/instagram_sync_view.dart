import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/error_dialog.dart';

class InstagramSyncView extends ConsumerStatefulWidget {
  const InstagramSyncView({Key? key}) : super(key: key);

  @override
  ConsumerState<InstagramSyncView> createState() => _InstagramSyncViewState();
}

class _InstagramSyncViewState extends ConsumerState<InstagramSyncView> {
  bool _isSyncing = false;
  String? _statusMessage;
  bool _isUnlinking = false;
  bool _isStartingAuth = false;
  bool _isExchanging = false;
  final TextEditingController _authCodeController = TextEditingController();
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  @override
  void dispose() {
    _authCodeController.dispose();
    super.dispose();
  }

  Future<void> _showLinkCompletedDialog(String count) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('連携が完了しました'),
          content: Text('Instagram連携が完了しました。（取得: $count 件）'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSyncCompletedDialog(String count) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('同期が完了しました'),
          content: Text('Instagram同期が完了しました。（取得: $count 件）'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runSync(String storeId) async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
      _statusMessage = null;
    });

    try {
      final callable = _functions.httpsCallable('syncInstagramPosts');
      final result = await callable.call({'storeId': storeId});
      final data = result.data as Map<dynamic, dynamic>?;
      final count = data?['count']?.toString() ?? '0';
      setState(() {
        _statusMessage = '同期が完了しました（取得: $count 件）';
      });
      await _showSyncCompletedDialog(count);
    } catch (e) {
      ErrorDialog.show(
        context,
        title: '同期に失敗しました',
        message: 'Instagram同期に失敗しました。',
        details: e.toString(),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _startInstagramAuth(String storeId) async {
    if (_isStartingAuth) return;
    setState(() {
      _isStartingAuth = true;
    });

    try {
      final callable = _functions.httpsCallable('startInstagramAuth');
      final result = await callable.call({'storeId': storeId});
      final data = result.data as Map<dynamic, dynamic>?;
      final authUrl = data?['authUrl']?.toString();
      if (authUrl == null || authUrl.isEmpty) {
        throw Exception('認可URLが取得できませんでした');
      }
      final uri = Uri.parse(authUrl);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        throw Exception('ブラウザで認可URLを開けませんでした');
      }
    } catch (e) {
      ErrorDialog.show(
        context,
        title: '連携開始に失敗しました',
        message: 'Instagram連携を開始できませんでした。',
        details: e.toString(),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isStartingAuth = false;
      });
    }
  }

  Future<void> _exchangeInstagramCode(String storeId) async {
    final raw = _authCodeController.text.trim();
    final code = _extractAuthCode(raw);
    if (code.isEmpty) {
      ErrorDialog.show(
        context,
        title: '認可コードが必要です',
        message: '認可コードまたはURLを入力してください。',
      );
      return;
    }
    if (_isExchanging) return;

    setState(() {
      _isExchanging = true;
      _statusMessage = null;
    });

    try {
      final callable = _functions.httpsCallable('exchangeInstagramAuthCode');
      final result = await callable.call({'storeId': storeId, 'code': code});
      final data = result.data as Map<dynamic, dynamic>?;
      final count = data?['count']?.toString() ?? '0';
      setState(() {
        _statusMessage = '連携が完了しました（取得: $count 件）';
      });
      _authCodeController.clear();
      await _showLinkCompletedDialog(count);
    } catch (e) {
      ErrorDialog.show(
        context,
        title: '連携に失敗しました',
        message: 'Instagram連携に失敗しました。',
        details: e.toString(),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isExchanging = false;
      });
    }
  }

  String _extractAuthCode(String raw) {
    if (raw.isEmpty) return '';
    final sanitized = raw.replaceAll('#_=_', '');
    if (sanitized.startsWith('code=')) {
      return sanitized.substring('code='.length);
    }
    if (sanitized.contains('code=')) {
      final uri = Uri.tryParse(sanitized);
      final code = uri?.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        return code;
      }
      final match = RegExp(r'code=([^&]+)').firstMatch(sanitized);
      if (match != null) {
        return match.group(1) ?? '';
      }
    }
    return sanitized;
  }

  Future<void> _unlinkInstagram(String storeId) async {
    if (_isUnlinking) return;
    setState(() {
      _isUnlinking = true;
    });

    try {
      final callable = _functions.httpsCallable('unlinkInstagramAuth');
      await callable.call({'storeId': storeId});
      setState(() {
        _statusMessage = 'Instagram連携を解除しました。';
      });
    } catch (e) {
      ErrorDialog.show(
        context,
        title: '連携解除に失敗しました',
        message: 'Instagram連携の解除に失敗しました。',
        details: e.toString(),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUnlinking = false;
      });
    }
  }

  String _formatSyncAt(dynamic value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }
    if (date == null) return '未同期';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final storeIdAsync = ref.watch(userStoreIdProvider);

    return Scaffold(
      appBar: const CommonHeader(title: 'Instagram同期'),
      backgroundColor: const Color(0xFFFBF6F2),
      body: storeIdAsync.when(
        data: (storeId) {
          if (storeId == null) {
            return const Center(
              child: Text('店舗情報が取得できませんでした。'),
            );
          }

          final storeDataAsync = ref.watch(storeDataProvider(storeId));
          return storeDataAsync.when(
            data: (storeData) {
              if (storeData == null) {
                return const Center(
                  child: Text('店舗情報が取得できませんでした。'),
                );
              }

              final instagramAuth = storeData['instagramAuth'] as Map<String, dynamic>?;
              final instagramSync = storeData['instagramSync'] as Map<String, dynamic>?;
              final socialMedia = storeData['socialMedia'] as Map<String, dynamic>?;
              final instagramLink = (socialMedia?['instagram'] as String?) ?? '';
              final instagramUserId = (instagramAuth?['instagramUserId'] as String?) ?? '';
              final isLinked = instagramUserId.isNotEmpty;
              final lastSyncAt = instagramSync?['lastSyncAt'];
              final lastSyncCount = instagramSync?['lastSyncCount'];

              return DismissKeyboard(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isLinked) ...[
                        _buildInfoCard(
                          title: 'Instagram連携手順',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                instagramLink.isNotEmpty
                                    ? '対象アカウント: $instagramLink'
                                    : 'Instagramリンクが未設定です',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '1. 「連携を開始する」を押してInstagramにログイン',
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '2. 表示された認可コードをコピー',
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '3. 下の入力欄に貼り付けて連携を完了',
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              CustomButton(
                                text: '連携を開始する',
                                isLoading: _isStartingAuth,
                                onPressed: _isStartingAuth ? null : () => _startInstagramAuth(storeId),
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                controller: _authCodeController,
                                labelText: '認可コード',
                                hintText: '認可コードまたはURLを貼り付け',
                                maxLines: 2,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '※「https://.../instagram-auth?code=...」のURLを貼り付けてもOKです',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              CustomButton(
                                text: '連携を完了する',
                                isLoading: _isExchanging,
                                onPressed: _isExchanging ? null : () => _exchangeInstagramCode(storeId),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (isLinked) ...[
                        _buildInfoCard(
                          title: '同期項目',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '最終同期: ${_formatSyncAt(lastSyncAt)}',
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              if (lastSyncCount != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '前回取得件数: $lastSyncCount 件',
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                              const SizedBox(height: 8),
                              const Text(
                                'Instagramの最新投稿（動画を除外）を取得し、'
                                'ユーザーアプリに表示するための同期です。',
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_statusMessage != null) ...[
                          _buildInfoCard(
                            title: '同期結果',
                            child: Text(
                              _statusMessage!,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        CustomButton(
                          text: '今すぐ同期する',
                          isLoading: _isSyncing,
                          onPressed: _isSyncing ? null : () => _runSync(storeId),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Instagram連携を解除する',
                          isLoading: _isUnlinking,
                          backgroundColor: Colors.white,
                          textColor: Colors.red,
                          borderColor: Colors.red,
                          onPressed: _isUnlinking
                              ? null
                              : () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('連携解除の確認'),
                                      content: const Text('Instagram連携を解除しますか？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogContext).pop(false),
                                          child: const Text('キャンセル'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogContext).pop(true),
                                          child: const Text(
                                            '解除する',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    _unlinkInstagram(storeId);
                                  }
                                },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
            error: (error, _) => Center(
              child: Text('店舗情報の取得に失敗しました: $error'),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
          ),
        ),
        error: (error, _) => Center(
          child: Text('店舗情報の取得に失敗しました: $error'),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
