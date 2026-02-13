import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'approval_pending_view.dart';
import 'email_verification_pending_view.dart';
import '../main_navigation_view.dart';

class SignUpView extends ConsumerStatefulWidget {
  final Map<String, dynamic>? storeInfo;
  
  const SignUpView({Key? key, this.storeInfo}) : super(key: key);

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
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
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'アカウント作成',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // メールアドレス入力
                CustomTextField(
                  controller: _emailController,
                  labelText: 'メールアドレス',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // パスワード入力
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'パスワード',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    if (value.length < 6) {
                      return 'パスワードは6文字以上で入力してください';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // パスワード確認入力
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'パスワード確認',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワード確認を入力してください';
                    }
                    if (value != _passwordController.text) {
                      return 'パスワードが一致しません';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // 登録ボタン
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

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final authService = ref.read(authServiceProvider);
        
        // アカウント作成
        print('アカウント作成開始: ${_emailController.text.trim()}');
        await authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          widget.storeInfo,
        );
        print('アカウント作成完了');
        
        // 少し待機してからメール送信
        await Future.delayed(const Duration(milliseconds: 500));
        
        // メール認証コードを送信
        print('メール認証コード送信開始');
        try {
          await authService.sendEmailVerification();
          print('メール認証コード送信完了');
        } catch (emailError) {
          print('メール送信エラー: $emailError');
          // メール送信エラーでも画面遷移は行う
        }
        
        // 成功時の処理
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('アカウントと店舗情報を作成しました。認証コードを送信しました。'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // メール認証待ち画面に遷移
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const EmailVerificationPendingView(autoSendOnLoad: false),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        // エラー時の処理
        print('アカウント作成エラー: $e');
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
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _checkApprovalAndNavigate() async {
    try {
      // 現在のユーザーを取得
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ApprovalPendingView()),
          (route) => false,
        );
        return;
      }

      // ユーザーの店舗IDを直接取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ApprovalPendingView()),
          (route) => false,
        );
        return;
      }

      final userData = userDoc.data()!;
      final createdStores = userData['createdStores'] as List<dynamic>?;
      
      if (createdStores == null || createdStores.isEmpty) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ApprovalPendingView()),
          (route) => false,
        );
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
          // 承認済みの場合は直接ホーム画面に遷移
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainNavigationView()),
            (route) => false,
          );
        } else {
          // 未承認の場合は承認待ち画面に遷移
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ApprovalPendingView()),
            (route) => false,
          );
        }
      } else {
        // 店舗情報が見つからない場合は承認待ち画面に遷移
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ApprovalPendingView()),
          (route) => false,
        );
      }
    } catch (e) {
      // エラーの場合は承認待ち画面に遷移
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ApprovalPendingView()),
        (route) => false,
      );
    }
  }
}
