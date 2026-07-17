import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/area_model.dart';

/// 全エリア一覧（order順）を取得する StreamProvider
final areasAdminProvider = StreamProvider<List<AreaModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('areas')
      .orderBy('order')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => AreaModel.fromFirestore(d)).toList());
});

/// エリア管理サービス
class AreaAdminService {
  final _db = FirebaseFirestore.instance;

  /// エリアを新規作成する
  Future<void> createArea({
    required String name,
    String? description,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String color,
    required int order,
    bool isActive = true,
  }) async {
    final docRef = _db.collection('areas').doc();
    await docRef.set({
      'areaId': docRef.id,
      'name': name,
      'description': description,
      'center': {'latitude': latitude, 'longitude': longitude},
      'radiusMeters': radiusMeters,
      'color': color,
      'isActive': isActive,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// エリアを更新する
  Future<void> updateArea({
    required String areaId,
    required String name,
    String? description,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required String color,
    required int order,
    required bool isActive,
  }) async {
    await _db.collection('areas').doc(areaId).update({
      'name': name,
      'description': description,
      'center': {'latitude': latitude, 'longitude': longitude},
      'radiusMeters': radiusMeters,
      'color': color,
      'isActive': isActive,
      'order': order,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// エリアを無効化する（ソフトデリート）
  Future<void> deactivateArea(String areaId) async {
    await _db.collection('areas').doc(areaId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final areaAdminServiceProvider = Provider<AreaAdminService>((ref) {
  return AreaAdminService();
});
