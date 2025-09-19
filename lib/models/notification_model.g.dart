// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isDelivered: json['isDelivered'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      imageUrl: json['imageUrl'] as String?,
      actionUrl: json['actionUrl'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$$NotificationModelImplToJson(
        _$NotificationModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'body': instance.body,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'isRead': instance.isRead,
      'isDelivered': instance.isDelivered,
      'data': instance.data,
      'imageUrl': instance.imageUrl,
      'actionUrl': instance.actionUrl,
      'tags': instance.tags,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.ranking: 'ranking',
  NotificationType.badge: 'badge',
  NotificationType.levelUp: 'level_up',
  NotificationType.pointEarned: 'point_earned',
  NotificationType.social: 'social',
  NotificationType.marketing: 'marketing',
  NotificationType.system: 'system',
  NotificationType.storeAnnouncement: 'store_announcement',
  NotificationType.couponUpdate: 'coupon_update',
  NotificationType.customerVisit: 'customer_visit',
};

_$NotificationSettingsImpl _$$NotificationSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationSettingsImpl(
      userId: json['userId'] as String,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      inAppEnabled: json['inAppEnabled'] as bool? ?? true,
      rankingEnabled: json['rankingEnabled'] as bool? ?? true,
      badgeEnabled: json['badgeEnabled'] as bool? ?? true,
      levelUpEnabled: json['levelUpEnabled'] as bool? ?? true,
      pointEarnedEnabled: json['pointEarnedEnabled'] as bool? ?? true,
      socialEnabled: json['socialEnabled'] as bool? ?? true,
      marketingEnabled: json['marketingEnabled'] as bool? ?? true,
      quietHours: (json['quietHours'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      timezone: json['timezone'] as String? ?? '',
    );

Map<String, dynamic> _$$NotificationSettingsImplToJson(
        _$NotificationSettingsImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'pushEnabled': instance.pushEnabled,
      'inAppEnabled': instance.inAppEnabled,
      'rankingEnabled': instance.rankingEnabled,
      'badgeEnabled': instance.badgeEnabled,
      'levelUpEnabled': instance.levelUpEnabled,
      'pointEarnedEnabled': instance.pointEarnedEnabled,
      'socialEnabled': instance.socialEnabled,
      'marketingEnabled': instance.marketingEnabled,
      'quietHours': instance.quietHours,
      'timezone': instance.timezone,
    };
