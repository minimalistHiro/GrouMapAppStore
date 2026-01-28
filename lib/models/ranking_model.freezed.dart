// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ranking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RankingModel _$RankingModelFromJson(Map<String, dynamic> json) {
  return _RankingModel.fromJson(json);
}

/// @nodoc
mixin _$RankingModel {
  String get userId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get photoURL => throw _privateConstructorUsedError;
  int get totalPoints => throw _privateConstructorUsedError;
  int get currentLevel => throw _privateConstructorUsedError;
  int get badgeCount => throw _privateConstructorUsedError;
  int get stampCount => throw _privateConstructorUsedError;
  int get totalPayment => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;
  int get rank => throw _privateConstructorUsedError;
  int get previousRank => throw _privateConstructorUsedError;
  int get rankChange => throw _privateConstructorUsedError;

  /// Serializes this RankingModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RankingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RankingModelCopyWith<RankingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RankingModelCopyWith<$Res> {
  factory $RankingModelCopyWith(
          RankingModel value, $Res Function(RankingModel) then) =
      _$RankingModelCopyWithImpl<$Res, RankingModel>;
  @useResult
  $Res call(
      {String userId,
      String displayName,
      String? photoURL,
      int totalPoints,
      int currentLevel,
      int badgeCount,
      int stampCount,
      int totalPayment,
      DateTime lastUpdated,
      int rank,
      int previousRank,
      int rankChange});
}

/// @nodoc
class _$RankingModelCopyWithImpl<$Res, $Val extends RankingModel>
    implements $RankingModelCopyWith<$Res> {
  _$RankingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RankingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? photoURL = freezed,
    Object? totalPoints = null,
    Object? currentLevel = null,
    Object? badgeCount = null,
    Object? stampCount = null,
    Object? totalPayment = null,
    Object? lastUpdated = null,
    Object? rank = null,
    Object? previousRank = null,
    Object? rankChange = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      currentLevel: null == currentLevel
          ? _value.currentLevel
          : currentLevel // ignore: cast_nullable_to_non_nullable
              as int,
      badgeCount: null == badgeCount
          ? _value.badgeCount
          : badgeCount // ignore: cast_nullable_to_non_nullable
              as int,
      stampCount: null == stampCount
          ? _value.stampCount
          : stampCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalPayment: null == totalPayment
          ? _value.totalPayment
          : totalPayment // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int,
      previousRank: null == previousRank
          ? _value.previousRank
          : previousRank // ignore: cast_nullable_to_non_nullable
              as int,
      rankChange: null == rankChange
          ? _value.rankChange
          : rankChange // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RankingModelImplCopyWith<$Res>
    implements $RankingModelCopyWith<$Res> {
  factory _$$RankingModelImplCopyWith(
          _$RankingModelImpl value, $Res Function(_$RankingModelImpl) then) =
      __$$RankingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String displayName,
      String? photoURL,
      int totalPoints,
      int currentLevel,
      int badgeCount,
      int stampCount,
      int totalPayment,
      DateTime lastUpdated,
      int rank,
      int previousRank,
      int rankChange});
}

