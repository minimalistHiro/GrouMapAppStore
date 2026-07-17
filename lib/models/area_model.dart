import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// エリアデータモデル
/// Firestore の areas/{areaId} ドキュメントに対応
class AreaModel {
  final String areaId;
  final String name;
  final String? description;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final String? color;
  final bool isActive;
  final int? order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AreaModel({
    required this.areaId,
    required this.name,
    this.description,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    this.color,
    required this.isActive,
    this.order,
    this.createdAt,
    this.updatedAt,
  });

  factory AreaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final center = data['center'];
    double lat = 0.0;
    double lng = 0.0;
    if (center is Map) {
      lat = (center['latitude'] as num?)?.toDouble() ?? 0.0;
      lng = (center['longitude'] as num?)?.toDouble() ?? 0.0;
    }
    return AreaModel(
      areaId: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      centerLatitude: lat,
      centerLongitude: lng,
      radiusMeters: (data['radiusMeters'] as num?)?.toDouble() ?? 500.0,
      color: data['color'] as String?,
      isActive: data['isActive'] as bool? ?? false,
      order: (data['order'] as num?)?.toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory AreaModel.fromMap(Map<String, dynamic> data) {
    final center = data['center'];
    double lat = 0.0;
    double lng = 0.0;
    if (center is Map) {
      lat = (center['latitude'] as num?)?.toDouble() ?? 0.0;
      lng = (center['longitude'] as num?)?.toDouble() ?? 0.0;
    }
    return AreaModel(
      areaId: data['areaId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      centerLatitude: lat,
      centerLongitude: lng,
      radiusMeters: (data['radiusMeters'] as num?)?.toDouble() ?? 500.0,
      color: data['color'] as String?,
      isActive: data['isActive'] as bool? ?? false,
      order: (data['order'] as num?)?.toInt(),
    );
  }

  /// エリアの代表色（不透過）
  Color get displayColor =>
      parseHexColor(color, defaultColor: const Color(0xFFFF6B35));

  /// hex 文字列（例: "#FF6B35"）を Color に変換する
  static Color parseHexColor(String? hexColor,
      {required Color defaultColor}) {
    if (hexColor == null || hexColor.isEmpty) return defaultColor;
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return defaultColor;
  }
}
