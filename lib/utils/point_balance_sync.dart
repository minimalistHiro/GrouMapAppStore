import 'package:cloud_firestore/cloud_firestore.dart';

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

Future<void> syncUserPointBalanceFromUserDoc({
  required FirebaseFirestore firestore,
  required String userId,
  String? storeId,
}) async {
  final userDoc = await firestore.collection('users').doc(userId).get();
  if (!userDoc.exists) return;

  final userData = userDoc.data() ?? {};
  final points = _parseInt(userData['points']);
  final specialPoints = _parseInt(userData['specialPoints']);
  final availablePoints = points + specialPoints;

  final balanceRef = firestore.collection('user_point_balances').doc(userId);
  final balanceDoc = await balanceRef.get();
  final usedPoints = _parseInt(balanceDoc.data()?['usedPoints']);
  final totalPoints = availablePoints + usedPoints;

  final updateData = <String, dynamic>{
    'userId': userId,
    'totalPoints': totalPoints,
    'availablePoints': availablePoints,
    'usedPoints': usedPoints,
    'lastUpdated': FieldValue.serverTimestamp(),
  };
  if (storeId != null && storeId.isNotEmpty) {
    updateData['lastUpdatedByStoreId'] = storeId;
  }

  await balanceRef.set(updateData, SetOptions(merge: true));
}