/// @nodoc
class __$$RankingModelImplCopyWithImpl<$Res>
    extends _$RankingModelCopyWithImpl<$Res, _$RankingModelImpl>
    implements _$$RankingModelImplCopyWith<$Res> {
  __$$RankingModelImplCopyWithImpl(
      _$RankingModelImpl _value, $Res Function(_$RankingModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of RankingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? photoURL = freezed,
    Object? totalPoints = null,
    Object? currentLevel = null,
    Object? badgeCount = null,
    Object? stampCount = null,
    Object? totalPayment = null,
    Object? lastUpdated = null,
    Object? rank = null,
    Object? previousRank = null,
    Object? rankChange = null,
  }) {
    return _then(_$RankingModelImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      currentLevel: null == currentLevel
          ? _value.currentLevel
          : currentLevel // ignore: cast_nullable_to_non_nullable
              as int,
      badgeCount: null == badgeCount
          ? _value.badgeCount
          : badgeCount // ignore: cast_nullable_to_non_nullable
              as int,
      stampCount: null == stampCount
          ? _value.stampCount
          : stampCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalPayment: null == totalPayment
          ? _value.totalPayment
          : totalPayment // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int,
      previousRank: null == previousRank
          ? _value.previousRank
          : previousRank // ignore: cast_nullable_to_non_nullable
              as int,
      rankChange: null == rankChange
          ? _value.rankChange
          : rankChange // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RankingModelImpl implements _RankingModel {
  const _$RankingModelImpl(
      {required this.userId,
      required this.displayName,
      required this.photoURL,
      required this.totalPoints,
      required this.currentLevel,
      required this.badgeCount,
      required this.stampCount,
      required this.totalPayment,
      required this.lastUpdated,
      required this.rank,
      this.previousRank = 0,
      this.rankChange = 0});

  factory _$RankingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RankingModelImplFromJson(json);

  @override
  final String userId;
  @override
  final String displayName;
  @override
  final String? photoURL;
  @override
  final int totalPoints;
  @override
  final int currentLevel;
  @override
  final int badgeCount;
  @override
  final int stampCount;
  @override
  final int totalPayment;
  @override
  final DateTime lastUpdated;
  @override
  final int rank;
  @override
  @JsonKey()
  final int previousRank;
  @override
  @JsonKey()
  final int rankChange;

  @override
  String toString() {
    return 'RankingModel(userId: $userId, displayName: $displayName, photoURL: $photoURL, totalPoints: $totalPoints, currentLevel: $currentLevel, badgeCount: $badgeCount, stampCount: $stampCount, totalPayment: $totalPayment, lastUpdated: $lastUpdated, rank: $rank, previousRank: $previousRank, rankChange: $rankChange)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RankingModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.photoURL, photoURL) ||
                other.photoURL == photoURL) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
            (identical(other.currentLevel, currentLevel) ||
                other.currentLevel == currentLevel) &&
            (identical(other.badgeCount, badgeCount) ||
                other.badgeCount == badgeCount) &&
            (identical(other.stampCount, stampCount) ||
                other.stampCount == stampCount) &&
            (identical(other.totalPayment, totalPayment) ||
                other.totalPayment == totalPayment) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.previousRank, previousRank) ||
                other.previousRank == previousRank) &&
            (identical(other.rankChange, rankChange) ||
                other.rankChange == rankChange));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      displayName,
      photoURL,
      totalPoints,
      currentLevel,
      badgeCount,
      stampCount,
      totalPayment,
      lastUpdated,
      rank,
      previousRank,
      rankChange);

  /// Create a copy of RankingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RankingModelImplCopyWith<_$RankingModelImpl> get copyWith =>
      __$$RankingModelImplCopyWithImpl<_$RankingModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RankingModelImplToJson(
      this,
    );
  }
}

abstract class _RankingModel implements RankingModel {
  const factory _RankingModel(
      {required final String userId,
      required final String displayName,
      required final String? photoURL,
      required final int totalPoints,
      required final int currentLevel,
      required final int badgeCount,
      required final int stampCount,
      required final int totalPayment,
      required final DateTime lastUpdated,
      required final int rank,
      final int previousRank,
      final int rankChange}) = _$RankingModelImpl;

  factory _RankingModel.fromJson(Map<String, dynamic> json) =
      _$RankingModelImpl.fromJson;

  @override
  String get userId;
  @override
  String get displayName;
  @override
  String? get photoURL;
  @override
  int get totalPoints;
  @override
  int get currentLevel;
  @override
  int get badgeCount;
  @override
  int get stampCount;
  @override
  int get totalPayment;
  @override
  DateTime get lastUpdated;
  @override
  int get rank;
  @override
  int get previousRank;
  @override
  int get rankChange;

  /// Create a copy of RankingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RankingModelImplCopyWith<_$RankingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RankingPeriod _$RankingPeriodFromJson(Map<String, dynamic> json) {
  return _RankingPeriod.fromJson(json);
}

/// @nodoc
mixin _$RankingPeriod {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  List<String> get rewards => throw _privateConstructorUsedError;

  /// Serializes this RankingPeriod to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RankingPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RankingPeriodCopyWith<RankingPeriod> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RankingPeriodCopyWith<$Res> {
  factory $RankingPeriodCopyWith(
          RankingPeriod value, $Res Function(RankingPeriod) then) =
      _$RankingPeriodCopyWithImpl<$Res, RankingPeriod>;
  @useResult
  $Res call(
      {String id,
      String name,
      DateTime startDate,
      DateTime endDate,
      bool isActive,
      List<String> rewards});
}

/// @nodoc
class _$RankingPeriodCopyWithImpl<$Res, $Val extends RankingPeriod>
    implements $RankingPeriodCopyWith<$Res> {
  _$RankingPeriodCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RankingPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? isActive = null,
    Object? rewards = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      rewards: null == rewards
          ? _value.rewards
          : rewards // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RankingPeriodImplCopyWith<$Res>
    implements $RankingPeriodCopyWith<$Res> {
  factory _$$RankingPeriodImplCopyWith(
          _$RankingPeriodImpl value, $Res Function(_$RankingPeriodImpl) then) =
      __$$RankingPeriodImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      DateTime startDate,
      DateTime endDate,
      bool isActive,
      List<String> rewards});
}

