import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'email_verification_pending_view.dart';

class StoreOwnerSignUpView extends ConsumerStatefulWidget {
  const StoreOwnerSignUpView({Key? key}) : super(key: key);

  @override
  ConsumerState<StoreOwnerSignUpView> createState() => _StoreOwnerSignUpViewState();
}

class _StoreOwnerSignUpViewState extends ConsumerState<StoreOwnerSignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      await authService.createStoreOwnerAccount(
        _emailController.text.trim(),
        _passwordController.text,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      try {
        await authService.sendEmailVerification();
      } catch (_) {
        // 送信失敗でも遷移は続行
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウントを作成しました。認証コードを送信しました。'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const EmailVerificationPendingView(autoSendOnLoad: false),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'アカウント作成に失敗しました';
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'このメールアドレスは既に使用されています';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = '無効なメールアドレスです';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'パスワードが弱すぎます';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // タイトル
                const Text(
                  'ぐるまっぷ店舗用',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  'アカウント作成',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // 説明文
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
                  ),
                  child: const Text(
                    '来店データをアプリで確認するためのアカウントを作成します。\nアカウント作成後、運営から受け取ったリンクコードで店舗と紐づけを行います。',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // メールアドレス
                CustomTextField(
                  controller: _emailController,
                  labelText: 'メールアドレス',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'メールアドレスを入力してください';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return '有効なメールアドレスを入力してください';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // パスワード
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'パスワード',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'パスワードを入力してください';
                    if (value.length < 6) return 'パスワードは6文字以上で入力してください';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // パスワード確認
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'パスワード確認',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'パスワード確認を入力してください';
                    if (value != _passwordController.text) return 'パスワードが一致しません';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                CustomButton(
                  text: 'アカウント作成',
                  onPressed: _isLoading ? null : _handleSignUp,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
