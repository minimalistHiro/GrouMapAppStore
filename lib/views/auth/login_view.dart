import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import 'store_info_view.dart';
import 'approval_pending_view.dart';
import '../main_navigation_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインしました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 承認状況をチェックして適切な画面に遷移
        await _checkApprovalAndNavigate();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'ログインに失敗しました';
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'ユーザーが見つかりません';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'パスワードが間違っています';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = '無効なメールアドレスです';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'ログイン試行回数が多すぎます。しばらくしてから再試行してください';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // ロゴ
                Image.asset(
                  'assets/images/groumap_store_icon.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.store, size: 120, color: Colors.orange),
                ),
                
                const SizedBox(height: 32),
                
                // タイトル
                const Text(
                  'GrouMap Store',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  '店舗管理アプリにログイン',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // メールアドレス入力
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    hintText: 'example@store.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF6B35)),
                    ),
                  ),
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
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    prefixIcon: const Icon(Icons.lock_outlined),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF6B35)),
                    ),
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
                
                const SizedBox(height: 24),
                
                // ログインボタン
                CustomButton(
                  text: 'ログイン',
                  onPressed: _isLoading ? () {} : _signIn,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 16),
                
                // パスワードリセット
                TextButton(
                  onPressed: _showPasswordResetDialog,
                  child: const Text(
                    'パスワードを忘れた場合',
                    style: TextStyle(
                      color: Color(0xFFFF6B35),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 新規登録リンク
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'アカウントをお持ちでない方は ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const StoreInfoView()),
                        );
                      },
                      child: const Text(
                        '新規登録',
                        style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPasswordResetDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('パスワードリセット'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('パスワードリセット用のメールを送信します。'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
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
              if (emailController.text.isNotEmpty) {
                try {
                  final authService = ref.read(authServiceProvider);
                  await authService.sendPasswordResetEmail(emailController.text.trim());
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('パスワードリセット用のメールを送信しました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('エラーが発生しました: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('送信'),
          ),
        ],
      ),
    );
  }
}
