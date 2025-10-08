import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import 'login_view.dart';
import 'email_verification_pending_view.dart';
import '../main_navigation_view.dart';
import 'approval_pending_view.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // ログインしていない場合はログイン画面を表示
          return const LoginView();
        }
        
        // ログイン済みの場合はメール認証状態をチェック
        return _EmailVerificationChecker();
      },
      loading: () {
        // 認証状態を確認中
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        // エラーの場合はログイン画面を表示
        return const LoginView();
      },
    );
  }
}

class _EmailVerificationChecker extends ConsumerStatefulWidget {
  @override
  ConsumerState<_EmailVerificationChecker> createState() => _EmailVerificationCheckerState();
}

class _EmailVerificationCheckerState extends ConsumerState<_EmailVerificationChecker> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    try {
      final authService = ref.read(authServiceProvider);
      final isVerified = await authService.isEmailVerified();
      
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        
        if (!isVerified) {
          // メール認証未完了の場合は認証待ち画面を表示
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const EmailVerificationPendingView()),
            (route) => false,
          );
        } else {
          // メール認証完了の場合は承認状態をチェックして適切な画面に遷移
          await _checkApprovalAndNavigate();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        
        // エラーの場合はメール認証待ち画面に遷移
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const EmailVerificationPendingView()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _checkApprovalAndNavigate() async {
    try {
      // 現在のユーザーを取得
      final user = ref.read(currentUserProvider);
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
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
          ),
        ),
      );
    }
    
    // チェック中でない場合はメイン画面を表示（通常は上記の処理で遷移するはず）
    return const MainNavigationView();
  }
}
