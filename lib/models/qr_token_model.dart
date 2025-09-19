import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_token_model.freezed.dart';
part 'qr_token_model.g.dart';

@freezed
class QRToken with _$QRToken {
  const factory QRToken({
    required String userId,
    required DateTime timestamp,
    required String securityHash,
  }) = _QRToken;

  factory QRToken.fromJson(Map<String, dynamic> json) => _$QRTokenFromJson(json);
}

@freezed
class QRTokenValidationResult with _$QRTokenValidationResult {
  const factory QRTokenValidationResult({
    required bool isValid,
    required String message,
    QRToken? token,
    QRTokenError? error,
  }) = _QRTokenValidationResult;
}

enum QRTokenError {
  invalidFormat,
  expired,
  invalidHash,
  invalidUserId,
  unknown,
}

class QRTokenValidator {
  static const int _tokenValiditySeconds = 60;
  static const String _secretKey = 'groumap_secret_key_2024'; // 実際の運用では環境変数から取得

  /// QRコードの文字列からトークンを解析
  static QRTokenValidationResult parseAndValidate(String qrCodeString) {
    try {
      // QRコードの形式をチェック: userId|timestamp|hash
      final parts = qrCodeString.split('|');
      if (parts.length != 3) {
        return QRTokenValidationResult(
          isValid: false,
          message: 'QRコードの形式が正しくありません',
          error: QRTokenError.invalidFormat,
        );
      }

      final userId = parts[0];
      final timestampStr = parts[1];
      final securityHash = parts[2];

      // ユーザーIDの形式チェック（英数字、5文字以上）
      if (!RegExp(r'^[a-zA-Z0-9]{5,}$').hasMatch(userId)) {
        return QRTokenValidationResult(
          isValid: false,
          message: 'ユーザーIDの形式が正しくありません',
          error: QRTokenError.invalidUserId,
        );
      }

      // タイムスタンプの解析
      final timestamp = DateTime.tryParse(timestampStr);
      if (timestamp == null) {
        return QRTokenValidationResult(
          isValid: false,
          message: 'タイムスタンプの形式が正しくありません',
          error: QRTokenError.invalidFormat,
        );
      }

      // 有効期限チェック
      final now = DateTime.now();
      final timeDifference = now.difference(timestamp).inSeconds;
      if (timeDifference > _tokenValiditySeconds) {
        return QRTokenValidationResult(
          isValid: false,
          message: 'QRコードの有効期限が切れています（${_tokenValiditySeconds}秒以内）',
          error: QRTokenError.expired,
        );
      }

      // セキュリティハッシュの検証
      final expectedHash = _generateSecurityHash(userId, timestampStr);
      if (securityHash != expectedHash) {
        return QRTokenValidationResult(
          isValid: false,
          message: 'セキュリティハッシュが無効です',
          error: QRTokenError.invalidHash,
        );
      }

      // すべての検証を通過
      final token = QRToken(
        userId: userId,
        timestamp: timestamp,
        securityHash: securityHash,
      );

      return QRTokenValidationResult(
        isValid: true,
        message: 'QRコードが有効です',
        token: token,
      );
    } catch (e) {
      return QRTokenValidationResult(
        isValid: false,
        message: 'QRコードの解析中にエラーが発生しました: $e',
        error: QRTokenError.unknown,
      );
    }
  }

  /// セキュリティハッシュを生成
  static String _generateSecurityHash(String userId, String timestamp) {
    // 簡易的なハッシュ生成（実際の運用ではより強固な暗号化を使用）
    final data = '$userId|$timestamp|$_secretKey';
    return data.hashCode.abs().toString();
  }

  /// 新しいQRトークンを生成（テスト用）
  static String generateQRToken(String userId) {
    final timestamp = DateTime.now().toIso8601String();
    final hash = _generateSecurityHash(userId, timestamp);
    return '$userId|$timestamp|$hash';
  }
}
