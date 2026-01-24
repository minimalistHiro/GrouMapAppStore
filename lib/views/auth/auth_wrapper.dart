import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'email_verification_pending_view.dart';
import 'login_view.dart';
import '../main_navigation_view.dart';
import '../../widgets/app_update_gate.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final emailVerificationStatus = ref.watch(emailVerificationStatusProvider);

    return AppUpdateGate(
      child: authState.when(
        data: (user) {
          if (user == null) {
            // ログインしていない場合はログイン画面を表示
            return const LoginView();
          }

          return emailVerificationStatus.when(
            data: (isVerified) {
              if (!isVerified) {
                return const EmailVerificationPendingView(autoSendOnLoad: false);
              }
              return const MainNavigationView();
            },
            loading: () => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
              ),
            ),
            error: (_, __) => const EmailVerificationPendingView(autoSendOnLoad: false),
          );
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
      ),
    );
  }
}
