// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_verification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QRVerificationRequestImpl _$$QRVerificationRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$QRVerificationRequestImpl(
      token: json['token'] as String,
      storeId: json['storeId'] as String,
    );

Map<String, dynamic> _$$QRVerificationRequestImplToJson(
        _$QRVerificationRequestImpl instance) =>
    <String, dynamic>{
      'token': instance.token,
      'storeId': instance.storeId,
    };

_$QRVerificationResponseImpl _$$QRVerificationResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$QRVerificationResponseImpl(
      uid: json['uid'] as String,
      status: $enumDecode(_$QRVerificationStatusEnumMap, json['status']),
      jti: json['jti'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$$QRVerificationResponseImplToJson(
        _$QRVerificationResponseImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'status': _$QRVerificationStatusEnumMap[instance.status]!,
      'jti': instance.jti,
      'message': instance.message,
    };

const _$QRVerificationStatusEnumMap = {
  QRVerificationStatus.ok: 'ok',
  QRVerificationStatus.expired: 'expired',
  QRVerificationStatus.invalid: 'invalid',
  QRVerificationStatus.used: 'used',
};

_$StoreSettingsImpl _$$StoreSettingsImplFromJson(Map<String, dynamic> json) =>
    _$StoreSettingsImpl(
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$StoreSettingsImplToJson(_$StoreSettingsImpl instance) =>
    <String, dynamic>{
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'description': instance.description,
    };
