// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) {
  return _NotificationModel.fromJson(json);
}

/// @nodoc
mixin _$NotificationModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  NotificationType get type => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;
  bool get isDelivered => throw _privateConstructorUsedError;
  Map<String, dynamic>? get data => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get actionUrl => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this NotificationModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationModelCopyWith<NotificationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationModelCopyWith<$Res> {
  factory $NotificationModelCopyWith(
          NotificationModel value, $Res Function(NotificationModel) then) =
      _$NotificationModelCopyWithImpl<$Res, NotificationModel>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String title,
      String body,
      NotificationType type,
      DateTime createdAt,
      bool isRead,
      bool isDelivered,
      Map<String, dynamic>? data,
      String? imageUrl,
      String? actionUrl,
      List<String> tags});
}

/// @nodoc
class _$NotificationModelCopyWithImpl<$Res, $Val extends NotificationModel>
    implements $NotificationModelCopyWith<$Res> {
  _$NotificationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? body = null,
    Object? type = null,
    Object? createdAt = null,
    Object? isRead = null,
    Object? isDelivered = null,
    Object? data = freezed,
    Object? imageUrl = freezed,
    Object? actionUrl = freezed,
    Object? tags = null,
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
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      isDelivered: null == isDelivered
          ? _value.isDelivered
          : isDelivered // ignore: cast_nullable_to_non_nullable
              as bool,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      actionUrl: freezed == actionUrl
          ? _value.actionUrl
          : actionUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationModelImplCopyWith<$Res>
    implements $NotificationModelCopyWith<$Res> {
  factory _$$NotificationModelImplCopyWith(_$NotificationModelImpl value,
          $Res Function(_$NotificationModelImpl) then) =
      __$$NotificationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String title,
      String body,
      NotificationType type,
      DateTime createdAt,
      bool isRead,
      bool isDelivered,
      Map<String, dynamic>? data,
      String? imageUrl,
      String? actionUrl,
      List<String> tags});
}

/// @nodoc
class __$$NotificationModelImplCopyWithImpl<$Res>
    extends _$NotificationModelCopyWithImpl<$Res, _$NotificationModelImpl>
    implements _$$NotificationModelImplCopyWith<$Res> {
  __$$NotificationModelImplCopyWithImpl(_$NotificationModelImpl _value,
      $Res Function(_$NotificationModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? body = null,
    Object? type = null,
    Object? createdAt = null,
    Object? isRead = null,
    Object? isDelivered = null,
    Object? data = freezed,
    Object? imageUrl = freezed,
    Object? actionUrl = freezed,
    Object? tags = null,
  }) {
    return _then(_$NotificationModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      isDelivered: null == isDelivered
          ? _value.isDelivered
          : isDelivered // ignore: cast_nullable_to_non_nullable
              as bool,
      data: freezed == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      actionUrl: freezed == actionUrl
          ? _value.actionUrl
          : actionUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationModelImpl implements _NotificationModel {
  const _$NotificationModelImpl(
      {required this.id,
      required this.userId,
      required this.title,
      required this.body,
      required this.type,
      required this.createdAt,
      this.isRead = false,
      this.isDelivered = false,
      final Map<String, dynamic>? data,
      this.imageUrl,
      this.actionUrl,
      final List<String> tags = const []})
      : _data = data,
        _tags = tags;

  factory _$NotificationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String title;
  @override
  final String body;
  @override
  final NotificationType type;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final bool isRead;
  @override
  @JsonKey()
  final bool isDelivered;
  final Map<String, dynamic>? _data;
  @override
  Map<String, dynamic>? get data {
    final value = _data;
    if (value == null) return null;
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? imageUrl;
  @override
  final String? actionUrl;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, title: $title, body: $body, type: $type, createdAt: $createdAt, isRead: $isRead, isDelivered: $isDelivered, data: $data, imageUrl: $imageUrl, actionUrl: $actionUrl, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.isDelivered, isDelivered) ||
                other.isDelivered == isDelivered) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.actionUrl, actionUrl) ||
                other.actionUrl == actionUrl) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      title,
      body,
      type,
      createdAt,
      isRead,
      isDelivered,
      const DeepCollectionEquality().hash(_data),
      imageUrl,
      actionUrl,
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationModelImplCopyWith<_$NotificationModelImpl> get copyWith =>
      __$$NotificationModelImplCopyWithImpl<_$NotificationModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationModelImplToJson(
      this,
    );
  }
}

