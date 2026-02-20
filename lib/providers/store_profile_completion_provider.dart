import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_provider.dart';

// メニュー件数の監視
final storeMenuCountProvider =
    StreamProvider.family<int, String>((ref, storeId) {
  return FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .collection('menu')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// 店内画像件数の監視
final storeInteriorImagesCountProvider =
    StreamProvider.family<int, String>((ref, storeId) {
  return FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .collection('interior_images')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// 5項目の完成状態を返すプロバイダー
final storeProfileCompletionProvider =
    Provider.family<StoreProfileCompletion, String>((ref, storeId) {
  final storeData = ref.watch(storeDataProvider(storeId)).valueOrNull;
  final menuCount =
      ref.watch(storeMenuCountProvider(storeId)).valueOrNull ?? 0;
  final imagesCount =
      ref.watch(storeInteriorImagesCountProvider(storeId)).valueOrNull ?? 0;

  if (storeData == null) {
    return StoreProfileCompletion.empty();
  }

  // 1. 店舗プロフィール: name, category, address が空でない
  final name = storeData['name'] as String? ?? '';
  final category = storeData['category'] as String? ?? '';
  final address = storeData['address'] as String? ?? '';
  final isProfileComplete =
      name.trim().isNotEmpty &&
      category.trim().isNotEmpty &&
      address.trim().isNotEmpty;

  // 2. 店舗位置情報: location.latitude, location.longitude が null でない
  final location = storeData['location'] as Map<String, dynamic>?;
  final latitude = location?['latitude'];
  final longitude = location?['longitude'];
  final isLocationComplete = latitude != null && longitude != null;

  // 3. メニュー: 1件以上
  final isMenuComplete = menuCount > 0;

  // 4. 店内画像: 1件以上
  final isImagesComplete = imagesCount > 0;

  // 5. 決済方法: 1つ以上trueの項目がある
  final paymentMethods =
      storeData['paymentMethods'] as Map<String, dynamic>?;
  final isPaymentComplete = _hasAnyPaymentMethodEnabled(paymentMethods);

  return StoreProfileCompletion(
    isProfileComplete: isProfileComplete,
    isLocationComplete: isLocationComplete,
    isMenuComplete: isMenuComplete,
    isImagesComplete: isImagesComplete,
    isPaymentComplete: isPaymentComplete,
  );
});

bool _hasAnyPaymentMethodEnabled(Map<String, dynamic>? paymentMethods) {
  if (paymentMethods == null) return false;
  for (final categoryValue in paymentMethods.values) {
    if (categoryValue is Map) {
      for (final value in categoryValue.values) {
        if (value == true) return true;
      }
    }
  }
  return false;
}

class StoreProfileCompletion {
  final bool isProfileComplete;
  final bool isLocationComplete;
  final bool isMenuComplete;
  final bool isImagesComplete;
  final bool isPaymentComplete;

  StoreProfileCompletion({
    required this.isProfileComplete,
    required this.isLocationComplete,
    required this.isMenuComplete,
    required this.isImagesComplete,
    required this.isPaymentComplete,
  });

  factory StoreProfileCompletion.empty() {
    return StoreProfileCompletion(
      isProfileComplete: false,
      isLocationComplete: false,
      isMenuComplete: false,
      isImagesComplete: false,
      isPaymentComplete: false,
    );
  }

  int get completedCount {
    int count = 0;
    if (isProfileComplete) count++;
    if (isLocationComplete) count++;
    if (isMenuComplete) count++;
    if (isImagesComplete) count++;
    if (isPaymentComplete) count++;
    return count;
  }

  bool get isAllComplete => completedCount == 5;

  /// 次に設定すべき項目のインデックス（0〜4）、全完了ならnull
  int? get nextIncompleteStep {
    if (!isProfileComplete) return 0;
    if (!isLocationComplete) return 1;
    if (!isMenuComplete) return 2;
    if (!isImagesComplete) return 3;
    if (!isPaymentComplete) return 4;
    return null;
  }

  bool getStepComplete(int index) {
    switch (index) {
      case 0:
        return isProfileComplete;
      case 1:
        return isLocationComplete;
      case 2:
        return isMenuComplete;
      case 3:
        return isImagesComplete;
      case 4:
        return isPaymentComplete;
      default:
        return false;
    }
  }
}
