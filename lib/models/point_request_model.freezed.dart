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
  double? get baseRate => throw _privateConstructorUsedError; // 固定1.0
  double? get appliedRate => throw _privateConstructorUsedError; // 最終適用率
  int? get normalPoints => throw _privateConstructorUsedError; // 店舗負担分
  int? get specialPoints => throw _privateConstructorUsedError; // 自社負担分
  int? get totalPoints => throw _privateConstructorUsedError; // 付与合計
  DateTime? get rateCalculatedAt =>
      throw _privateConstructorUsedError; // Functions確定時刻
  String? get rateSource => throw _privateConstructorUsedError;
  String? get campaignId => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // pending, accepted, rejected
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get respondedAt => throw _privateConstructorUsedError;
  String? get respondedBy =>
      throw _privateConstructorUsedError; // リクエストに応答したユーザーのID
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
      double? baseRate,
      double? appliedRate,
      int? normalPoints,
      int? specialPoints,
      int? totalPoints,
      DateTime? rateCalculatedAt,
      String? rateSource,
      String? campaignId,
      String status,
      DateTime createdAt,
      DateTime? respondedAt,
      String? respondedBy,
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
    Object? baseRate = freezed,
    Object? appliedRate = freezed,
    Object? normalPoints = freezed,
    Object? specialPoints = freezed,
    Object? totalPoints = freezed,
    Object? rateCalculatedAt = freezed,
    Object? rateSource = freezed,
    Object? campaignId = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? respondedAt = freezed,
    Object? respondedBy = freezed,
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
      baseRate: freezed == baseRate
          ? _value.baseRate
          : baseRate // ignore: cast_nullable_to_non_nullable
              as double?,
      appliedRate: freezed == appliedRate
          ? _value.appliedRate
          : appliedRate // ignore: cast_nullable_to_non_nullable
              as double?,
      normalPoints: freezed == normalPoints
          ? _value.normalPoints
          : normalPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      specialPoints: freezed == specialPoints
          ? _value.specialPoints
          : specialPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      totalPoints: freezed == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      rateCalculatedAt: freezed == rateCalculatedAt
          ? _value.rateCalculatedAt
          : rateCalculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      rateSource: freezed == rateSource
          ? _value.rateSource
          : rateSource // ignore: cast_nullable_to_non_nullable
              as String?,
      campaignId: freezed == campaignId
          ? _value.campaignId
          : campaignId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      respondedBy: freezed == respondedBy
          ? _value.respondedBy
          : respondedBy // ignore: cast_nullable_to_non_nullable
              as String?,
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
      double? baseRate,
      double? appliedRate,
      int? normalPoints,
      int? specialPoints,
      int? totalPoints,
      DateTime? rateCalculatedAt,
      String? rateSource,
      String? campaignId,
      String status,
      DateTime createdAt,
      DateTime? respondedAt,
      String? respondedBy,
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
    Object? baseRate = freezed,
    Object? appliedRate = freezed,
    Object? normalPoints = freezed,
    Object? specialPoints = freezed,
    Object? totalPoints = freezed,
    Object? rateCalculatedAt = freezed,
    Object? rateSource = freezed,
    Object? campaignId = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? respondedAt = freezed,
    Object? respondedBy = freezed,
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
      baseRate: freezed == baseRate
          ? _value.baseRate
          : baseRate // ignore: cast_nullable_to_non_nullable
              as double?,
      appliedRate: freezed == appliedRate
          ? _value.appliedRate
          : appliedRate // ignore: cast_nullable_to_non_nullable
              as double?,
      normalPoints: freezed == normalPoints
          ? _value.normalPoints
          : normalPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      specialPoints: freezed == specialPoints
          ? _value.specialPoints
          : specialPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      totalPoints: freezed == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int?,
      rateCalculatedAt: freezed == rateCalculatedAt
          ? _value.rateCalculatedAt
          : rateCalculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      rateSource: freezed == rateSource
          ? _value.rateSource
          : rateSource // ignore: cast_nullable_to_non_nullable
              as String?,
      campaignId: freezed == campaignId
          ? _value.campaignId
          : campaignId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      respondedBy: freezed == respondedBy
          ? _value.respondedBy
          : respondedBy // ignore: cast_nullable_to_non_nullable
              as String?,
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
      this.baseRate,
      this.appliedRate,
      this.normalPoints,
      this.specialPoints,
      this.totalPoints,
      this.rateCalculatedAt,
      this.rateSource,
      this.campaignId,
      required this.status,
      required this.createdAt,
      this.respondedAt,
      this.respondedBy,
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
  final double? baseRate;
