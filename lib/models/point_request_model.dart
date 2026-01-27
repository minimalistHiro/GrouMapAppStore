import 'package:freezed_annotation/freezed_annotation.dart';

part 'point_request_model.freezed.dart';
part 'point_request_model.g.dart';

@freezed
class PointRequest with _$PointRequest {
  const factory PointRequest({
    required String id,
    required String userId,
    required String storeId,
    required String storeName,
    required int amount,
    required int pointsToAward,
    required int userPoints, // ユーザーに付与されるポイント
    double? baseRate, // 固定1.0
    double? appliedRate, // 最終適用率
    int? normalPoints, // 店舗負担分
    int? specialPoints, // 自社負担分
    int? totalPoints, // 付与合計
    DateTime? rateCalculatedAt, // Functions確定時刻
    String? rateSource,
    String? campaignId,
    required String status, // pending, accepted, rejected
    required DateTime createdAt,
    DateTime? respondedAt,
    String? respondedBy, // リクエストに応答したユーザーのID
    String? description,
    String? rejectionReason,
  }) = _PointRequest;

  factory PointRequest.fromJson(Map<String, dynamic> json) => _$PointRequestFromJson(json);
}

enum PointRequestStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected');

  const PointRequestStatus(this.value);
  final String value;
}
