// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_token_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QRToken _$QRTokenFromJson(Map<String, dynamic> json) {
  return _QRToken.fromJson(json);
}

/// @nodoc
mixin _$QRToken {
  String get userId => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String get securityHash => throw _privateConstructorUsedError;

  /// Serializes this QRToken to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QRToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QRTokenCopyWith<QRToken> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QRTokenCopyWith<$Res> {
  factory $QRTokenCopyWith(QRToken value, $Res Function(QRToken) then) =
      _$QRTokenCopyWithImpl<$Res, QRToken>;
  @useResult
  $Res call({String userId, DateTime timestamp, String securityHash});
}

/// @nodoc
class _$QRTokenCopyWithImpl<$Res, $Val extends QRToken>
    implements $QRTokenCopyWith<$Res> {
  _$QRTokenCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QRToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? timestamp = null,
    Object? securityHash = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      securityHash: null == securityHash
          ? _value.securityHash
          : securityHash // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QRTokenImplCopyWith<$Res> implements $QRTokenCopyWith<$Res> {
  factory _$$QRTokenImplCopyWith(
          _$QRTokenImpl value, $Res Function(_$QRTokenImpl) then) =
      __$$QRTokenImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String userId, DateTime timestamp, String securityHash});
}

/// @nodoc
class __$$QRTokenImplCopyWithImpl<$Res>
    extends _$QRTokenCopyWithImpl<$Res, _$QRTokenImpl>
    implements _$$QRTokenImplCopyWith<$Res> {
  __$$QRTokenImplCopyWithImpl(
      _$QRTokenImpl _value, $Res Function(_$QRTokenImpl) _then)
      : super(_value, _then);

  /// Create a copy of QRToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? timestamp = null,
    Object? securityHash = null,
  }) {
    return _then(_$QRTokenImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      securityHash: null == securityHash
          ? _value.securityHash
          : securityHash // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QRTokenImpl implements _QRToken {
  const _$QRTokenImpl(
      {required this.userId,
      required this.timestamp,
      required this.securityHash});

  factory _$QRTokenImpl.fromJson(Map<String, dynamic> json) =>
      _$$QRTokenImplFromJson(json);

  @override
  final String userId;
  @override
  final DateTime timestamp;
  @override
  final String securityHash;

  @override
  String toString() {
    return 'QRToken(userId: $userId, timestamp: $timestamp, securityHash: $securityHash)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QRTokenImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.securityHash, securityHash) ||
                other.securityHash == securityHash));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, timestamp, securityHash);

  /// Create a copy of QRToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QRTokenImplCopyWith<_$QRTokenImpl> get copyWith =>
      __$$QRTokenImplCopyWithImpl<_$QRTokenImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QRTokenImplToJson(
      this,
    );
  }
}

abstract class _QRToken implements QRToken {
  const factory _QRToken(
      {required final String userId,
      required final DateTime timestamp,
      required final String securityHash}) = _$QRTokenImpl;

  factory _QRToken.fromJson(Map<String, dynamic> json) = _$QRTokenImpl.fromJson;

  @override
  String get userId;
  @override
  DateTime get timestamp;
  @override
  String get securityHash;

  /// Create a copy of QRToken
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QRTokenImplCopyWith<_$QRTokenImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$QRTokenValidationResult {
  bool get isValid => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  QRToken? get token => throw _privateConstructorUsedError;
  QRTokenError? get error => throw _privateConstructorUsedError;

  /// Create a copy of QRTokenValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QRTokenValidationResultCopyWith<QRTokenValidationResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QRTokenValidationResultCopyWith<$Res> {
  factory $QRTokenValidationResultCopyWith(QRTokenValidationResult value,
          $Res Function(QRTokenValidationResult) then) =
      _$QRTokenValidationResultCopyWithImpl<$Res, QRTokenValidationResult>;
  @useResult
  $Res call(
      {bool isValid, String message, QRToken? token, QRTokenError? error});

  $QRTokenCopyWith<$Res>? get token;
}

/// @nodoc
class _$QRTokenValidationResultCopyWithImpl<$Res,
        $Val extends QRTokenValidationResult>
    implements $QRTokenValidationResultCopyWith<$Res> {
  _$QRTokenValidationResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QRTokenValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isValid = null,
    Object? message = null,
    Object? token = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      token: freezed == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as QRToken?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as QRTokenError?,
    ) as $Val);
  }

  /// Create a copy of QRTokenValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $QRTokenCopyWith<$Res>? get token {
    if (_value.token == null) {
      return null;
    }

    return $QRTokenCopyWith<$Res>(_value.token!, (value) {
      return _then(_value.copyWith(token: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$QRTokenValidationResultImplCopyWith<$Res>
    implements $QRTokenValidationResultCopyWith<$Res> {
  factory _$$QRTokenValidationResultImplCopyWith(
          _$QRTokenValidationResultImpl value,
          $Res Function(_$QRTokenValidationResultImpl) then) =
      __$$QRTokenValidationResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isValid, String message, QRToken? token, QRTokenError? error});

  @override
  $QRTokenCopyWith<$Res>? get token;
}

/// @nodoc
class __$$QRTokenValidationResultImplCopyWithImpl<$Res>
    extends _$QRTokenValidationResultCopyWithImpl<$Res,
        _$QRTokenValidationResultImpl>
    implements _$$QRTokenValidationResultImplCopyWith<$Res> {
  __$$QRTokenValidationResultImplCopyWithImpl(
      _$QRTokenValidationResultImpl _value,
      $Res Function(_$QRTokenValidationResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of QRTokenValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isValid = null,
    Object? message = null,
    Object? token = freezed,
    Object? error = freezed,
  }) {
    return _then(_$QRTokenValidationResultImpl(
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      token: freezed == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as QRToken?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as QRTokenError?,
    ));
  }
}

/// @nodoc

class _$QRTokenValidationResultImpl implements _QRTokenValidationResult {
  const _$QRTokenValidationResultImpl(
      {required this.isValid, required this.message, this.token, this.error});

  @override
  final bool isValid;
  @override
  final String message;
  @override
  final QRToken? token;
  @override
  final QRTokenError? error;

  @override
  String toString() {
    return 'QRTokenValidationResult(isValid: $isValid, message: $message, token: $token, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QRTokenValidationResultImpl &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isValid, message, token, error);

  /// Create a copy of QRTokenValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QRTokenValidationResultImplCopyWith<_$QRTokenValidationResultImpl>
      get copyWith => __$$QRTokenValidationResultImplCopyWithImpl<
          _$QRTokenValidationResultImpl>(this, _$identity);
}

abstract class _QRTokenValidationResult implements QRTokenValidationResult {
  const factory _QRTokenValidationResult(
      {required final bool isValid,
      required final String message,
      final QRToken? token,
      final QRTokenError? error}) = _$QRTokenValidationResultImpl;

  @override
  bool get isValid;
  @override
  String get message;
  @override
  QRToken? get token;
  @override
  QRTokenError? get error;

  /// Create a copy of QRTokenValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QRTokenValidationResultImplCopyWith<_$QRTokenValidationResultImpl>
      get copyWith => throw _privateConstructorUsedError;
}
