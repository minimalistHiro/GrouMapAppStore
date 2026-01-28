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

  final visitEntries = visitsSnapshot.docs.map((doc) => doc.data()).toList();
  final Map<String, DateTime> referralUsers = {};
  for (final data in visitEntries) {
    final userId = data['userId'] as String?;
    if (userId == null) continue;
    final visitAt = _parseTimestamp(data['visitAt']) ?? _parseTimestamp(data['firstPointAwardAt']);
    if (visitAt == null) continue;
    final existing = referralUsers[userId];
    if (existing == null || visitAt.isBefore(existing)) {
      referralUsers[userId] = visitAt;
    }
  }

  int referralRevenue = 0;
  int referralLtv30 = 0;

  for (final entry in referralUsers.entries) {
    final userId = entry.key;
    final visitAt = entry.value;
    final endAt = visitAt.add(const Duration(days: 30));
    try {
      final transactionsSnapshot = await firestore
          .collection('stores')
          .doc(storeId)
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: visitAt)
          .where('createdAt', isLessThanOrEqualTo: endAt)
          .orderBy('createdAt')
          .get();

      int userTotal = 0;
      int? firstAmount;
      for (final doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amountYen'] as num?)?.toInt()
            ?? (data['amount'] as num?)?.toInt()
            ?? 0;
        userTotal += amount;
        firstAmount ??= amount;
      }

      referralRevenue += firstAmount ?? 0;
      referralLtv30 += userTotal;
    } catch (e) {
      _logFirestoreError('stores/$storeId/transactions', e, storeId);
      rethrow;
    }
  }

  return {
    'firstVisits': visitCount,
    'impressions': impressionsCount,
    'visitRate': visitRate,
    'referralRevenue': referralRevenue,
    'referralLtv30': referralLtv30,
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

DateTime? _parseTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
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