// 固定1.0
  @override
  final double? appliedRate;
// 最終適用率
  @override
  final int? normalPoints;
// 店舗負担分
  @override
  final int? specialPoints;
// 自社負担分
  @override
  final int? totalPoints;
// 付与合計
  @override
  final DateTime? rateCalculatedAt;
// Functions確定時刻
  @override
  final String? rateSource;
  @override
  final String? campaignId;
  @override
  final String status;
// pending, accepted, rejected
  @override
  final DateTime createdAt;
  @override
  final DateTime? respondedAt;
  @override
  final String? respondedBy;
// リクエストに応答したユーザーのID
  @override
  final String? description;
  @override
  final String? rejectionReason;

  @override
  String toString() {
    return 'PointRequest(id: $id, userId: $userId, storeId: $storeId, storeName: $storeName, amount: $amount, pointsToAward: $pointsToAward, userPoints: $userPoints, baseRate: $baseRate, appliedRate: $appliedRate, normalPoints: $normalPoints, specialPoints: $specialPoints, totalPoints: $totalPoints, rateCalculatedAt: $rateCalculatedAt, rateSource: $rateSource, campaignId: $campaignId, status: $status, createdAt: $createdAt, respondedAt: $respondedAt, respondedBy: $respondedBy, description: $description, rejectionReason: $rejectionReason)';
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
            (identical(other.baseRate, baseRate) ||
                other.baseRate == baseRate) &&
            (identical(other.appliedRate, appliedRate) ||
                other.appliedRate == appliedRate) &&
            (identical(other.normalPoints, normalPoints) ||
                other.normalPoints == normalPoints) &&
            (identical(other.specialPoints, specialPoints) ||
                other.specialPoints == specialPoints) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
            (identical(other.rateCalculatedAt, rateCalculatedAt) ||
                other.rateCalculatedAt == rateCalculatedAt) &&
            (identical(other.rateSource, rateSource) ||
                other.rateSource == rateSource) &&
            (identical(other.campaignId, campaignId) ||
                other.campaignId == campaignId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.respondedAt, respondedAt) ||
                other.respondedAt == respondedAt) &&
            (identical(other.respondedBy, respondedBy) ||
                other.respondedBy == respondedBy) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        userId,
        storeId,
        storeName,
        amount,
        pointsToAward,
        userPoints,
        baseRate,
        appliedRate,
        normalPoints,
        specialPoints,
        totalPoints,
        rateCalculatedAt,
        rateSource,
        campaignId,
        status,
        createdAt,
        respondedAt,
        respondedBy,
        description,
        rejectionReason
      ]);

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
      final double? baseRate,
      final double? appliedRate,
      final int? normalPoints,
      final int? specialPoints,
      final int? totalPoints,
      final DateTime? rateCalculatedAt,
      final String? rateSource,
      final String? campaignId,
      required final String status,
      required final DateTime createdAt,
      final DateTime? respondedAt,
      final String? respondedBy,
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
  double? get baseRate; // 固定1.0
  @override
  double? get appliedRate; // 最終適用率
  @override
  int? get normalPoints; // 店舗負担分
  @override
  int? get specialPoints; // 自社負担分
  @override
  int? get totalPoints; // 付与合計
  @override
  DateTime? get rateCalculatedAt; // Functions確定時刻
  @override
  String? get rateSource;
  @override
  String? get campaignId;
  @override
  String get status; // pending, accepted, rejected
  @override
  DateTime get createdAt;
  @override
  DateTime? get respondedAt;
  @override
  String? get respondedBy; // リクエストに応答したユーザーのID
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