abstract class _NotificationModel implements NotificationModel {
  const factory _NotificationModel(
      {required final String id,
      required final String userId,
      required final String title,
      required final String body,
      required final NotificationType type,
      required final DateTime createdAt,
      final bool isRead,
      final bool isDelivered,
      final Map<String, dynamic>? data,
      final String? imageUrl,
      final String? actionUrl,
      final List<String> tags}) = _$NotificationModelImpl;

  factory _NotificationModel.fromJson(Map<String, dynamic> json) =
      _$NotificationModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get title;
  @override
  String get body;
  @override
  NotificationType get type;
  @override
  DateTime get createdAt;
  @override
  bool get isRead;
  @override
  bool get isDelivered;
  @override
  Map<String, dynamic>? get data;
  @override
  String? get imageUrl;
  @override
  String? get actionUrl;
  @override
  List<String> get tags;

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationModelImplCopyWith<_$NotificationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NotificationSettings _$NotificationSettingsFromJson(Map<String, dynamic> json) {
  return _NotificationSettings.fromJson(json);
}

/// @nodoc
mixin _$NotificationSettings {
  String get userId => throw _privateConstructorUsedError;
  bool get pushEnabled => throw _privateConstructorUsedError;
  bool get inAppEnabled => throw _privateConstructorUsedError;
  bool get rankingEnabled => throw _privateConstructorUsedError;
  bool get badgeEnabled => throw _privateConstructorUsedError;
  bool get levelUpEnabled => throw _privateConstructorUsedError;
  bool get pointEarnedEnabled => throw _privateConstructorUsedError;
  bool get socialEnabled => throw _privateConstructorUsedError;
  bool get marketingEnabled => throw _privateConstructorUsedError;
  List<String> get quietHours => throw _privateConstructorUsedError;
  String get timezone => throw _privateConstructorUsedError;

  /// Serializes this NotificationSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationSettingsCopyWith<NotificationSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationSettingsCopyWith<$Res> {
  factory $NotificationSettingsCopyWith(NotificationSettings value,
          $Res Function(NotificationSettings) then) =
      _$NotificationSettingsCopyWithImpl<$Res, NotificationSettings>;
  @useResult
  $Res call(
      {String userId,
      bool pushEnabled,
      bool inAppEnabled,
      bool rankingEnabled,
      bool badgeEnabled,
      bool levelUpEnabled,
      bool pointEarnedEnabled,
      bool socialEnabled,
      bool marketingEnabled,
      List<String> quietHours,
      String timezone});
}

/// @nodoc
class _$NotificationSettingsCopyWithImpl<$Res,
        $Val extends NotificationSettings>
    implements $NotificationSettingsCopyWith<$Res> {
  _$NotificationSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? pushEnabled = null,
    Object? inAppEnabled = null,
    Object? rankingEnabled = null,
    Object? badgeEnabled = null,
    Object? levelUpEnabled = null,
    Object? pointEarnedEnabled = null,
    Object? socialEnabled = null,
    Object? marketingEnabled = null,
    Object? quietHours = null,
    Object? timezone = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      pushEnabled: null == pushEnabled
          ? _value.pushEnabled
          : pushEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      inAppEnabled: null == inAppEnabled
          ? _value.inAppEnabled
          : inAppEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      rankingEnabled: null == rankingEnabled
          ? _value.rankingEnabled
          : rankingEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      badgeEnabled: null == badgeEnabled
          ? _value.badgeEnabled
          : badgeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      levelUpEnabled: null == levelUpEnabled
          ? _value.levelUpEnabled
          : levelUpEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      pointEarnedEnabled: null == pointEarnedEnabled
          ? _value.pointEarnedEnabled
          : pointEarnedEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      socialEnabled: null == socialEnabled
          ? _value.socialEnabled
          : socialEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      marketingEnabled: null == marketingEnabled
          ? _value.marketingEnabled
          : marketingEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      quietHours: null == quietHours
          ? _value.quietHours
          : quietHours // ignore: cast_nullable_to_non_nullable
              as List<String>,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationSettingsImplCopyWith<$Res>
    implements $NotificationSettingsCopyWith<$Res> {
  factory _$$NotificationSettingsImplCopyWith(_$NotificationSettingsImpl value,
          $Res Function(_$NotificationSettingsImpl) then) =
      __$$NotificationSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      bool pushEnabled,
      bool inAppEnabled,
      bool rankingEnabled,
      bool badgeEnabled,
      bool levelUpEnabled,
      bool pointEarnedEnabled,
      bool socialEnabled,
      bool marketingEnabled,
      List<String> quietHours,
      String timezone});
}

