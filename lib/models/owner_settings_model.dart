import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerSettings {
  final DateTime? friendCampaignStartDate;
  final DateTime? friendCampaignEndDate;
  final int? friendCampaignPoints;
  final DateTime? storeCampaignStartDate;
  final DateTime? storeCampaignEndDate;
  final int? storeCampaignPoints;
  final DateTime? lotteryCampaignStartDate;
  final DateTime? lotteryCampaignEndDate;
  final double? basePointReturnRate;
  final List<LevelPointReturnRateRange>? levelPointReturnRateRanges;
  final DateTime? maintenanceStartDate;
  final DateTime? maintenanceEndDate;
  final String? maintenanceStartTime;
  final String? maintenanceEndTime;
  final String? minRequiredVersion;
  final String? latestVersion;
  final String? iosStoreUrl;
  final String? androidStoreUrl;
  final String? userMinRequiredVersion;
  final String? userLatestVersion;
  final String? userIosStoreUrl;
  final String? userAndroidStoreUrl;

  const OwnerSettings({
    this.friendCampaignStartDate,
    this.friendCampaignEndDate,
    this.friendCampaignPoints,
    this.storeCampaignStartDate,
    this.storeCampaignEndDate,
    this.storeCampaignPoints,
    this.lotteryCampaignStartDate,
    this.lotteryCampaignEndDate,
    this.basePointReturnRate,
    this.levelPointReturnRateRanges,
    this.maintenanceStartDate,
    this.maintenanceEndDate,
    this.maintenanceStartTime,
    this.maintenanceEndTime,
    this.minRequiredVersion,
    this.latestVersion,
    this.iosStoreUrl,
    this.androidStoreUrl,
    this.userMinRequiredVersion,
    this.userLatestVersion,
    this.userIosStoreUrl,
    this.userAndroidStoreUrl,
  });

  factory OwnerSettings.fromMap(Map<String, dynamic> data) {
    return OwnerSettings(
      friendCampaignStartDate: _parseDate(data['friendCampaignStartDate']),
      friendCampaignEndDate: _parseDate(data['friendCampaignEndDate']),
      friendCampaignPoints: _parseInt(data['friendCampaignPoints']),
      storeCampaignStartDate: _parseDate(data['storeCampaignStartDate']),
      storeCampaignEndDate: _parseDate(data['storeCampaignEndDate']),
      storeCampaignPoints: _parseInt(data['storeCampaignPoints']),
      lotteryCampaignStartDate: _parseDate(data['lotteryCampaignStartDate']),
      lotteryCampaignEndDate: _parseDate(data['lotteryCampaignEndDate']),
      basePointReturnRate: _parseDouble(data['basePointReturnRate']),
      levelPointReturnRateRanges: _parseLevelRateRanges(data['levelPointReturnRateRanges']),
      maintenanceStartDate: _parseDate(data['maintenanceStartDate']),
      maintenanceEndDate: _parseDate(data['maintenanceEndDate']),
      maintenanceStartTime: _parseString(data['maintenanceStartTime']),
      maintenanceEndTime: _parseString(data['maintenanceEndTime']),
      minRequiredVersion: _parseString(data['minRequiredVersion']),
      latestVersion: _parseString(data['latestVersion']),
      iosStoreUrl: _parseString(data['iosStoreUrl']),
      androidStoreUrl: _parseString(data['androidStoreUrl']),
      userMinRequiredVersion: _parseString(data['userMinRequiredVersion']),
      userLatestVersion: _parseString(data['userLatestVersion']),
      userIosStoreUrl: _parseString(data['userIosStoreUrl']),
      userAndroidStoreUrl: _parseString(data['userAndroidStoreUrl']),
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
      'lotteryCampaignStartDate': _toTimestamp(lotteryCampaignStartDate),
      'lotteryCampaignEndDate': _toTimestamp(lotteryCampaignEndDate),
      'basePointReturnRate': basePointReturnRate,
      'levelPointReturnRateRanges': _toLevelRateRanges(levelPointReturnRateRanges),
      'maintenanceStartDate': _toTimestamp(maintenanceStartDate),
      'maintenanceEndDate': _toTimestamp(maintenanceEndDate),
      'maintenanceStartTime': maintenanceStartTime,
      'maintenanceEndTime': maintenanceEndTime,
      'minRequiredVersion': minRequiredVersion,
      'latestVersion': latestVersion,
      'iosStoreUrl': iosStoreUrl,
      'androidStoreUrl': androidStoreUrl,
      'userMinRequiredVersion': userMinRequiredVersion,
      'userLatestVersion': userLatestVersion,
      'userIosStoreUrl': userIosStoreUrl,
      'userAndroidStoreUrl': userAndroidStoreUrl,
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

  static String? _parseString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
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
