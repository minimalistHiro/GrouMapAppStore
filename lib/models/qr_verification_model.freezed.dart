// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_verification_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QRVerificationRequest _$QRVerificationRequestFromJson(
    Map<String, dynamic> json) {
  return _QRVerificationRequest.fromJson(json);
}

/// @nodoc
mixin _$QRVerificationRequest {
  String get token => throw _privateConstructorUsedError;
  String get storeId => throw _privateConstructorUsedError;

  /// Serializes this QRVerificationRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QRVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QRVerificationRequestCopyWith<QRVerificationRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QRVerificationRequestCopyWith<$Res> {
  factory $QRVerificationRequestCopyWith(QRVerificationRequest value,
          $Res Function(QRVerificationRequest) then) =
      _$QRVerificationRequestCopyWithImpl<$Res, QRVerificationRequest>;
  @useResult
  $Res call({String token, String storeId});
}

/// @nodoc
class _$QRVerificationRequestCopyWithImpl<$Res,
        $Val extends QRVerificationRequest>
    implements $QRVerificationRequestCopyWith<$Res> {
  _$QRVerificationRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QRVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? storeId = null,
  }) {
    return _then(_value.copyWith(
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QRVerificationRequestImplCopyWith<$Res>
    implements $QRVerificationRequestCopyWith<$Res> {
  factory _$$QRVerificationRequestImplCopyWith(
          _$QRVerificationRequestImpl value,
          $Res Function(_$QRVerificationRequestImpl) then) =
      __$$QRVerificationRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String token, String storeId});
}

/// @nodoc
class __$$QRVerificationRequestImplCopyWithImpl<$Res>
    extends _$QRVerificationRequestCopyWithImpl<$Res,
        _$QRVerificationRequestImpl>
    implements _$$QRVerificationRequestImplCopyWith<$Res> {
  __$$QRVerificationRequestImplCopyWithImpl(_$QRVerificationRequestImpl _value,
      $Res Function(_$QRVerificationRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of QRVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? storeId = null,
  }) {
    return _then(_$QRVerificationRequestImpl(
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QRVerificationRequestImpl implements _QRVerificationRequest {
  const _$QRVerificationRequestImpl(
      {required this.token, required this.storeId});

  factory _$QRVerificationRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$QRVerificationRequestImplFromJson(json);

  @override
  final String token;
  @override
  final String storeId;

  @override
  String toString() {
    return 'QRVerificationRequest(token: $token, storeId: $storeId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QRVerificationRequestImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.storeId, storeId) || other.storeId == storeId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, token, storeId);

  /// Create a copy of QRVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QRVerificationRequestImplCopyWith<_$QRVerificationRequestImpl>
      get copyWith => __$$QRVerificationRequestImplCopyWithImpl<
          _$QRVerificationRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QRVerificationRequestImplToJson(
      this,
    );
  }
}

abstract class _QRVerificationRequest implements QRVerificationRequest {
  const factory _QRVerificationRequest(
      {required final String token,
      required final String storeId}) = _$QRVerificationRequestImpl;

  factory _QRVerificationRequest.fromJson(Map<String, dynamic> json) =
      _$QRVerificationRequestImpl.fromJson;

  @override
  String get token;
  @override
  String get storeId;

  /// Create a copy of QRVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QRVerificationRequestImplCopyWith<_$QRVerificationRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

QRVerificationResponse _$QRVerificationResponseFromJson(
    Map<String, dynamic> json) {
  return _QRVerificationResponse.fromJson(json);
}

/// @nodoc
mixin _$QRVerificationResponse {
  String get uid => throw _privateConstructorUsedError;
  QRVerificationStatus get status => throw _privateConstructorUsedError;
  String? get jti => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  /// Serializes this QRVerificationResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QRVerificationResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QRVerificationResponseCopyWith<QRVerificationResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QRVerificationResponseCopyWith<$Res> {
  factory $QRVerificationResponseCopyWith(QRVerificationResponse value,
          $Res Function(QRVerificationResponse) then) =
      _$QRVerificationResponseCopyWithImpl<$Res, QRVerificationResponse>;
  @useResult
  $Res call(
      {String uid, QRVerificationStatus status, String? jti, String? message});
}

/// @nodoc
class _$QRVerificationResponseCopyWithImpl<$Res,
        $Val extends QRVerificationResponse>
    implements $QRVerificationResponseCopyWith<$Res> {
  _$QRVerificationResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QRVerificationResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? status = null,
    Object? jti = freezed,
    Object? message = freezed,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as QRVerificationStatus,
      jti: freezed == jti
          ? _value.jti
          : jti // ignore: cast_nullable_to_non_nullable
              as String?,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QRVerificationResponseImplCopyWith<$Res>
    implements $QRVerificationResponseCopyWith<$Res> {
  factory _$$QRVerificationResponseImplCopyWith(
          _$QRVerificationResponseImpl value,
          $Res Function(_$QRVerificationResponseImpl) then) =
      __$$QRVerificationResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid, QRVerificationStatus status, String? jti, String? message});
}

/// @nodoc
class __$$QRVerificationResponseImplCopyWithImpl<$Res>
    extends _$QRVerificationResponseCopyWithImpl<$Res,
        _$QRVerificationResponseImpl>
    implements _$$QRVerificationResponseImplCopyWith<$Res> {
  __$$QRVerificationResponseImplCopyWithImpl(
      _$QRVerificationResponseImpl _value,
      $Res Function(_$QRVerificationResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of QRVerificationResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? status = null,
    Object? jti = freezed,
    Object? message = freezed,
  }) {
    return _then(_$QRVerificationResponseImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as QRVerificationStatus,
      jti: freezed == jti
          ? _value.jti
          : jti // ignore: cast_nullable_to_non_nullable
              as String?,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QRVerificationResponseImpl implements _QRVerificationResponse {
  const _$QRVerificationResponseImpl(
      {required this.uid, required this.status, this.jti, this.message});

  factory _$QRVerificationResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$QRVerificationResponseImplFromJson(json);

  @override
  final String uid;
  @override
  final QRVerificationStatus status;
  @override
  final String? jti;
  @override
  final String? message;

  @override
  String toString() {
    return 'QRVerificationResponse(uid: $uid, status: $status, jti: $jti, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QRVerificationResponseImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.jti, jti) || other.jti == jti) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, uid, status, jti, message);

  /// Create a copy of QRVerificationResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QRVerificationResponseImplCopyWith<_$QRVerificationResponseImpl>
      get copyWith => __$$QRVerificationResponseImplCopyWithImpl<
          _$QRVerificationResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QRVerificationResponseImplToJson(
      this,
    );
  }
}

abstract class _QRVerificationResponse implements QRVerificationResponse {
  const factory _QRVerificationResponse(
      {required final String uid,
      required final QRVerificationStatus status,
      final String? jti,
      final String? message}) = _$QRVerificationResponseImpl;

  factory _QRVerificationResponse.fromJson(Map<String, dynamic> json) =
      _$QRVerificationResponseImpl.fromJson;

  @override
  String get uid;
  @override
  QRVerificationStatus get status;
  @override
  String? get jti;
  @override
  String? get message;

  /// Create a copy of QRVerificationResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QRVerificationResponseImplCopyWith<_$QRVerificationResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$QRVerificationResult {
  bool get isSuccess => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  String? get uid => throw _privateConstructorUsedError;
  String? get jti => throw _privateConstructorUsedError;
  QRVerificationStatus? get status => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of QRVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QRVerificationResultCopyWith<QRVerificationResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QRVerificationResultCopyWith<$Res> {
  factory $QRVerificationResultCopyWith(QRVerificationResult value,
          $Res Function(QRVerificationResult) then) =
      _$QRVerificationResultCopyWithImpl<$Res, QRVerificationResult>;
  @useResult
  $Res call(
      {bool isSuccess,
      String message,
      String? uid,
      String? jti,
      QRVerificationStatus? status,
      String? error});
}

/// @nodoc
class _$QRVerificationResultCopyWithImpl<$Res,
        $Val extends QRVerificationResult>
    implements $QRVerificationResultCopyWith<$Res> {
  _$QRVerificationResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QRVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isSuccess = null,
    Object? message = null,
    Object? uid = freezed,
    Object? jti = freezed,
    Object? status = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      isSuccess: null == isSuccess
          ? _value.isSuccess
          : isSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      uid: freezed == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String?,
      jti: freezed == jti
          ? _value.jti
          : jti // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as QRVerificationStatus?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QRVerificationResultImplCopyWith<$Res>
    implements $QRVerificationResultCopyWith<$Res> {
  factory _$$QRVerificationResultImplCopyWith(_$QRVerificationResultImpl value,
          $Res Function(_$QRVerificationResultImpl) then) =
      __$$QRVerificationResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isSuccess,
      String message,
      String? uid,
      String? jti,
      QRVerificationStatus? status,
      String? error});
}

/// @nodoc
class __$$QRVerificationResultImplCopyWithImpl<$Res>
    extends _$QRVerificationResultCopyWithImpl<$Res, _$QRVerificationResultImpl>
    implements _$$QRVerificationResultImplCopyWith<$Res> {
  __$$QRVerificationResultImplCopyWithImpl(_$QRVerificationResultImpl _value,
      $Res Function(_$QRVerificationResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of QRVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isSuccess = null,
    Object? message = null,
    Object? uid = freezed,
    Object? jti = freezed,
    Object? status = freezed,
    Object? error = freezed,
  }) {
    return _then(_$QRVerificationResultImpl(
      isSuccess: null == isSuccess
          ? _value.isSuccess
          : isSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      uid: freezed == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String?,
      jti: freezed == jti
          ? _value.jti
          : jti // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as QRVerificationStatus?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$QRVerificationResultImpl implements _QRVerificationResult {
  const _$QRVerificationResultImpl(
      {required this.isSuccess,
      required this.message,
      this.uid,
      this.jti,
      this.status,
      this.error});

  @override
  final bool isSuccess;
  @override
  final String message;
  @override
  final String? uid;
  @override
  final String? jti;
  @override
  final QRVerificationStatus? status;
  @override
  final String? error;

  @override
  String toString() {
    return 'QRVerificationResult(isSuccess: $isSuccess, message: $message, uid: $uid, jti: $jti, status: $status, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QRVerificationResultImpl &&
            (identical(other.isSuccess, isSuccess) ||
                other.isSuccess == isSuccess) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.jti, jti) || other.jti == jti) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isSuccess, message, uid, jti, status, error);

  /// Create a copy of QRVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QRVerificationResultImplCopyWith<_$QRVerificationResultImpl>
      get copyWith =>
          __$$QRVerificationResultImplCopyWithImpl<_$QRVerificationResultImpl>(
              this, _$identity);
}

abstract class _QRVerificationResult implements QRVerificationResult {
  const factory _QRVerificationResult(
      {required final bool isSuccess,
      required final String message,
      final String? uid,
      final String? jti,
      final QRVerificationStatus? status,
      final String? error}) = _$QRVerificationResultImpl;

  @override
  bool get isSuccess;
  @override
  String get message;
  @override
  String? get uid;
  @override
  String? get jti;
  @override
  QRVerificationStatus? get status;
  @override
  String? get error;

  /// Create a copy of QRVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QRVerificationResultImplCopyWith<_$QRVerificationResultImpl>
      get copyWith => throw _privateConstructorUsedError;
}

StoreSettings _$StoreSettingsFromJson(Map<String, dynamic> json) {
  return _StoreSettings.fromJson(json);
}

/// @nodoc
mixin _$StoreSettings {
  String get storeId => throw _privateConstructorUsedError;
  String get storeName => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this StoreSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreSettingsCopyWith<StoreSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreSettingsCopyWith<$Res> {
  factory $StoreSettingsCopyWith(
          StoreSettings value, $Res Function(StoreSettings) then) =
      _$StoreSettingsCopyWithImpl<$Res, StoreSettings>;
  @useResult
  $Res call({String storeId, String storeName, String? description});
}

/// @nodoc
class _$StoreSettingsCopyWithImpl<$Res, $Val extends StoreSettings>
    implements $StoreSettingsCopyWith<$Res> {
  _$StoreSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? storeId = null,
    Object? storeName = null,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      storeName: null == storeName
          ? _value.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoreSettingsImplCopyWith<$Res>
    implements $StoreSettingsCopyWith<$Res> {
  factory _$$StoreSettingsImplCopyWith(
          _$StoreSettingsImpl value, $Res Function(_$StoreSettingsImpl) then) =
      __$$StoreSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String storeId, String storeName, String? description});
}

/// @nodoc
class __$$StoreSettingsImplCopyWithImpl<$Res>
    extends _$StoreSettingsCopyWithImpl<$Res, _$StoreSettingsImpl>
    implements _$$StoreSettingsImplCopyWith<$Res> {
  __$$StoreSettingsImplCopyWithImpl(
      _$StoreSettingsImpl _value, $Res Function(_$StoreSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoreSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? storeId = null,
    Object? storeName = null,
    Object? description = freezed,
  }) {
    return _then(_$StoreSettingsImpl(
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      storeName: null == storeName
          ? _value.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreSettingsImpl implements _StoreSettings {
  const _$StoreSettingsImpl(
      {required this.storeId, required this.storeName, this.description});

  factory _$StoreSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreSettingsImplFromJson(json);

  @override
  final String storeId;
  @override
  final String storeName;
  @override
  final String? description;

  @override
  String toString() {
    return 'StoreSettings(storeId: $storeId, storeName: $storeName, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreSettingsImpl &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.storeName, storeName) ||
                other.storeName == storeName) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, storeId, storeName, description);

  /// Create a copy of StoreSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreSettingsImplCopyWith<_$StoreSettingsImpl> get copyWith =>
      __$$StoreSettingsImplCopyWithImpl<_$StoreSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreSettingsImplToJson(
      this,
    );
  }
}

abstract class _StoreSettings implements StoreSettings {
  const factory _StoreSettings(
      {required final String storeId,
      required final String storeName,
      final String? description}) = _$StoreSettingsImpl;

  factory _StoreSettings.fromJson(Map<String, dynamic> json) =
      _$StoreSettingsImpl.fromJson;

  @override
  String get storeId;
  @override
  String get storeName;
  @override
  String? get description;

  /// Create a copy of StoreSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreSettingsImplCopyWith<_$StoreSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
