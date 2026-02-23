import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import 'login_view.dart';
import '../main_navigation_view.dart';

class ApprovalPendingView extends ConsumerStatefulWidget {
  const ApprovalPendingView({Key? key}) : super(key: key);

  @override
  ConsumerState<ApprovalPendingView> createState() => _ApprovalPendingViewState();
}

class _ApprovalPendingViewState extends ConsumerState<ApprovalPendingView> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    // フレーム後に承認状況をチェック（UIの構築を待つ）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkApprovalStatus();
    });
  }

  Future<void> _checkApprovalStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isChecking = false;
        });
        return;
      }

      // ユーザーの店舗IDを直接取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _isChecking = false;
        });
        return;
      }

      final userData = userDoc.data()!;
      final createdStores = userData['createdStores'] as List<dynamic>?;
      
      if (createdStores == null || createdStores.isEmpty) {
        setState(() {
          _isChecking = false;
        });
        return;
      }

      final storeId = createdStores.first as String;

      // 店舗の承認状況を確認
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      if (storeDoc.exists) {
        final storeData = storeDoc.data()!;
        final isApproved = storeData['isApproved'] ?? false;

        if (isApproved) {
          // 承認済みの場合は即座にホーム画面に遷移（UI更新をスキップ）
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainNavigationView()),
              (route) => false,
            );
          }
          return;
        }
      }

      // 未承認または店舗情報が見つからない場合は承認待ち画面を表示
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _showReturnToTopDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('トップに戻る'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'トップに戻るとアカウントが削除されます。',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• アカウント情報'),
              Text('• 作成した店舗情報'),
              Text('• その他すべての関連データ'),
              SizedBox(height: 12),
              Text(
                'この操作は取り消すことができません。',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '本当にトップに戻りますか？',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccountAndReturn();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('削除して戻る'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccountAndReturn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('アカウントを削除しています...'),
            ],
          ),
        );
      },
    );

    final authService = ref.read(authServiceProvider);
    final deleted = await _deleteAccountWithReauth(authService);
    if (!mounted) return;

    if (deleted == true) {
      Navigator.of(context).pop();
      try {
        await authService.signOut();
      } catch (e) {
        debugPrint('ログアウトエラー: $e');
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
      return;
    }

    if (deleted == false) {
      Navigator.of(context).pop();
      return;
    }

    // 再認証が必要
    Navigator.of(context).pop();
    final password = await _promptPassword();
    if (!mounted || password == null || password.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('再認証しています...'),
            ],
          ),
        );
      },
    );

    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      if (mounted) Navigator.of(context).pop();
      await _showErrorDialog('再認証に必要なメールアドレスを取得できませんでした');
      return;
    }

    try {
      await authService.reauthenticateWithPassword(email: email, password: password);
      await authService.deleteAccount();
      if (mounted) Navigator.of(context).pop();
      try {
        await authService.signOut();
      } catch (e) {
        debugPrint('ログアウトエラー: $e');
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.of(context).pop();
      await _showErrorDialog('再認証に失敗しました: ${e.message ?? e.code}');
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      await _showErrorDialog('再認証に失敗しました: ${e.toString()}');
    }
  }

  Future<bool?> _deleteAccountWithReauth(AuthService authService) async {
    try {
      await authService.deleteAccount();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        await _showErrorDialog('アカウント削除に失敗しました: ${e.message ?? e.code}');
        return false;
      }
      return null;
    } catch (e) {
      await _showErrorDialog('アカウント削除に失敗しました: ${e.toString()}');
      return false;
    }
  }

  Future<String?> _promptPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('再認証が必要です'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'パスワード',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('再認証'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ロゴ
                      Image.asset(
                        'assets/images/groumap_store_icon.png',
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.store, size: 120, color: Color(0xFFFF6B35)),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // タイトル
                      const Text(
                        'ぐるまっぷ店舗用',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 承認待ちメッセージ
                      if (_isChecking)
                        const Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '承認状況を確認中...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '承認がされるまでしばらくお待ちください',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'アカウントが承認され次第、\n店舗管理機能をご利用いただけます',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            IconButton(
                              onPressed: _checkApprovalStatus,
                              icon: const Icon(Icons.refresh),
                              color: const Color(0xFFFF6B35),
                              iconSize: 32,
                              tooltip: 'リロード',
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: _showReturnToTopDialog,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text(
                  'トップに戻る',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
