import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/push_notification_service.dart';
import 'email_verification_pending_view.dart';
import 'login_view.dart';
import '../main_navigation_view.dart';
import '../../widgets/app_update_gate.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  late final PushNotificationService _pushNotificationService;
  ProviderSubscription? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _pushNotificationService = ref.read(pushNotificationServiceProvider);
    _pushNotificationService.initialize();

    _authStateSubscription = ref.listenManual(authStateProvider, (previous, next) {
      if (next is AsyncData) {
        final user = next.value;
        if (user != null) {
          _pushNotificationService.registerForUser(user.uid);
        } else {
          _pushNotificationService.clearCurrentUser();
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final emailOtpRequired = ref.watch(emailOtpRequiredProvider);

    return AppUpdateGate(
      child: authState.when(
        data: (user) {
          if (user == null) {
            // ログインしていない場合はログイン画面を表示
            return const LoginView();
          }

          return emailOtpRequired.when(
            data: (isRequired) {
              if (isRequired) {
                return const EmailVerificationPendingView(
                  autoSendOnLoad: false,
                  isLoginFlow: true,
                );
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
            error: (_, __) => const EmailVerificationPendingView(
              autoSendOnLoad: false,
              isLoginFlow: true,
            ),
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
