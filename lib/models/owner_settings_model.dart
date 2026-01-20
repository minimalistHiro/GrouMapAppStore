import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerSettings {
  final DateTime? friendCampaignStartDate;
  final DateTime? friendCampaignEndDate;
  final int? friendCampaignPoints;
  final DateTime? storeCampaignStartDate;
  final DateTime? storeCampaignEndDate;
  final int? storeCampaignPoints;
  final double? basePointReturnRate;
  final List<LevelPointReturnRateRange>? levelPointReturnRateRanges;

  const OwnerSettings({
    this.friendCampaignStartDate,
    this.friendCampaignEndDate,
    this.friendCampaignPoints,
    this.storeCampaignStartDate,
    this.storeCampaignEndDate,
    this.storeCampaignPoints,
    this.basePointReturnRate,
    this.levelPointReturnRateRanges,
  });

  factory OwnerSettings.fromMap(Map<String, dynamic> data) {
    return OwnerSettings(
      friendCampaignStartDate: _parseDate(data['friendCampaignStartDate']),
      friendCampaignEndDate: _parseDate(data['friendCampaignEndDate']),
      friendCampaignPoints: _parseInt(data['friendCampaignPoints']),
      storeCampaignStartDate: _parseDate(data['storeCampaignStartDate']),
      storeCampaignEndDate: _parseDate(data['storeCampaignEndDate']),
      storeCampaignPoints: _parseInt(data['storeCampaignPoints']),
      basePointReturnRate: _parseDouble(data['basePointReturnRate']),
      levelPointReturnRateRanges: _parseLevelRateRanges(data['levelPointReturnRateRanges']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'friendCampaignStartDate': _toTimestamp(friendCampaignStartDate),
      'friendCampaignEndDate': _toTimestamp(friendCampaignEndDate),
      'friendCampaignPoints': friendCampaignPoints,
      'storeCampaignStartDate': _toTimestamp(storeCampaignStartDate),
      'storeCampaignEndDate': _toTimestamp(storeCampaignEndDate),
      'storeCampaignPoints': storeCampaignPoints,
      'basePointReturnRate': basePointReturnRate,
      'levelPointReturnRateRanges': _toLevelRateRanges(levelPointReturnRateRanges),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static Timestamp? _toTimestamp(DateTime? value) {
    if (value == null) {
      return null;
    }
    return Timestamp.fromDate(value);
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static List<LevelPointReturnRateRange>? _parseLevelRateRanges(dynamic value) {
    if (value is! List) {
      return null;
    }
    final List<LevelPointReturnRateRange> result = [];
    for (final item in value) {
      if (item is! Map) {
        continue;
      }
      final minLevel = _parseInt(item['minLevel']);
      final maxLevel = _parseInt(item['maxLevel']);
      final rate = _parseDouble(item['rate']);
      if (minLevel != null && rate != null) {
        result.add(LevelPointReturnRateRange(
          minLevel: minLevel,
          maxLevel: maxLevel,
          rate: rate,
        ));
      }
    }
    return result.isEmpty ? null : result;
  }

  static List<Map<String, dynamic>>? _toLevelRateRanges(
    List<LevelPointReturnRateRange>? ranges,
  ) {
    if (ranges == null || ranges.isEmpty) {
      return null;
    }
    return ranges
        .map((range) => {
              'minLevel': range.minLevel,
              'maxLevel': range.maxLevel,
              'rate': range.rate,
            })
        .toList();
  }
}

class LevelPointReturnRateRange {
  final int minLevel;
  final int? maxLevel;
  final double rate;

  const LevelPointReturnRateRange({
    required this.minLevel,
    required this.maxLevel,
    required this.rate,
  });
}
