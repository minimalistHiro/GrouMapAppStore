// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RankingModelImpl _$$RankingModelImplFromJson(Map<String, dynamic> json) =>
    _$RankingModelImpl(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoURL: json['photoURL'] as String?,
      totalPoints: (json['totalPoints'] as num).toInt(),
      currentLevel: (json['currentLevel'] as num).toInt(),
      badgeCount: (json['badgeCount'] as num).toInt(),
      stampCount: (json['stampCount'] as num).toInt(),
      totalPayment: (json['totalPayment'] as num).toInt(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      rank: (json['rank'] as num).toInt(),
      previousRank: (json['previousRank'] as num?)?.toInt() ?? 0,
      rankChange: (json['rankChange'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$RankingModelImplToJson(_$RankingModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'photoURL': instance.photoURL,
      'totalPoints': instance.totalPoints,
      'currentLevel': instance.currentLevel,
      'badgeCount': instance.badgeCount,
      'stampCount': instance.stampCount,
      'totalPayment': instance.totalPayment,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'rank': instance.rank,
      'previousRank': instance.previousRank,
      'rankChange': instance.rankChange,
    };

_$RankingPeriodImpl _$$RankingPeriodImplFromJson(Map<String, dynamic> json) =>
    _$RankingPeriodImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool,
      rewards: (json['rewards'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$RankingPeriodImplToJson(_$RankingPeriodImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'isActive': instance.isActive,
      'rewards': instance.rewards,
    };

_$UserRankingHistoryImpl _$$UserRankingHistoryImplFromJson(
        Map<String, dynamic> json) =>
    _$UserRankingHistoryImpl(
      userId: json['userId'] as String,
      periodId: json['periodId'] as String,
      finalRank: (json['finalRank'] as num).toInt(),
      totalPoints: (json['totalPoints'] as num).toInt(),
      badgeCount: (json['badgeCount'] as num).toInt(),
      achievedAt: DateTime.parse(json['achievedAt'] as String),
      rewardsEarned: (json['rewardsEarned'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$UserRankingHistoryImplToJson(
        _$UserRankingHistoryImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'periodId': instance.periodId,
      'finalRank': instance.finalRank,
      'totalPoints': instance.totalPoints,
      'badgeCount': instance.badgeCount,
      'achievedAt': instance.achievedAt.toIso8601String(),
      'rewardsEarned': instance.rewardsEarned,
    };
