import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 管理者専用: 全承認済み店舗一覧（zukanOrder 順）
final allStoresForAdminProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('stores')
      .where('isApproved', isEqualTo: true)
      .snapshots()
      .map((snap) {
    final docs = snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
    // zukanOrder 順でソート（未設定は末尾に）
    docs.sort((a, b) {
      final aOrder = (a['zukanOrder'] as num?)?.toInt();
      final bOrder = (b['zukanOrder'] as num?)?.toInt();
      if (aOrder == null && bOrder == null) return 0;
      if (aOrder == null) return 1;
      if (bOrder == null) return -1;
      return aOrder.compareTo(bOrder);
    });
    return docs;
  });
});

/// 管理者専用: 店舗作成・リンクコード管理サービス
class AdminStoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// ランダム6文字英数字（大文字+数字）を生成する
  String _generateLinkCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// 次の zukanOrder 番号を取得する（現在の最大値+1）
  Future<int> _getNextZukanOrder() async {
    final snap = await _db
        .collection('stores')
        .where('isApproved', isEqualTo: true)
        .get();
    if (snap.docs.isEmpty) return 1;
    int maxOrder = 0;
    for (final doc in snap.docs) {
      final order = (doc.data()['zukanOrder'] as num?)?.toInt() ?? 0;
      if (order > maxOrder) maxOrder = order;
    }
    return maxOrder + 1;
  }

  /// 店舗を新規作成する（isApproved: true, linkCode 自動生成, zukanOrder 自動採番）
  /// 戻り値: 生成されたリンクコード
  Future<String> createStore({
    required String name,
    required String category,
    String? subCategory,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
    String? phone,
    String businessType = 'individual',
    String? businessName,
    Map<String, Map<String, dynamic>>? businessHours,
    bool isRegularHoliday = false,
    Map<String, String?>? socialMedia,
    String? iconImageUrl,
    String? storeImageUrl,
    Map<String, dynamic>? facilityInfo,
    List<String>? tags,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('ログインが必要です');

    final linkCode = _generateLinkCode();
    final docRef = _db.collection('stores').doc();
    final zukanOrder = await _getNextZukanOrder();

    await docRef.set({
      'storeId': docRef.id,
      'name': name,
      'category': category,
      'subCategory': subCategory ?? '',
      'address': address,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'description': description ?? '',
      'phone': phone ?? '',
      'businessType': businessType,
      'businessName': businessName ?? '',
      'businessHours': businessHours ?? {},
      'isRegularHoliday': isRegularHoliday,
      'socialMedia': socialMedia ?? {},
      'iconImageUrl': iconImageUrl,
      'storeImageUrl': storeImageUrl,
      'facilityInfo': facilityInfo ?? {},
      'tags': tags ?? [],
      'isApproved': true,
      'isActive': false,
      'createdByOwner': true,
      'linkCode': linkCode,
      'linkedUids': [],
      'ownerId': uid,
      'createdBy': uid,
      'zukanOrder': zukanOrder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return linkCode;
  }

  /// 図鑑の並び順を一括更新する
  /// storeIds: 新しい順番のstoreIdリスト（インデックス0が1番）
  Future<void> updateZukanOrder(List<String> storeIds) async {
    final batch = _db.batch();
    for (int i = 0; i < storeIds.length; i++) {
      final ref = _db.collection('stores').doc(storeIds[i]);
      batch.update(ref, {
        'zukanOrder': i + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// リンクコードを再生成する
  /// 戻り値: 新しいリンクコード
  Future<String> regenerateLinkCode(String storeId) async {
    final newCode = _generateLinkCode();
    await _db.collection('stores').doc(storeId).update({
      'linkCode': newCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return newCode;
  }

  /// store_icons に画像をアップロードして URL を返す
  Future<String> uploadIconImage(Uint8List bytes) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('store_icons')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    final snap = await ref.putData(bytes);
    return snap.ref.getDownloadURL();
  }

  /// store_images に画像をアップロードして URL を返す
  Future<String> uploadStoreImage(Uint8List bytes) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('store_images')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    final snap = await ref.putData(bytes);
    return snap.ref.getDownloadURL();
  }
}

final adminStoreServiceProvider = Provider<AdminStoreService>((ref) {
  return AdminStoreService();
});