/// @nodoc
class __$$RankingPeriodImplCopyWithImpl<$Res>
    extends _$RankingPeriodCopyWithImpl<$Res, _$RankingPeriodImpl>
    implements _$$RankingPeriodImplCopyWith<$Res> {
  __$$RankingPeriodImplCopyWithImpl(
      _$RankingPeriodImpl _value, $Res Function(_$RankingPeriodImpl) _then)
      : super(_value, _then);

  /// Create a copy of RankingPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? isActive = null,
    Object? rewards = null,
  }) {
    return _then(_$RankingPeriodImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      rewards: null == rewards
          ? _value._rewards
          : rewards // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RankingPeriodImpl implements _RankingPeriod {
  const _$RankingPeriodImpl(
      {required this.id,
      required this.name,
      required this.startDate,
      required this.endDate,
      required this.isActive,
      final List<String> rewards = const []})
      : _rewards = rewards;

  factory _$RankingPeriodImpl.fromJson(Map<String, dynamic> json) =>
      _$$RankingPeriodImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final bool isActive;
  final List<String> _rewards;
  @override
  @JsonKey()
  List<String> get rewards {
    if (_rewards is EqualUnmodifiableListView) return _rewards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rewards);
  }

  @override
  String toString() {
    return 'RankingPeriod(id: $id, name: $name, startDate: $startDate, endDate: $endDate, isActive: $isActive, rewards: $rewards)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RankingPeriodImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality().equals(other._rewards, _rewards));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, startDate, endDate,
      isActive, const DeepCollectionEquality().hash(_rewards));

  /// Create a copy of RankingPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RankingPeriodImplCopyWith<_$RankingPeriodImpl> get copyWith =>
      __$$RankingPeriodImplCopyWithImpl<_$RankingPeriodImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RankingPeriodImplToJson(
      this,
    );
  }
}

abstract class _RankingPeriod implements RankingPeriod {
  const factory _RankingPeriod(
      {required final String id,
      required final String name,
      required final DateTime startDate,
      required final DateTime endDate,
      required final bool isActive,
      final List<String> rewards}) = _$RankingPeriodImpl;

  factory _RankingPeriod.fromJson(Map<String, dynamic> json) =
      _$RankingPeriodImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  bool get isActive;
  @override
  List<String> get rewards;

  /// Create a copy of RankingPeriod
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RankingPeriodImplCopyWith<_$RankingPeriodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserRankingHistory _$UserRankingHistoryFromJson(Map<String, dynamic> json) {
  return _UserRankingHistory.fromJson(json);
}

/// @nodoc
mixin _$UserRankingHistory {
  String get userId => throw _privateConstructorUsedError;
  String get periodId => throw _privateConstructorUsedError;
  int get finalRank => throw _privateConstructorUsedError;
  int get totalPoints => throw _privateConstructorUsedError;
  int get badgeCount => throw _privateConstructorUsedError;
  DateTime get achievedAt => throw _privateConstructorUsedError;
  List<String> get rewardsEarned => throw _privateConstructorUsedError;

  /// Serializes this UserRankingHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserRankingHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserRankingHistoryCopyWith<UserRankingHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserRankingHistoryCopyWith<$Res> {
  factory $UserRankingHistoryCopyWith(
          UserRankingHistory value, $Res Function(UserRankingHistory) then) =
      _$UserRankingHistoryCopyWithImpl<$Res, UserRankingHistory>;
  @useResult
  $Res call(
      {String userId,
      String periodId,
      int finalRank,
      int totalPoints,
      int badgeCount,
      DateTime achievedAt,
      List<String> rewardsEarned});
}

/// @nodoc
class _$UserRankingHistoryCopyWithImpl<$Res, $Val extends UserRankingHistory>
    implements $UserRankingHistoryCopyWith<$Res> {
  _$UserRankingHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserRankingHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? periodId = null,
    Object? finalRank = null,
    Object? totalPoints = null,
    Object? badgeCount = null,
    Object? achievedAt = null,
    Object? rewardsEarned = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      periodId: null == periodId
          ? _value.periodId
          : periodId // ignore: cast_nullable_to_non_nullable
              as String,
      finalRank: null == finalRank
          ? _value.finalRank
          : finalRank // ignore: cast_nullable_to_non_nullable
              as int,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      badgeCount: null == badgeCount
          ? _value.badgeCount
          : badgeCount // ignore: cast_nullable_to_non_nullable
              as int,
      achievedAt: null == achievedAt
          ? _value.achievedAt
          : achievedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      rewardsEarned: null == rewardsEarned
          ? _value.rewardsEarned
          : rewardsEarned // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserRankingHistoryImplCopyWith<$Res>
    implements $UserRankingHistoryCopyWith<$Res> {
  factory _$$UserRankingHistoryImplCopyWith(_$UserRankingHistoryImpl value,
          $Res Function(_$UserRankingHistoryImpl) then) =
      __$$UserRankingHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String periodId,
      int finalRank,
      int totalPoints,
      int badgeCount,
      DateTime achievedAt,
      List<String> rewardsEarned});
}

