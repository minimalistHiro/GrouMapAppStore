import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/qr_verification_model.dart';

/// QRトークン検証プロバイダー
final qrVerificationProvider = StateNotifierProvider<QRVerificationNotifier, QRVerificationState>((ref) {
  return QRVerificationNotifier();
});

/// QR検証状態
class QRVerificationState {
  final bool isLoading;
  final QRVerificationResult? result;
  final String? error;

  const QRVerificationState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  QRVerificationState copyWith({
    bool? isLoading,
    QRVerificationResult? result,
    String? error,
  }) {
    return QRVerificationState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

/// QR検証Notifier
class QRVerificationNotifier extends StateNotifier<QRVerificationState> {
  QRVerificationNotifier() : super(const QRVerificationState());

  /// QRトークンを検証（リトライ機能付き）
  Future<QRVerificationResult> verifyQrToken({
    required String token,
    required String storeId,
    int maxRetries = 3,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Cloud FunctionsのverifyQrTokenを呼び出し
        final functions = FirebaseFunctions.instance;
        final callable = functions.httpsCallable('verifyQrToken');
        
        final result = await callable.call({
          'token': token,
          'storeId': storeId,
        });

        final data = result.data as Map<String, dynamic>;
        final response = QRVerificationResponse.fromJson(data);

        final verificationResult = _createVerificationResult(response);
        
        state = state.copyWith(
          isLoading: false,
          result: verificationResult,
        );

        return verificationResult;
      } catch (e) {
        print('QR検証エラー (試行 $attempt/$maxRetries): $e');
        
        // 最後の試行でない場合は少し待ってからリトライ
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2)); // 指数バックオフ
          continue;
        }
        
        // 最後の試行でも失敗した場合
        final errorResult = QRVerificationResult(
          isSuccess: false,
          message: _getErrorMessage(e),
          error: e.toString(),
        );
        
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
          result: errorResult,
        );

        return errorResult;
      }
    }

    // この行には到達しないはずだが、念のため
    final errorResult = QRVerificationResult(
      isSuccess: false,
      message: '予期しないエラーが発生しました',
      error: 'Unknown error',
    );
    
    state = state.copyWith(
      isLoading: false,
      error: 'Unknown error',
      result: errorResult,
    );

    return errorResult;
  }

  /// 検証結果をクリア
  void clearResult() {
    state = const QRVerificationState();
  }

  /// レスポンスから検証結果を作成
  QRVerificationResult _createVerificationResult(QRVerificationResponse response) {
    switch (response.status) {
      case QRVerificationStatus.ok:
        return QRVerificationResult(
          isSuccess: true,
          message: 'QRコードが有効です',
          uid: response.uid,
          jti: response.jti,
          status: response.status,
        );
      case QRVerificationStatus.expired:
        return QRVerificationResult(
          isSuccess: false,
          message: 'QRの有効期限切れ。お客さま側で再表示して再スキャンしてください',
          status: response.status,
        );
      case QRVerificationStatus.invalid:
        return QRVerificationResult(
          isSuccess: false,
          message: '無効なQRコードです',
          status: response.status,
        );
      case QRVerificationStatus.used:
        return QRVerificationResult(
          isSuccess: false,
          message: 'このQRコードは既に使用済みです',
          status: response.status,
        );
    }
  }

  /// エラーメッセージを取得
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'functions/unavailable':
          return 'サーバーに接続できません。ネットワーク接続を確認してください。';
        case 'functions/deadline-exceeded':
          return 'リクエストがタイムアウトしました。もう一度お試しください。';
        case 'functions/not-found':
          return 'QR検証機能が見つかりません。管理者にお問い合わせください。';
        case 'functions/permission-denied':
          return 'この操作を実行する権限がありません。';
        case 'functions/resource-exhausted':
          return 'リクエストが多すぎます。しばらく待ってから再試行してください。';
        case 'functions/unauthenticated':
          return '認証が必要です。ログインし直してください。';
        case 'functions/internal':
          return 'サーバー内部エラーが発生しました。しばらく待ってから再試行してください。';
        default:
          return 'サーバーエラーが発生しました: ${error.message ?? error.code}';
      }
    }
    
    if (error.toString().contains('network')) {
      return 'ネットワークエラーが発生しました。接続を確認してください。';
    }
    
    if (error.toString().contains('internal')) {
      return 'サーバー内部エラーが発生しました。しばらく待ってから再試行してください。';
    }
    
    return '予期しないエラーが発生しました: $error';
  }
}

/// 店舗設定プロバイダー
final storeSettingsProvider = StateNotifierProvider<StoreSettingsNotifier, StoreSettings?>((ref) {
  return StoreSettingsNotifier();
});

/// 店舗設定Notifier
class StoreSettingsNotifier extends StateNotifier<StoreSettings?> {
  StoreSettingsNotifier() : super(null);

  /// 店舗設定を設定
  void setStoreSettings(StoreSettings settings) {
    state = settings;
  }

  /// 店舗設定をクリア
  void clearStoreSettings() {
    state = null;
  }

  /// 現在の店舗IDを取得
  String? get currentStoreId => state?.storeId;

  /// 店舗設定が有効かチェック
  bool get hasValidStoreSettings => state != null && state!.storeId.isNotEmpty;
}
