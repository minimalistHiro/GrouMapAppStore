import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerSettings {
  final DateTime? friendCampaignStartDate;
  final DateTime? friendCampaignEndDate;
  final DateTime? storeCampaignStartDate;
  final DateTime? storeCampaignEndDate;
  final DateTime? lotteryCampaignStartDate;
  final DateTime? lotteryCampaignEndDate;
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
  final int? friendCampaignInviterCoins;
  final int? friendCampaignInviteeCoins;

  const OwnerSettings({
    this.friendCampaignStartDate,
    this.friendCampaignEndDate,
    this.storeCampaignStartDate,
    this.storeCampaignEndDate,
    this.lotteryCampaignStartDate,
    this.lotteryCampaignEndDate,
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
    this.friendCampaignInviterCoins,
    this.friendCampaignInviteeCoins,
  });

  factory OwnerSettings.fromMap(Map<String, dynamic> data) {
    return OwnerSettings(
      friendCampaignStartDate: _parseDate(data['friendCampaignStartDate']),
      friendCampaignEndDate: _parseDate(data['friendCampaignEndDate']),
      storeCampaignStartDate: _parseDate(data['storeCampaignStartDate']),
      storeCampaignEndDate: _parseDate(data['storeCampaignEndDate']),
      lotteryCampaignStartDate: _parseDate(data['lotteryCampaignStartDate']),
      lotteryCampaignEndDate: _parseDate(data['lotteryCampaignEndDate']),
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
      friendCampaignInviterCoins: _parseInt(data['friendCampaignInviterPoints']),
      friendCampaignInviteeCoins: _parseInt(data['friendCampaignInviteePoints']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'friendCampaignStartDate': _toTimestamp(friendCampaignStartDate),
      'friendCampaignEndDate': _toTimestamp(friendCampaignEndDate),
      'storeCampaignStartDate': _toTimestamp(storeCampaignStartDate),
      'storeCampaignEndDate': _toTimestamp(storeCampaignEndDate),
      'lotteryCampaignStartDate': _toTimestamp(lotteryCampaignStartDate),
      'lotteryCampaignEndDate': _toTimestamp(lotteryCampaignEndDate),
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
      'friendCampaignInviterPoints': friendCampaignInviterCoins,
      'friendCampaignInviteePoints': friendCampaignInviteeCoins,
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

  static String? _parseString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
