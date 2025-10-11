import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'login_view.dart';
import '../main_navigation_view.dart';

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
        
        // ログイン済みの場合は直接メインナビゲーション画面を表示
        return const MainNavigationView();
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
