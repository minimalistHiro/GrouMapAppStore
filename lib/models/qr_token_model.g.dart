// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_token_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QRTokenImpl _$$QRTokenImplFromJson(Map<String, dynamic> json) =>
    _$QRTokenImpl(
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      securityHash: json['securityHash'] as String,
    );

Map<String, dynamic> _$$QRTokenImplToJson(_$QRTokenImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'timestamp': instance.timestamp.toIso8601String(),
      'securityHash': instance.securityHash,
    };
