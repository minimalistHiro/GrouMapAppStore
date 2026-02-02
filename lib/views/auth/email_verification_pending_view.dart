import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../main_navigation_view.dart';
import 'login_view.dart';

class EmailVerificationPendingView extends ConsumerStatefulWidget {
  final bool autoSendOnLoad;

  const EmailVerificationPendingView({
    Key? key,
    this.autoSendOnLoad = true,
  }) : super(key: key);

  @override
  ConsumerState<EmailVerificationPendingView> createState() => _EmailVerificationPendingViewState();
}

class _EmailVerificationPendingViewState extends ConsumerState<EmailVerificationPendingView> {
  bool _isResending = false;
  bool _isVerifying = false;
  bool _isDeleting = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.autoSendOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestEmailOtp();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // アイコン
              const Icon(
                Icons.mark_email_unread,
                size: 100,
                color: Color(0xFFFF6B35),
              ),
              
              const SizedBox(height: 24),
              
              // タイトル
              const Text(
                'メール認証コードの入力',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // 説明文
              Text(
                '${user?.email ?? "登録したメールアドレス"}に6桁の認証コードを送信しました。\nメールに記載されたコードを入力してください。',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              // メールプロバイダーの注意
              if (user?.email?.contains('@rakumail.jp') == true ||
                  user?.email?.contains('@yahoo.co.jp') == true)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ご利用のメールサービスでは、メールが届きにくい場合があります。迷惑メールフォルダもご確認ください。',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // 注意事項
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ご注意',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• メールが届かない場合は、迷惑メールフォルダをご確認ください\n• 認証コードの有効期限は10分です\n• 認証が完了するまで、一部の機能がご利用いただけません',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: '認証コード（6桁）',
                  hintText: '123456',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 認証実行ボタン
              CustomButton(
                text: '認証する',
                onPressed: _verifyEmailOtp,
                isLoading: _isVerifying,
                backgroundColor: const Color(0xFFFF6B35),
                textColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 再送信ボタン
              CustomButton(
                text: '認証コードを再送信',
                onPressed: _resendEmailVerification,
                isLoading: _isResending,
                backgroundColor: Colors.white,
                textColor: const Color(0xFFFF6B35),
                borderColor: const Color(0xFFFF6B35),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // トップに戻るボタン
              TextButton(
                onPressed: _isDeleting ? null : _deleteAccountAndReturn,
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
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // メール認証コードを検証
  Future<void> _verifyEmailOtp() async {
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('6桁の認証コードを入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyEmailOtp(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メール認証が完了しました'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationView()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('確認に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _requestEmailOtp() async {
    setState(() {
      _isResending = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = ref.read(currentUserProvider);

      await authService.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user?.email ?? "メールアドレス"} に認証コードを送信しました'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // 認証コードを再送信
  Future<void> _resendEmailVerification() async {
    await _requestEmailOtp();
  }

  Future<void> _deleteAccountAndReturn() async {
    setState(() {
      _isDeleting = true;
    });

    final authService = ref.read(authServiceProvider);
    final deleted = await _deleteAccountWithReauth(authService);
    if (!mounted) return;

    if (deleted == true) {
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
      setState(() {
        _isDeleting = false;
      });
      return;
    }

    setState(() {
      _isDeleting = false;
    });
    final password = await _promptPassword();
    if (!mounted || password == null || password.isEmpty) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
      await _showErrorDialog('再認証に必要なメールアドレスを取得できませんでした');
      return;
    }

    try {
      await authService.reauthenticateWithPassword(email: email, password: password);
      await authService.deleteAccount();
      if (mounted) {
        await authService.signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      await _showErrorDialog('再認証に失敗しました: ${e.message ?? e.code}');
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    } catch (e) {
      await _showErrorDialog('再認証に失敗しました: ${e.toString()}');
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
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
}
