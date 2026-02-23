import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PasswordChangeView extends ConsumerStatefulWidget {
  const PasswordChangeView({Key? key}) : super(key: key);

  @override
  ConsumerState<PasswordChangeView> createState() => _PasswordChangeViewState();
}

class _PasswordChangeViewState extends ConsumerState<PasswordChangeView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _canChangePassword(User? user) {
    if (user == null) return false;
    return user.providerData
        .any((provider) => provider.providerId == 'password');
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) {
      _showSnackBar('ログイン情報を確認できません');
      return;
    }

    if (!_canChangePassword(user)) {
      _showSnackBar('このアカウントではパスワード変更ができません');
      return;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      _showSnackBar('メールアドレスを確認できません');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('パスワードを変更しました'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'パスワード変更に失敗しました';
      if (e.code == 'wrong-password') {
        message = '現在のパスワードが正しくありません';
      } else if (e.code == 'weak-password') {
        message = '新しいパスワードは6文字以上にしてください';
      } else if (e.code == 'requires-recent-login') {
        message = '再ログインが必要です。ログアウト後にもう一度お試しください';
      }
      _showSnackBar(message);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('パスワード変更に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
    final canChange = _canChangePassword(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('パスワード変更'),
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
                    '現在のパスワードと新しいパスワードを入力してください。',
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
                        'このアカウントはパスワードでログインしていないため、変更できません。',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomTextField(
                    controller: _currentPasswordController,
                    labelText: '現在のパスワード',
                    obscureText: _obscureCurrent,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    validator: (value) {
                      if (!canChange) return null;
                      if (value == null || value.isEmpty) {
                        return '現在のパスワードを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _newPasswordController,
                    labelText: '新しいパスワード',
                    obscureText: _obscureNew,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    validator: (value) {
                      if (!canChange) return null;
                      if (value == null || value.isEmpty) {
                        return '新しいパスワードを入力してください';
                      }
                      if (value.length < 6) {
                        return '6文字以上で入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: '新しいパスワード（確認）',
                    obscureText: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (value) {
                      if (!canChange) return null;
                      if (value == null || value.isEmpty) {
                        return '確認用のパスワードを入力してください';
                      }
                      if (value != _newPasswordController.text) {
                        return '新しいパスワードが一致しません';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: '変更する',
                    onPressed:
                        canChange && !_isSaving ? _changePassword : null,
                    isLoading: _isSaving,
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
