// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'point_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PointRequest _$PointRequestFromJson(Map<String, dynamic> json) {
  return _PointRequest.fromJson(json);
}

/// @nodoc
mixin _$PointRequest {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get storeId => throw _privateConstructorUsedError;
  String get storeName => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  int get pointsToAward => throw _privateConstructorUsedError;
  int get userPoints => throw _privateConstructorUsedError; // ユーザーに付与されるポイント
  String get status =>
      throw _privateConstructorUsedError; // pending, accepted, rejected
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get respondedAt => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get rejectionReason => throw _privateConstructorUsedError;

  /// Serializes this PointRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PointRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointRequestCopyWith<PointRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointRequestCopyWith<$Res> {
  factory $PointRequestCopyWith(
          PointRequest value, $Res Function(PointRequest) then) =
      _$PointRequestCopyWithImpl<$Res, PointRequest>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String storeId,
      String storeName,
      int amount,
      int pointsToAward,
      int userPoints,
      String status,
      DateTime createdAt,
      DateTime? respondedAt,
      String? description,
      String? rejectionReason});
}

/// @nodoc
class _$PointRequestCopyWithImpl<$Res, $Val extends PointRequest>
    implements $PointRequestCopyWith<$Res> {
  _$PointRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PointRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? storeId = null,
    Object? storeName = null,
    Object? amount = null,
    Object? pointsToAward = null,
    Object? userPoints = null,
    Object? status = null,
    Object? createdAt = null,
    Object? respondedAt = freezed,
    Object? description = freezed,
    Object? rejectionReason = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      storeName: null == storeName
          ? _value.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      pointsToAward: null == pointsToAward
          ? _value.pointsToAward
          : pointsToAward // ignore: cast_nullable_to_non_nullable
              as int,
      userPoints: null == userPoints
          ? _value.userPoints
          : userPoints // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      respondedAt: freezed == respondedAt
          ? _value.respondedAt
          : respondedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PointRequestImplCopyWith<$Res>
    implements $PointRequestCopyWith<$Res> {
  factory _$$PointRequestImplCopyWith(
          _$PointRequestImpl value, $Res Function(_$PointRequestImpl) then) =
      __$$PointRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String storeId,
      String storeName,
      int amount,
      int pointsToAward,
      int userPoints,
      String status,
      DateTime createdAt,
      DateTime? respondedAt,
      String? description,
      String? rejectionReason});
}

/// @nodoc
class __$$PointRequestImplCopyWithImpl<$Res>
    extends _$PointRequestCopyWithImpl<$Res, _$PointRequestImpl>
    implements _$$PointRequestImplCopyWith<$Res> {
  __$$PointRequestImplCopyWithImpl(
      _$PointRequestImpl _value, $Res Function(_$PointRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of PointRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? storeId = null,
    Object? storeName = null,
    Object? amount = null,
    Object? pointsToAward = null,
    Object? userPoints = null,
    Object? status = null,
    Object? createdAt = null,
    Object? respondedAt = freezed,
    Object? description = freezed,
    Object? rejectionReason = freezed,
  }) {
    return _then(_$PointRequestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      storeId: null == storeId
          ? _value.storeId
          : storeId // ignore: cast_nullable_to_non_nullable
              as String,
      storeName: null == storeName
          ? _value.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      pointsToAward: null == pointsToAward
          ? _value.pointsToAward
          : pointsToAward // ignore: cast_nullable_to_non_nullable
              as int,
      userPoints: null == userPoints
          ? _value.userPoints
          : userPoints // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      respondedAt: freezed == respondedAt
          ? _value.respondedAt
          : respondedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointRequestImpl implements _PointRequest {
  const _$PointRequestImpl(
      {required this.id,
      required this.userId,
      required this.storeId,
      required this.storeName,
      required this.amount,
      required this.pointsToAward,
      required this.userPoints,
      required this.status,
      required this.createdAt,
      this.respondedAt,
      this.description,
      this.rejectionReason});

  factory _$PointRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String storeId;
  @override
  final String storeName;
  @override
  final int amount;
  @override
  final int pointsToAward;
  @override
  final int userPoints;
// ユーザーに付与されるポイント
  @override
  final String status;
// pending, accepted, rejected
  @override
  final DateTime createdAt;
  @override
  final DateTime? respondedAt;
  @override
  final String? description;
  @override
  final String? rejectionReason;

  @override
  String toString() {
    return 'PointRequest(id: $id, userId: $userId, storeId: $storeId, storeName: $storeName, amount: $amount, pointsToAward: $pointsToAward, userPoints: $userPoints, status: $status, createdAt: $createdAt, respondedAt: $respondedAt, description: $description, rejectionReason: $rejectionReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.storeId, storeId) || other.storeId == storeId) &&
            (identical(other.storeName, storeName) ||
                other.storeName == storeName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.pointsToAward, pointsToAward) ||
                other.pointsToAward == pointsToAward) &&
            (identical(other.userPoints, userPoints) ||
                other.userPoints == userPoints) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.respondedAt, respondedAt) ||
                other.respondedAt == respondedAt) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      storeId,
      storeName,
      amount,
      pointsToAward,
      userPoints,
      status,
      createdAt,
      respondedAt,
      description,
      rejectionReason);

  /// Create a copy of PointRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointRequestImplCopyWith<_$PointRequestImpl> get copyWith =>
      __$$PointRequestImplCopyWithImpl<_$PointRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PointRequestImplToJson(
      this,
    );
  }
}

abstract class _PointRequest implements PointRequest {
  const factory _PointRequest(
      {required final String id,
      required final String userId,
      required final String storeId,
      required final String storeName,
      required final int amount,
      required final int pointsToAward,
      required final int userPoints,
      required final String status,
      required final DateTime createdAt,
      final DateTime? respondedAt,
      final String? description,
      final String? rejectionReason}) = _$PointRequestImpl;

  factory _PointRequest.fromJson(Map<String, dynamic> json) =
      _$PointRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get storeId;
  @override
  String get storeName;
  @override
  int get amount;
  @override
  int get pointsToAward;
  @override
  int get userPoints; // ユーザーに付与されるポイント
  @override
  String get status; // pending, accepted, rejected
  @override
  DateTime get createdAt;
  @override
  DateTime? get respondedAt;
  @override
  String? get description;
  @override
  String? get rejectionReason;

  /// Create a copy of PointRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointRequestImplCopyWith<_$PointRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
