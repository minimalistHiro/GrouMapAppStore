import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_verification_model.freezed.dart';
part 'qr_verification_model.g.dart';

/// QRトークン検証リクエスト
@freezed
class QRVerificationRequest with _$QRVerificationRequest {
  const factory QRVerificationRequest({
    required String token,
    required String storeId,
  }) = _QRVerificationRequest;

  factory QRVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$QRVerificationRequestFromJson(json);
}

/// QRトークン検証レスポンス
@freezed
class QRVerificationResponse with _$QRVerificationResponse {
  const factory QRVerificationResponse({
    required String uid,
    required QRVerificationStatus status,
    String? jti,
    String? message,
  }) = _QRVerificationResponse;

  factory QRVerificationResponse.fromJson(Map<String, dynamic> json) =>
      _$QRVerificationResponseFromJson(json);
}

/// QRトークン検証ステータス
enum QRVerificationStatus {
  @JsonValue('ok')
  ok,
  @JsonValue('expired')
  expired,
  @JsonValue('invalid')
  invalid,
  @JsonValue('used')
  used,
}

/// QRトークン検証結果（UI表示用）
@freezed
class QRVerificationResult with _$QRVerificationResult {
  const factory QRVerificationResult({
    required bool isSuccess,
    required String message,
    String? uid,
    String? jti,
    QRVerificationStatus? status,
    String? error,
  }) = _QRVerificationResult;
}

/// 店舗設定
@freezed
class StoreSettings with _$StoreSettings {
  const factory StoreSettings({
    required String storeId,
    required String storeName,
    String? description,
  }) = _StoreSettings;

  factory StoreSettings.fromJson(Map<String, dynamic> json) =>
      _$StoreSettingsFromJson(json);
}
