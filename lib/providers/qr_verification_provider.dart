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
    // ウィジェットが破棄されていないかチェック
    if (!mounted) {
      print('QRVerificationNotifier: ウィジェットが破棄されています');
      return QRVerificationResult(
        isSuccess: false,
        message: '処理が中断されました',
        error: 'Widget disposed',
      );
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          print('QR検証開始 (試行 $attempt/$maxRetries): storeId=$storeId, tokenLength=${token.length}');
          
          // まずテスト関数を呼び出し
          final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
          final testCallable = functions.httpsCallable(
            'testFunction',
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 30),
            ),
          );
          
          print('テスト関数呼び出し開始');
          final testResult = await testCallable.call();
          print('テスト関数呼び出し成功: ${testResult.data}');
          
          // Cloud FunctionsのverifyQrTokenを呼び出し（リージョン指定）
          final callable = functions.httpsCallable(
            'verifyQrToken',
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 30),
            ),
          );
          
          print('Cloud Functions呼び出し開始');
          final result = await callable.call({
            'token': token,
            'storeId': storeId,
          });

          print('Cloud Functions呼び出し成功: ${result.data}');

          final data = result.data as Map<String, dynamic>;
          final response = QRVerificationResponse.fromJson(data);

          final verificationResult = _createVerificationResult(response);
          
          // ウィジェットが破棄されていないかチェック
          if (!mounted) {
            print('QRVerificationNotifier: 検証完了後にウィジェットが破棄されています');
            return verificationResult;
          }
          
          state = state.copyWith(
            isLoading: false,
            result: verificationResult,
          );

          return verificationResult;
        } catch (e) {
          print('QR検証エラー (試行 $attempt/$maxRetries): $e');
          print('エラータイプ: ${e.runtimeType}');
          
          if (e is FirebaseFunctionsException) {
            print('FirebaseFunctionsException詳細: code=${e.code}, message=${e.message}, details=${e.details}');
          }
          
          // 最後の試行でない場合は少し待ってからリトライ
          if (attempt < maxRetries) {
            final delay = Duration(seconds: attempt * 2); // 指数バックオフ
            print('${delay.inSeconds}秒後にリトライします...');
            await Future.delayed(delay);
            continue;
          }
          
          // 最後の試行でも失敗した場合、エラーを再スロー
          rethrow;
        }
      }
    } catch (e) {
      print('QR検証最終エラー: $e');
      
      // エラー結果を作成
      final errorResult = QRVerificationResult(
        isSuccess: false,
        message: _getErrorMessage(e),
        error: e.toString(),
      );
      
      // ウィジェットが破棄されていないかチェック
      if (!mounted) {
        print('QRVerificationNotifier: エラー処理時にウィジェットが破棄されています');
        return errorResult;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        result: errorResult,
      );

      return errorResult;
    }

    // この行には到達しないはずだが、念のため
    final errorResult = QRVerificationResult(
      isSuccess: false,
      message: '予期しないエラーが発生しました',
      error: 'Unknown error',
    );
    
    if (!mounted) {
      print('QRVerificationNotifier: 予期しないエラー処理時にウィジェットが破棄されています');
      return errorResult;
    }
    
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
    print('エラーメッセージ生成開始: ${error.runtimeType}');
    
    if (error is FirebaseFunctionsException) {
      print('FirebaseFunctionsException: code=${error.code}, message=${error.message}, details=${error.details}');
      
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
          print('内部エラー詳細: ${error.message}');
          return 'サーバー内部エラーが発生しました。詳細: ${error.message ?? "不明なエラー"}';
        case 'functions/invalid-argument':
          return '無効なパラメータです: ${error.message ?? "不明なエラー"}';
        case 'functions/failed-precondition':
          return '前提条件が満たされていません: ${error.message ?? "不明なエラー"}';
        default:
          print('未知のFirebaseFunctionsException: ${error.code}');
          return 'サーバーエラーが発生しました: ${error.message ?? error.code}';
      }
    }
    
    final errorString = error.toString();
    print('エラー文字列: $errorString');
    
    if (errorString.contains('network') || errorString.contains('NetworkException')) {
      return 'ネットワークエラーが発生しました。接続を確認してください。';
    }
    
    if (errorString.contains('internal') || errorString.contains('InternalError')) {
      return 'サーバー内部エラーが発生しました。しばらく待ってから再試行してください。';
    }
    
    if (errorString.contains('timeout') || errorString.contains('TimeoutException')) {
      return 'リクエストがタイムアウトしました。もう一度お試しください。';
    }
    
    if (errorString.contains('permission') || errorString.contains('PermissionDenied')) {
      return 'この操作を実行する権限がありません。';
    }
    
    print('予期しないエラータイプ: $errorString');
    return '予期しないエラーが発生しました: $errorString';
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
