import 'package:freezed_annotation/freezed_annotation.dart';

part 'ranking_model.freezed.dart';
part 'ranking_model.g.dart';

@freezed
class RankingModel with _$RankingModel {
  const factory RankingModel({
    required String userId,
    required String displayName,
    required String? photoURL,
    required int totalPoints,
    required int currentLevel,
    required int badgeCount,
    required int stampCount,
    required int totalPayment,
    required DateTime lastUpdated,
    required int rank,
    @Default(0) int previousRank,
    @Default(0) int rankChange,
  }) = _RankingModel;

  factory RankingModel.fromJson(Map<String, dynamic> json) => _$RankingModelFromJson(json);
}

@freezed
class RankingPeriod with _$RankingPeriod {
  const factory RankingPeriod({
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required bool isActive,
    @Default([]) List<String> rewards,
  }) = _RankingPeriod;

  factory RankingPeriod.fromJson(Map<String, dynamic> json) => _$RankingPeriodFromJson(json);
}

@freezed
class UserRankingHistory with _$UserRankingHistory {
  const factory UserRankingHistory({
    required String userId,
    required String periodId,
    required int finalRank,
    required int totalPoints,
    required int badgeCount,
    required DateTime achievedAt,
    @Default([]) List<String> rewardsEarned,
  }) = _UserRankingHistory;

  factory UserRankingHistory.fromJson(Map<String, dynamic> json) => _$UserRankingHistoryFromJson(json);
}

enum RankingType {
  @JsonValue('total_points')
  totalPoints,
  @JsonValue('badge_count')
  badgeCount,
  @JsonValue('level')
  level,
  @JsonValue('stamp_count')
  stampCount,
  @JsonValue('total_payment')
  totalPayment,
}

enum RankingPeriodType {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('monthly')
  monthly,
  @JsonValue('all_time')
  allTime,
}