/// @nodoc
class __$$NotificationSettingsImplCopyWithImpl<$Res>
    extends _$NotificationSettingsCopyWithImpl<$Res, _$NotificationSettingsImpl>
    implements _$$NotificationSettingsImplCopyWith<$Res> {
  __$$NotificationSettingsImplCopyWithImpl(_$NotificationSettingsImpl _value,
      $Res Function(_$NotificationSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of NotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? pushEnabled = null,
    Object? inAppEnabled = null,
    Object? rankingEnabled = null,
    Object? badgeEnabled = null,
    Object? levelUpEnabled = null,
    Object? pointEarnedEnabled = null,
    Object? socialEnabled = null,
    Object? marketingEnabled = null,
    Object? quietHours = null,
    Object? timezone = null,
  }) {
    return _then(_$NotificationSettingsImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      pushEnabled: null == pushEnabled
          ? _value.pushEnabled
          : pushEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      inAppEnabled: null == inAppEnabled
          ? _value.inAppEnabled
          : inAppEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      rankingEnabled: null == rankingEnabled
          ? _value.rankingEnabled
          : rankingEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      badgeEnabled: null == badgeEnabled
          ? _value.badgeEnabled
          : badgeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      levelUpEnabled: null == levelUpEnabled
          ? _value.levelUpEnabled
          : levelUpEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      pointEarnedEnabled: null == pointEarnedEnabled
          ? _value.pointEarnedEnabled
          : pointEarnedEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      socialEnabled: null == socialEnabled
          ? _value.socialEnabled
          : socialEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      marketingEnabled: null == marketingEnabled
          ? _value.marketingEnabled
          : marketingEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      quietHours: null == quietHours
          ? _value._quietHours
          : quietHours // ignore: cast_nullable_to_non_nullable
              as List<String>,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationSettingsImpl implements _NotificationSettings {
  const _$NotificationSettingsImpl(
      {required this.userId,
      this.pushEnabled = true,
      this.inAppEnabled = true,
      this.rankingEnabled = true,
      this.badgeEnabled = true,
      this.levelUpEnabled = true,
      this.pointEarnedEnabled = true,
      this.socialEnabled = true,
      this.marketingEnabled = true,
      final List<String> quietHours = const [],
      this.timezone = ''})
      : _quietHours = quietHours;

  factory _$NotificationSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationSettingsImplFromJson(json);

  @override
  final String userId;
  @override
  @JsonKey()
  final bool pushEnabled;
  @override
  @JsonKey()
  final bool inAppEnabled;
  @override
  @JsonKey()
  final bool rankingEnabled;
  @override
  @JsonKey()
  final bool badgeEnabled;
  @override
  @JsonKey()
  final bool levelUpEnabled;
  @override
  @JsonKey()
  final bool pointEarnedEnabled;
  @override
  @JsonKey()
  final bool socialEnabled;
  @override
  @JsonKey()
  final bool marketingEnabled;
  final List<String> _quietHours;
  @override
  @JsonKey()
  List<String> get quietHours {
    if (_quietHours is EqualUnmodifiableListView) return _quietHours;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_quietHours);
  }

  @override
  @JsonKey()
  final String timezone;

  @override
  String toString() {
    return 'NotificationSettings(userId: $userId, pushEnabled: $pushEnabled, inAppEnabled: $inAppEnabled, rankingEnabled: $rankingEnabled, badgeEnabled: $badgeEnabled, levelUpEnabled: $levelUpEnabled, pointEarnedEnabled: $pointEarnedEnabled, socialEnabled: $socialEnabled, marketingEnabled: $marketingEnabled, quietHours: $quietHours, timezone: $timezone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationSettingsImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.pushEnabled, pushEnabled) ||
                other.pushEnabled == pushEnabled) &&
            (identical(other.inAppEnabled, inAppEnabled) ||
                other.inAppEnabled == inAppEnabled) &&
            (identical(other.rankingEnabled, rankingEnabled) ||
                other.rankingEnabled == rankingEnabled) &&
            (identical(other.badgeEnabled, badgeEnabled) ||
                other.badgeEnabled == badgeEnabled) &&
            (identical(other.levelUpEnabled, levelUpEnabled) ||
                other.levelUpEnabled == levelUpEnabled) &&
            (identical(other.pointEarnedEnabled, pointEarnedEnabled) ||
                other.pointEarnedEnabled == pointEarnedEnabled) &&
            (identical(other.socialEnabled, socialEnabled) ||
                other.socialEnabled == socialEnabled) &&
            (identical(other.marketingEnabled, marketingEnabled) ||
                other.marketingEnabled == marketingEnabled) &&
            const DeepCollectionEquality()
                .equals(other._quietHours, _quietHours) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      pushEnabled,
      inAppEnabled,
      rankingEnabled,
      badgeEnabled,
      levelUpEnabled,
      pointEarnedEnabled,
      socialEnabled,
      marketingEnabled,
      const DeepCollectionEquality().hash(_quietHours),
      timezone);

  /// Create a copy of NotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationSettingsImplCopyWith<_$NotificationSettingsImpl>
      get copyWith =>
          __$$NotificationSettingsImplCopyWithImpl<_$NotificationSettingsImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationSettingsImplToJson(
      this,
    );
  }
}

abstract class _NotificationSettings implements NotificationSettings {
  const factory _NotificationSettings(
      {required final String userId,
      final bool pushEnabled,
      final bool inAppEnabled,
      final bool rankingEnabled,
      final bool badgeEnabled,
      final bool levelUpEnabled,
      final bool pointEarnedEnabled,
      final bool socialEnabled,
      final bool marketingEnabled,
      final List<String> quietHours,
      final String timezone}) = _$NotificationSettingsImpl;

  factory _NotificationSettings.fromJson(Map<String, dynamic> json) =
      _$NotificationSettingsImpl.fromJson;

  @override
  String get userId;
  @override
  bool get pushEnabled;
  @override
  bool get inAppEnabled;
  @override
  bool get rankingEnabled;
  @override
  bool get badgeEnabled;
  @override
  bool get levelUpEnabled;
  @override
  bool get pointEarnedEnabled;
  @override
  bool get socialEnabled;
  @override
  bool get marketingEnabled;
  @override
  List<String> get quietHours;
  @override
  String get timezone;

  /// Create a copy of NotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationSettingsImplCopyWith<_$NotificationSettingsImpl>
      get copyWith => throw _privateConstructorUsedError;
}
