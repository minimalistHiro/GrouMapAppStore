import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final referralKpiProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, storeId) async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final startDate = now.subtract(const Duration(days: 30));

  QuerySnapshot<Map<String, dynamic>> impressionsSnapshot;
  QuerySnapshot<Map<String, dynamic>> visitsSnapshot;
  QuerySnapshot<Map<String, dynamic>> outboundSnapshot;

  try {
    impressionsSnapshot = await firestore
        .collection('recommendation_impressions')
        .where('targetStoreId', isEqualTo: storeId)
        .where('shownAt', isGreaterThanOrEqualTo: startDate)
        .where('shownAt', isLessThanOrEqualTo: now)
        .get();
  } catch (e) {
    _logFirestoreError('recommendation_impressions', e, storeId);
    rethrow;
  }

  try {
    visitsSnapshot = await firestore
        .collection('recommendation_visits')
        .where('targetStoreId', isEqualTo: storeId)
        .where('visitAt', isGreaterThanOrEqualTo: startDate)
        .where('visitAt', isLessThanOrEqualTo: now)
        .get();
  } catch (e) {
    _logFirestoreError('recommendation_visits(target)', e, storeId);
    rethrow;
  }

  try {
    outboundSnapshot = await firestore
        .collection('recommendation_visits')
        .where('sourceStoreId', isEqualTo: storeId)
        .where('visitAt', isGreaterThanOrEqualTo: startDate)
        .where('visitAt', isLessThanOrEqualTo: now)
        .get();
  } catch (e) {
    _logFirestoreError('recommendation_visits(source)', e, storeId);
    rethrow;
  }

  final impressionsCount = impressionsSnapshot.docs.length;
  final visitCount = visitsSnapshot.docs.length;
  final outboundCount = outboundSnapshot.docs.length;
  final visitRate = impressionsCount > 0
      ? (visitCount / impressionsCount * 100)
      : 0.0;

  return {
    'firstVisits': visitCount,
    'impressions': impressionsCount,
    'visitRate': visitRate,
    'balance': visitCount - outboundCount,
  };
});

final referralSourceRankingProvider = FutureProvider.family<List<Map<String, String>>, String>((ref, storeId) async {
  return _buildReferralRanking(
    storeId: storeId,
    role: _ReferralRole.inbound,
  );
});

final referralTargetRankingProvider = FutureProvider.family<List<Map<String, String>>, String>((ref, storeId) async {
  return _buildReferralRanking(
    storeId: storeId,
    role: _ReferralRole.outbound,
  );
});

Future<List<Map<String, String>>> _buildReferralRanking({
  required String storeId,
  required _ReferralRole role,
}) async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final startDate = now.subtract(const Duration(days: 30));

  Query<Map<String, dynamic>> query = firestore
      .collection('recommendation_visits')
      .where('visitAt', isGreaterThanOrEqualTo: startDate)
      .where('visitAt', isLessThanOrEqualTo: now);

  if (role == _ReferralRole.inbound) {
    query = query.where('targetStoreId', isEqualTo: storeId);
  } else {
    query = query.where('sourceStoreId', isEqualTo: storeId);
  }

  QuerySnapshot<Map<String, dynamic>> snapshot;
  try {
    snapshot = await query.get();
  } catch (e) {
    _logFirestoreError(
      role == _ReferralRole.inbound ? 'recommendation_visits(rank_inbound)' : 'recommendation_visits(rank_outbound)',
      e,
      storeId,
    );
    rethrow;
  }
  final Map<String, int> counter = {};

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final key = role == _ReferralRole.inbound
        ? data['sourceStoreId'] as String?
        : data['targetStoreId'] as String?;
    if (key == null || key.isEmpty) continue;
    counter[key] = (counter[key] ?? 0) + 1;
  }

  final entries = counter.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final topEntries = entries.take(5).toList();
  final List<Map<String, String>> result = [];

  for (final entry in topEntries) {
    final storeName = await _fetchStoreName(entry.key);
    result.add({
      'label': storeName,
      'value': '${entry.value}',
    });
  }

  return result;
}

Future<String> _fetchStoreName(String storeId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .get();
    final data = doc.data();
    if (data == null) {
      return storeId;
    }
    return data['name'] as String? ?? storeId;
  } catch (_) {
    return storeId;
  }
}

enum _ReferralRole { inbound, outbound }

void _logFirestoreError(String label, Object error, String storeId) {
  if (error is FirebaseException) {
    // ignore: avoid_print
    print('[ReferralKpi] $label error for storeId=$storeId code=${error.code} message=${error.message}');
    return;
  }
  // ignore: avoid_print
  print('[ReferralKpi] $label error for storeId=$storeId error=$error');
}
