import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'email_change_otp_view.dart';

class EmailChangeView extends ConsumerStatefulWidget {
  const EmailChangeView({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailChangeView> createState() => _EmailChangeViewState();
}

class _EmailChangeViewState extends ConsumerState<EmailChangeView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentEmailController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSending = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authServiceProvider).currentUser;
    _currentEmailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _currentEmailController.dispose();
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _canChangeEmail(User? user) {
    if (user == null) return false;
    return user.providerData.any((provider) => provider.providerId == 'password');
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) {
      _showSnackBar('ログイン情報を確認できません');
      return;
    }

    if (!_canChangeEmail(user)) {
      _showSnackBar('このアカウントではメールアドレス変更ができません');
      return;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      _showSnackBar('現在のメールアドレスを確認できません');
      return;
    }

    setState(() => _isSending = true);

    try {
      // パスワードで再認証
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // 新メールアドレスにOTP送信
      final newEmail = _newEmailController.text.trim();
      await authService.sendEmailChangeOtp(newEmail);

      if (!mounted) return;

      // OTP入力画面に遷移
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => EmailChangeOtpView(newEmail: newEmail),
        ),
      );

      if (result == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'メールアドレスの変更に失敗しました';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = '現在のパスワードが正しくありません';
      } else if (e.code == 'requires-recent-login') {
        message = '再ログインが必要です。ログアウト後にもう一度お試しください';
      }
      _showSnackBar(message);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString();
      if (errorMsg.contains('already-exists') || errorMsg.contains('email-already-in-use')) {
        _showSnackBar('このメールアドレスは既に使用されています');
      } else if (errorMsg.contains('resource-exhausted')) {
        _showSnackBar('認証コードは1分以内に再送信できません');
      } else if (errorMsg.contains('invalid-argument')) {
        _showSnackBar('有効なメールアドレスを入力してください');
      } else {
        _showSnackBar('メールアドレスの変更に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authServiceProvider).currentUser;
    final canChange = _canChangeEmail(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('メールアドレス変更'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '新しいメールアドレスを入力してください。認証コードが新しいメールアドレスに送信されます。',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (!canChange) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'このアカウントはパスワードでログインしていないため、メールアドレスを変更できません。',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomTextField(
                    controller: _currentEmailController,
                    labelText: '現在のメールアドレス',
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _newEmailController,
                    labelText: '新しいメールアドレス',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (!canChange) return null;
                      if (value == null || value.trim().isEmpty) {
                        return '新しいメールアドレスを入力してください';
                      }
                      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
                        return 'メールアドレスの形式が正しくありません';
                      }
                      if (value.trim().toLowerCase() == _currentEmailController.text.trim().toLowerCase()) {
                        return '現在のメールアドレスと異なるアドレスを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: '現在のパスワード',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (!canChange) return null;
                      if (value == null || value.isEmpty) {
                        return '現在のパスワードを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: '認証コードを送信',
                    onPressed: canChange && !_isSending ? _sendOtp : null,
                    isLoading: _isSending,
                    borderRadius: 999,
                    backgroundColor: const Color(0xFFFF6B35),
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
