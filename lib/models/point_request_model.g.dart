// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PointRequestImpl _$$PointRequestImplFromJson(Map<String, dynamic> json) =>
    _$PointRequestImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      amount: (json['amount'] as num).toInt(),
      pointsToAward: (json['pointsToAward'] as num).toInt(),
      userPoints: (json['userPoints'] as num).toInt(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
      description: json['description'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$$PointRequestImplToJson(_$PointRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'amount': instance.amount,
      'pointsToAward': instance.pointsToAward,
      'userPoints': instance.userPoints,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
      'description': instance.description,
      'rejectionReason': instance.rejectionReason,
    };