/// @nodoc
class __$$UserRankingHistoryImplCopyWithImpl<$Res>
    extends _$UserRankingHistoryCopyWithImpl<$Res, _$UserRankingHistoryImpl>
    implements _$$UserRankingHistoryImplCopyWith<$Res> {
  __$$UserRankingHistoryImplCopyWithImpl(_$UserRankingHistoryImpl _value,
      $Res Function(_$UserRankingHistoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserRankingHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? periodId = null,
    Object? finalRank = null,
    Object? totalPoints = null,
    Object? badgeCount = null,
    Object? achievedAt = null,
    Object? rewardsEarned = null,
  }) {
    return _then(_$UserRankingHistoryImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      periodId: null == periodId
          ? _value.periodId
          : periodId // ignore: cast_nullable_to_non_nullable
              as String,
      finalRank: null == finalRank
          ? _value.finalRank
          : finalRank // ignore: cast_nullable_to_non_nullable
              as int,
      totalPoints: null == totalPoints
          ? _value.totalPoints
          : totalPoints // ignore: cast_nullable_to_non_nullable
              as int,
      badgeCount: null == badgeCount
          ? _value.badgeCount
          : badgeCount // ignore: cast_nullable_to_non_nullable
              as int,
      achievedAt: null == achievedAt
          ? _value.achievedAt
          : achievedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      rewardsEarned: null == rewardsEarned
          ? _value._rewardsEarned
          : rewardsEarned // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserRankingHistoryImpl implements _UserRankingHistory {
  const _$UserRankingHistoryImpl(
      {required this.userId,
      required this.periodId,
      required this.finalRank,
      required this.totalPoints,
      required this.badgeCount,
      required this.achievedAt,
      final List<String> rewardsEarned = const []})
      : _rewardsEarned = rewardsEarned;

  factory _$UserRankingHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserRankingHistoryImplFromJson(json);

  @override
  final String userId;
  @override
  final String periodId;
  @override
  final int finalRank;
  @override
  final int totalPoints;
  @override
  final int badgeCount;
  @override
  final DateTime achievedAt;
  final List<String> _rewardsEarned;
  @override
  @JsonKey()
  List<String> get rewardsEarned {
    if (_rewardsEarned is EqualUnmodifiableListView) return _rewardsEarned;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rewardsEarned);
  }

  @override
  String toString() {
    return 'UserRankingHistory(userId: $userId, periodId: $periodId, finalRank: $finalRank, totalPoints: $totalPoints, badgeCount: $badgeCount, achievedAt: $achievedAt, rewardsEarned: $rewardsEarned)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserRankingHistoryImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.periodId, periodId) ||
                other.periodId == periodId) &&
            (identical(other.finalRank, finalRank) ||
                other.finalRank == finalRank) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
            (identical(other.badgeCount, badgeCount) ||
                other.badgeCount == badgeCount) &&
            (identical(other.achievedAt, achievedAt) ||
                other.achievedAt == achievedAt) &&
            const DeepCollectionEquality()
                .equals(other._rewardsEarned, _rewardsEarned));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      periodId,
      finalRank,
      totalPoints,
      badgeCount,
      achievedAt,
      const DeepCollectionEquality().hash(_rewardsEarned));

  /// Create a copy of UserRankingHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserRankingHistoryImplCopyWith<_$UserRankingHistoryImpl> get copyWith =>
      __$$UserRankingHistoryImplCopyWithImpl<_$UserRankingHistoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserRankingHistoryImplToJson(
      this,
    );
  }
}

abstract class _UserRankingHistory implements UserRankingHistory {
  const factory _UserRankingHistory(
      {required final String userId,
      required final String periodId,
      required final int finalRank,
      required final int totalPoints,
      required final int badgeCount,
      required final DateTime achievedAt,
      final List<String> rewardsEarned}) = _$UserRankingHistoryImpl;

  factory _UserRankingHistory.fromJson(Map<String, dynamic> json) =
      _$UserRankingHistoryImpl.fromJson;

  @override
  String get userId;
  @override
  String get periodId;
  @override
  int get finalRank;
  @override
  int get totalPoints;
  @override
  int get badgeCount;
  @override
  DateTime get achievedAt;
  @override
  List<String> get rewardsEarned;

  /// Create a copy of UserRankingHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserRankingHistoryImplCopyWith<_$UserRankingHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
