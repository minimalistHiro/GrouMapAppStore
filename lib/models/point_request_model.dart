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
    required String status, // pending, accepted, rejected
    required DateTime createdAt,
    DateTime? respondedAt,
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
