import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required DateTime createdAt,
    @Default(false) bool isRead,
    @Default(false) bool isDelivered,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    @Default([]) List<String> tags,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) => _$NotificationModelFromJson(json);
}

@freezed
class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    required String userId,
    @Default(true) bool pushEnabled,
    @Default(true) bool inAppEnabled,
    @Default(true) bool rankingEnabled,
    @Default(true) bool badgeEnabled,
    @Default(true) bool levelUpEnabled,
    @Default(true) bool pointEarnedEnabled,
    @Default(true) bool socialEnabled,
    @Default(true) bool marketingEnabled,
    @Default([]) List<String> quietHours,
    @Default('') String timezone,
  }) = _NotificationSettings;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => _$NotificationSettingsFromJson(json);
}

enum NotificationType {
  @JsonValue('ranking')
  ranking,
  @JsonValue('badge')
  badge,
  @JsonValue('level_up')
  levelUp,
  @JsonValue('point_earned')
  pointEarned,
  @JsonValue('social')
  social,
  @JsonValue('marketing')
  marketing,
  @JsonValue('system')
  system,
  @JsonValue('store_announcement')
  storeAnnouncement,
  @JsonValue('coupon_update')
  couponUpdate,
  @JsonValue('customer_visit')
  customerVisit,
}

enum NotificationPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.ranking:
        return 'ランキング';
      case NotificationType.badge:
        return 'バッジ';
      case NotificationType.levelUp:
        return 'レベルアップ';
      case NotificationType.pointEarned:
        return 'ポイント獲得';
      case NotificationType.social:
        return 'ソーシャル';
      case NotificationType.marketing:
        return 'マーケティング';
      case NotificationType.system:
        return 'システム';
      case NotificationType.storeAnnouncement:
        return '店舗お知らせ';
      case NotificationType.couponUpdate:
        return 'クーポン更新';
      case NotificationType.customerVisit:
        return '顧客訪問';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.ranking:
        return '🏆';
      case NotificationType.badge:
        return '🏅';
      case NotificationType.levelUp:
        return '⭐';
      case NotificationType.pointEarned:
        return '💰';
      case NotificationType.social:
        return '👥';
      case NotificationType.marketing:
        return '📢';
      case NotificationType.system:
        return '⚙️';
      case NotificationType.storeAnnouncement:
        return '📢';
      case NotificationType.couponUpdate:
        return '🎫';
      case NotificationType.customerVisit:
        return '👤';
    }
  }
}
