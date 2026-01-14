import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerSettings {
  final DateTime? friendCampaignStartDate;
  final DateTime? friendCampaignEndDate;
  final int? friendCampaignPoints;
  final DateTime? storeCampaignStartDate;
  final DateTime? storeCampaignEndDate;
  final int? storeCampaignPoints;

  const OwnerSettings({
    this.friendCampaignStartDate,
    this.friendCampaignEndDate,
    this.friendCampaignPoints,
    this.storeCampaignStartDate,
    this.storeCampaignEndDate,
    this.storeCampaignPoints,
  });

  factory OwnerSettings.fromMap(Map<String, dynamic> data) {
    return OwnerSettings(
      friendCampaignStartDate: _parseDate(data['friendCampaignStartDate']),
      friendCampaignEndDate: _parseDate(data['friendCampaignEndDate']),
      friendCampaignPoints: _parseInt(data['friendCampaignPoints']),
      storeCampaignStartDate: _parseDate(data['storeCampaignStartDate']),
      storeCampaignEndDate: _parseDate(data['storeCampaignEndDate']),
      storeCampaignPoints: _parseInt(data['storeCampaignPoints']),
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
}
