import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// 店舗データプロバイダー
final storeDataProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    }).handleError((error) {
      debugPrint('Error fetching store data: $error');
      return null;
    });
  } catch (e) {
    debugPrint('Error creating store data stream: $e');
    return Stream.value(null);
  }
});

// 店舗統計プロバイダー
final storeStatsProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, storeId) {
  try {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return FirebaseFirestore.instance
        .collection('point_transactions')
        .where('storeId', isEqualTo: storeId)
        .where('description', whereIn: ['ポイント支払い', 'ポイント利用'])
        .snapshots()
        .map((snapshot) {
      // 今日のデータのみをフィルタリング
      final todayDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        if (createdAt == null) return false;
        
        DateTime docDate;
        if (createdAt is DateTime) {
          docDate = createdAt;
        } else if (createdAt is Timestamp) {
          docDate = createdAt.toDate();
        } else {
          return false;
        }
        
        return docDate.isAfter(startOfDay) && docDate.isBefore(endOfDay);
      }).toList();
      
      final todayVisitors = todayDocs.length;
      final totalPoints = todayDocs.fold<int>(0, (sum, doc) {
        final data = doc.data();
        return sum + ((data['amount'] ?? 0) as int);
      });
      
      return {
        'totalVisits': todayVisitors,
        'totalPoints': totalPoints,
        'activeUsers': todayVisitors, // 今日の訪問者数と同じ
        'couponsUsed': 0, // クーポン使用数は別途実装が必要
      };
    }).handleError((error) {
      debugPrint('Error fetching store stats: $error');
      return {
        'totalVisits': 0,
        'totalPoints': 0,
        'activeUsers': 0,
        'couponsUsed': 0,
      };
    });
  } catch (e) {
    debugPrint('Error creating store stats stream: $e');
    return Stream.value({
      'totalVisits': 0,
      'totalPoints': 0,
      'activeUsers': 0,
      'couponsUsed': 0,
    });
  }
});

// 今日の店舗統計（store_stats/daily から取得）
final todayStoreStatsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, storeId) {
  try {
    final todayKey = _buildDateKey(DateTime.now());
    return FirebaseFirestore.instance
        .collection('store_stats')
        .doc(storeId)
        .collection('daily')
        .doc(todayKey)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data() ?? const <String, dynamic>{};
      return {
        'visitorCount': (data['visitorCount'] as num?)?.toInt() ?? 0,
        'pointsIssued': (data['pointsIssued'] as num?)?.toInt() ?? 0,
      };
    }).handleError((error) {
      debugPrint('Error fetching today store stats: $error');
      return {
        'visitorCount': 0,
        'pointsIssued': 0,
      };
    });
  } catch (e) {
    debugPrint('Error creating today store stats stream: $e');
    return Stream.value({
      'visitorCount': 0,
      'pointsIssued': 0,
    });
  }
});

// 今日の訪問者プロバイダー（point_transactionsから取得）
final todayVisitorsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, storeId) {
  final firestore = FirebaseFirestore.instance;
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final controller = StreamController<List<Map<String, dynamic>>>();
  final Map<String, Map<String, dynamic>> userCache = {};
  StreamSubscription<QuerySnapshot>? usersRootSub;
  StreamSubscription<QuerySnapshot>? transactionsSub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> latestTransactions = [];

  void emitCombined() {
    try {
      final List<Map<String, dynamic>> all = [];
      for (final doc in latestTransactions) {
        final data = doc.data();
        final type = data['type'];
        if (type != 'award' && type != 'sale') continue;
        final createdAt = data['createdAtClient'] ?? data['createdAt'];
        final docDate = _parseCreatedAt(createdAt);
        if (docDate == null) continue;
        if (!docDate.isAfter(startOfDay) || !docDate.isBefore(endOfDay)) continue;

        final userId = data['userId'] as String?;
        final userData = userId != null ? userCache[userId] ?? const <String, dynamic>{} : const <String, dynamic>{};

        String resolveUserName() {
          final displayName = userData['displayName'];
          if (displayName is String && displayName.isNotEmpty) return displayName;
          final email = userData['email'];
          if (email is String && email.isNotEmpty) return email;
          final fallbackName = data['userName'];
          if (fallbackName is String && fallbackName.isNotEmpty) return fallbackName;
          return 'ゲストユーザー';
        }

        String? resolvePhotoUrl() {
          final profileImageUrl = userData['profileImageUrl'];
          if (profileImageUrl is String && profileImageUrl.isNotEmpty) return profileImageUrl;
          final photoUrl = userData['photoUrl'];
          if (photoUrl is String && photoUrl.isNotEmpty) return photoUrl;
          final photoURL = userData['photoURL'];
          if (photoURL is String && photoURL.isNotEmpty) return photoURL;
          return null;
        }

        final pointsEarned = (data['points'] ?? data['pointsAwarded'] ?? data['amount'] ?? 0) as num;

        all.add({
          ...data,
          'transactionId': doc.id,
          'userId': userId,
          'userName': resolveUserName(),
          'userEmail': userData['email'],
          'userPhotoUrl': resolvePhotoUrl(),
          'pointsEarned': pointsEarned.toInt(),
          'timestamp': createdAt,
          'storeName': data['storeName'] ?? '店舗名不明',
        });
      }

      all.sort((a, b) {
        final aTime = _parseCreatedAt(a['timestamp']);
        final bTime = _parseCreatedAt(b['timestamp']);
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      if (!controller.isClosed) controller.add(all);
    } catch (e) {
      debugPrint('Error in emitCombined: $e');
      if (!controller.isClosed) controller.add([]);
    }
  }

  usersRootSub = firestore.collection('users').snapshots().listen((usersSnap) {
    for (final doc in usersSnap.docs) {
      userCache[doc.id] = doc.data();
    }
    emitCombined();
  });

  transactionsSub = firestore
      .collection('stores')
      .doc(storeId)
      .collection('transactions')
      .snapshots()
      .listen((snapshot) {
    latestTransactions = snapshot.docs;
    emitCombined();
  });

  ref.onDispose(() {
    usersRootSub?.cancel();
    transactionsSub?.cancel();
    controller.close();
  });

  return controller.stream;
});

// 店舗利用者推移の状態管理
class StoreUserTrendNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  StoreUserTrendNotifier() : super(const AsyncValue.loading());

  DateTime? _minAvailableDate;
  DateTime? get minAvailableDate => _minAvailableDate;

  // 最後のフェッチパラメータを保持（フィルター変更時の再フェッチ用）
  String? _lastStoreId;
  String _lastPeriod = 'day';
  DateTime? _lastAnchorDate;
  String? get lastPeriod => _lastPeriod;
  DateTime? get lastAnchorDate => _lastAnchorDate;

  Future<void> fetchTrendData(
    String storeId,
    String period, {
    DateTime? anchorDate,
    String? genderFilter,
    String? ageGroupFilter,
  }) async {
    try {
      debugPrint('=== StoreUserTrendNotifier START ===');
      debugPrint('StoreId: $storeId, Period: $period, Gender: $genderFilter, AgeGroup: $ageGroupFilter');

      // パラメータを保存
      _lastStoreId = storeId;
      _lastPeriod = period;
      _lastAnchorDate = anchorDate;

      state = const AsyncValue.loading();

      DateTime startDate;
      DateTime endDate;
      final baseDate = anchorDate ?? DateTime.now();

      switch (period) {
        case 'day':
          startDate = DateTime(baseDate.year, baseDate.month, 1);
          endDate = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);
          break;
        case 'week':
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(baseDate.year, 1, 1);
          endDate = DateTime(baseDate.year, 12, 31, 23, 59, 59, 999);
          break;
        case 'year':
          endDate = baseDate;
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
      }

      debugPrint('Date Range: ${startDate.toLocal()} to ${endDate.toLocal()}');

      final bool hasFilter = genderFilter != null || ageGroupFilter != null;

      final Map<String, int> dailyVisitorCounts = {};
      DateTime? earliestDate;

      if (hasFilter) {
        // フィルター時: stores/{storeId}/transactions から個別トランザクションを取得
        dailyVisitorCounts.addAll(
          await _fetchFilteredDailyData(
            storeId, startDate, endDate,
            genderFilter: genderFilter,
            ageGroupFilter: ageGroupFilter,
          ),
        );
        for (final dateKey in dailyVisitorCounts.keys) {
          final parts = dateKey.split('-');
          if (parts.length == 3) {
            final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            if (earliestDate == null || date.isBefore(earliestDate)) {
              earliestDate = date;
            }
          }
        }
      } else {
        // フィルター無し: 既存の store_stats 高速パス
        for (var date = startDate;
            !date.isAfter(endDate);
            date = date.add(const Duration(days: 1))) {
          final dateKey = _buildDateKey(date);

          final dailyDoc = await FirebaseFirestore.instance
              .collection('store_stats')
              .doc(storeId)
              .collection('daily')
              .doc(dateKey)
              .get();

          if (dailyDoc.exists) {
            final data = dailyDoc.data();
            if (data != null) {
              final visitorCount = (data['visitorCount'] as num?)?.toInt() ?? 0;
              dailyVisitorCounts[dateKey] = visitorCount;

              if (earliestDate == null || date.isBefore(earliestDate!)) {
                earliestDate = date;
              }
            }
          }
        }
      }

      debugPrint('Retrieved ${dailyVisitorCounts.length} days of visitor data');

      // 期間に応じてデータをグループ化
      final Map<String, int> groupedData = {};

      for (final entry in dailyVisitorCounts.entries) {
        final dateStr = entry.key;
        final visitorCount = entry.value;

        final dateParts = dateStr.split('-');
        if (dateParts.length != 3) continue;

        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final docDate = DateTime(year, month, day);

        String groupKey;
        switch (period) {
          case 'day':
          case 'week':
            groupKey = dateStr;
            break;
          case 'month':
            groupKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}';
            break;
          case 'year':
            groupKey = '${docDate.year}';
            break;
          default:
            groupKey = dateStr;
        }

        groupedData[groupKey] = (groupedData[groupKey] ?? 0) + visitorCount;
      }

      // 結果をリストに変換してソート
      final List<Map<String, dynamic>> result;
      if (period == 'day') {
        final days = <Map<String, dynamic>>[];
        for (var date = startDate;
            !date.isAfter(endDate);
            date = date.add(const Duration(days: 1))) {
          final key = _buildDateKey(date);
          days.add({
            'date': key,
            'userCount': groupedData[key] ?? 0,
          });
        }
        result = days;
      } else if (period == 'month') {
        final months = <Map<String, dynamic>>[];
        final now = DateTime.now();
        final maxMonth = baseDate.year == now.year ? now.month : 12;
        for (var month = 1; month <= maxMonth; month++) {
          final key = _buildGroupKey(DateTime(baseDate.year, month, 1), period);
          months.add({
            'date': key,
            'userCount': groupedData[key] ?? 0,
          });
        }
        result = months;
      } else {
        result = groupedData.entries.map((entry) {
          return {
            'date': entry.key,
            'userCount': entry.value,
          };
        }).toList();
      }

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      if (result.isNotEmpty) {
        debugPrint('Sample data: ${result.take(3)}');
      }
      debugPrint('=== StoreUserTrendNotifier END ===');

      _minAvailableDate = earliestDate;
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      debugPrint('Error fetching user trend data: $e');
      debugPrint('StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// フィルター変更時に最後の期間設定で再フェッチ
  Future<void> refetchWithFilters({
    String? genderFilter,
    String? ageGroupFilter,
  }) async {
    if (_lastStoreId == null) return;
    await fetchTrendData(
      _lastStoreId!,
      _lastPeriod,
      anchorDate: _lastAnchorDate,
      genderFilter: genderFilter,
      ageGroupFilter: ageGroupFilter,
    );
  }

  /// フィルター適用時のデータ取得
  /// stores/{storeId}/transactions から日付範囲のトランザクションを取得し、
  /// トランザクション内のuserGender/userAgeGroupで直接フィルタリングして
  /// 日別ユニークユーザー数を返す
  Future<Map<String, int>> _fetchFilteredDailyData(
    String storeId,
    DateTime startDate,
    DateTime endDate, {
    String? genderFilter,
    String? ageGroupFilter,
  }) async {
    // 1. stores/{storeId}/transactions を日付範囲で取得
    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .collection('transactions')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    debugPrint('Filtered query: ${transactionsSnapshot.docs.length} transactions found');

    // 2. トランザクション内の属性で直接フィルター＋日別ユニークユーザー集計
    final Map<String, Set<String>> dailyUniqueUsers = {};

    for (final doc in transactionsSnapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      if (userId == null) continue;

      // 性別フィルター（トランザクションに保存されたuserGenderで判定）
      if (genderFilter != null) {
        final userGender = data['userGender'] as String?;
        if (genderFilter == 'その他') {
          if (userGender != 'その他' && userGender != '回答しない') continue;
        } else {
          if (userGender != genderFilter) continue;
        }
      }

      // 年代フィルター（トランザクションに保存されたuserAgeGroupで判定）
      if (ageGroupFilter != null) {
        final userAgeGroup = data['userAgeGroup'] as String?;
        if (userAgeGroup != ageGroupFilter) continue;
      }

      final createdAt = _parseCreatedAt(data['createdAt'] ?? data['createdAtClient']);
      if (createdAt == null) continue;

      final dateKey = _buildDateKey(createdAt);
      dailyUniqueUsers.putIfAbsent(dateKey, () => {}).add(userId);
    }

    debugPrint('Filtered daily data: ${dailyUniqueUsers.length} days');

    // 3. ユニークユーザー数のMapに変換
    return dailyUniqueUsers.map((key, value) => MapEntry(key, value.length));
  }
}

// 店舗利用者推移プロバイダー（StateNotifier版）
final storeUserTrendNotifierProvider = StateNotifierProvider<StoreUserTrendNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return StoreUserTrendNotifier();
});

DateTime? _parseCreatedAt(dynamic createdAt) {
  if (createdAt == null) return null;
  if (createdAt is DateTime) return createdAt;
  if (createdAt is Timestamp) return createdAt.toDate();
  if (createdAt is String) {
    try {
      return DateTime.parse(createdAt);
    } catch (_) {
      return null;
    }
  }
  return null;
}

bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
  return date.isAfter(start) && date.isBefore(end);
}

String _buildDateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _buildGroupKey(DateTime date, String period) {
  switch (period) {
    case 'day':
    case 'week':
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    case 'month':
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    case 'year':
      return '${date.year}';
    default:
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// 新規顧客推移の状態管理
class NewCustomerTrendNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  NewCustomerTrendNotifier() : super(const AsyncValue.loading());

  DateTime? _minAvailableDate;
  DateTime? get minAvailableDate => _minAvailableDate;

  Future<void> fetchTrendData(String storeId, String period, {DateTime? anchorDate}) async {
    try {
      debugPrint('=== NewCustomerTrendNotifier START ===');
      debugPrint('StoreId: $storeId, Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      DateTime endDate;
      final baseDate = anchorDate ?? DateTime.now();

      switch (period) {
        case 'day':
          startDate = DateTime(baseDate.year, baseDate.month, 1);
          endDate = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);
          break;
        case 'week':
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(baseDate.year, 1, 1);
          endDate = DateTime(baseDate.year, 12, 31, 23, 59, 59, 999);
          break;
        case 'year':
          endDate = baseDate;
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
      }

      debugPrint('Date Range: ${startDate.toLocal()} to ${endDate.toLocal()}');

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      debugPrint('Found ${usersSnapshot.docs.length} users');

      final Map<String, DateTime> firstVisitByUser = {};
      DateTime? earliestDate;

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final transactionsSnapshot = await FirebaseFirestore.instance
            .collection('point_transactions')
            .doc(storeId)
            .collection(userId)
            .where('description', isEqualTo: 'ポイント付与')
            .get();

        for (final transDoc in transactionsSnapshot.docs) {
          final data = transDoc.data();
          final createdAt = data['createdAt'];
          if (createdAt == null) continue;

          DateTime docDate;
          if (createdAt is DateTime) {
            docDate = createdAt;
          } else if (createdAt is Timestamp) {
            docDate = createdAt.toDate();
          } else if (createdAt is String) {
            try {
              docDate = DateTime.parse(createdAt);
            } catch (_) {
              continue;
            }
          } else {
            continue;
          }

          final existing = firstVisitByUser[userId];
          if (existing == null || docDate.isBefore(existing)) {
            firstVisitByUser[userId] = docDate;
          }
          if (earliestDate == null || docDate.isBefore(earliestDate!)) {
            earliestDate = docDate;
          }
        }
      }

      debugPrint('First visits: ${firstVisitByUser.length}');

      final Map<String, int> groupedData = {};
      for (final entry in firstVisitByUser.entries) {
        final visitDate = entry.value;
        final isWithinRange = period == 'day' || period == 'month'
            ? !visitDate.isBefore(startDate) && !visitDate.isAfter(endDate)
            : visitDate.isAfter(startDate) && visitDate.isBefore(endDate);
        if (!isWithinRange) {
          continue;
        }

        String groupKey;
        switch (period) {
          case 'day':
          case 'week':
            groupKey = '${visitDate.year}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')}';
            break;
          case 'month':
            groupKey = '${visitDate.year}-${visitDate.month.toString().padLeft(2, '0')}';
            break;
          case 'year':
            groupKey = '${visitDate.year}';
            break;
          default:
            groupKey = '${visitDate.year}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')}';
        }

        groupedData[groupKey] = (groupedData[groupKey] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> result;
      if (period == 'day') {
        final days = <Map<String, dynamic>>[];
        for (var date = startDate;
            !date.isAfter(endDate);
            date = date.add(const Duration(days: 1))) {
          final key = _buildDateKey(date);
          days.add({
            'date': key,
            'newCustomerCount': groupedData[key] ?? 0,
          });
        }
        result = days;
      } else if (period == 'month') {
        final months = <Map<String, dynamic>>[];
        final now = DateTime.now();
        final maxMonth = baseDate.year == now.year ? now.month : 12;
        for (var month = 1; month <= maxMonth; month++) {
          final key = _buildGroupKey(DateTime(baseDate.year, month, 1), period);
          months.add({
            'date': key,
            'newCustomerCount': groupedData[key] ?? 0,
          });
        }
        result = months;
      } else {
        result = groupedData.entries.map((entry) {
          return {
            'date': entry.key,
            'newCustomerCount': entry.value,
          };
        }).toList();
      }

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      if (result.isNotEmpty) {
        debugPrint('Sample data: ${result.take(3)}');
      }
      debugPrint('=== NewCustomerTrendNotifier END ===');

      _minAvailableDate = earliestDate;
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      debugPrint('Error fetching new customer trend data: $e');
      debugPrint('StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// 新規顧客推移プロバイダー（StateNotifier版）
final newCustomerTrendNotifierProvider = StateNotifierProvider<NewCustomerTrendNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return NewCustomerTrendNotifier();
});

// ポイント発行推移の状態管理
class PointIssueTrendNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  PointIssueTrendNotifier() : super(const AsyncValue.loading());

  DateTime? _minAvailableDate;
  DateTime? get minAvailableDate => _minAvailableDate;

  Future<void> fetchTrendData(String storeId, String period, {DateTime? anchorDate}) async {
    try {
      debugPrint('=== PointIssueTrendNotifier START ===');
      debugPrint('StoreId: $storeId, Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      DateTime endDate;
      final baseDate = anchorDate ?? DateTime.now();

      switch (period) {
        case 'day':
          startDate = DateTime(baseDate.year, baseDate.month, 1);
          endDate = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);
          break;
        case 'week':
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(baseDate.year, 1, 1);
          endDate = DateTime(baseDate.year, 12, 31, 23, 59, 59, 999);
          break;
        case 'year':
          endDate = baseDate;
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
      }

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, int> groupedData = {};
      DateTime? earliestDate;

      for (final userDoc in usersSnapshot.docs) {
        final transactionsSnapshot = await FirebaseFirestore.instance
            .collection('point_transactions')
            .doc(storeId)
            .collection(userDoc.id)
            .where('description', isEqualTo: 'ポイント付与')
            .get();

        for (final transDoc in transactionsSnapshot.docs) {
          final data = transDoc.data();
          final createdAt = _parseCreatedAt(data['createdAt']);
          if (createdAt == null) continue;
          if (earliestDate == null || createdAt.isBefore(earliestDate!)) {
            earliestDate = createdAt;
          }
          final isWithinRange = period == 'day' || period == 'month'
              ? !createdAt.isBefore(startDate) && !createdAt.isAfter(endDate)
              : _isWithinRange(createdAt, startDate, endDate);
          if (!isWithinRange) continue;

          final groupKey = _buildGroupKey(createdAt, period);
          final amount = (data['amount'] as num?)?.toInt() ?? 0;
          groupedData[groupKey] = (groupedData[groupKey] ?? 0) + amount;
        }
      }

      final List<Map<String, dynamic>> result;
      if (period == 'day') {
        final days = <Map<String, dynamic>>[];
        for (var date = startDate;
            !date.isAfter(endDate);
            date = date.add(const Duration(days: 1))) {
          final key = _buildDateKey(date);
          days.add({
            'date': key,
            'pointsIssued': groupedData[key] ?? 0,
          });
        }
        result = days;
      } else if (period == 'month') {
        final months = <Map<String, dynamic>>[];
        final now = DateTime.now();
        final maxMonth = baseDate.year == now.year ? now.month : 12;
        for (var month = 1; month <= maxMonth; month++) {
          final key = _buildGroupKey(DateTime(baseDate.year, month, 1), period);
          months.add({
            'date': key,
            'pointsIssued': groupedData[key] ?? 0,
          });
        }
        result = months;
      } else {
        result = groupedData.entries.map((entry) {
          return {
            'date': entry.key,
            'pointsIssued': entry.value,
          };
        }).toList();
      }

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      debugPrint('=== PointIssueTrendNotifier END ===');

      _minAvailableDate = earliestDate;
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      debugPrint('Error fetching point issue trend data: $e');
      debugPrint('StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final pointIssueTrendNotifierProvider = StateNotifierProvider<PointIssueTrendNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return PointIssueTrendNotifier();
});

// ポイント利用者推移の状態管理
class PointUsageUserTrendNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  PointUsageUserTrendNotifier() : super(const AsyncValue.loading());

  DateTime? _minAvailableDate;
  DateTime? get minAvailableDate => _minAvailableDate;

  Future<void> fetchTrendData(String storeId, String period, {DateTime? anchorDate}) async {
    try {
      debugPrint('=== PointUsageUserTrendNotifier START ===');
      debugPrint('StoreId: $storeId, Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      DateTime endDate;
      final baseDate = anchorDate ?? DateTime.now();

      switch (period) {
        case 'day':
          startDate = DateTime(baseDate.year, baseDate.month, 1);
          endDate = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);
          break;
        case 'week':
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(baseDate.year, 1, 1);
          endDate = DateTime(baseDate.year, 12, 31, 23, 59, 59, 999);
          break;
        case 'year':
          endDate = baseDate;
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
      }

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, Set<String>> groupedUsers = {};
      DateTime? earliestDate;

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final transactionsSnapshot = await FirebaseFirestore.instance
            .collection('point_transactions')
            .doc(storeId)
            .collection(userId)
            .where('description', whereIn: ['ポイント支払い', 'ポイント利用'])
            .get();

        for (final transDoc in transactionsSnapshot.docs) {
          final data = transDoc.data();
          final createdAt = _parseCreatedAt(data['createdAt']);
          if (createdAt == null) continue;
          if (earliestDate == null || createdAt.isBefore(earliestDate!)) {
            earliestDate = createdAt;
          }
          final isWithinRange = period == 'day' || period == 'month'
              ? !createdAt.isBefore(startDate) && !createdAt.isAfter(endDate)
              : _isWithinRange(createdAt, startDate, endDate);
          if (!isWithinRange) continue;

          final groupKey = _buildGroupKey(createdAt, period);
          groupedUsers.putIfAbsent(groupKey, () => <String>{});
          groupedUsers[groupKey]!.add(userId);
        }
      }

      final List<Map<String, dynamic>> result;
      if (period == 'day') {
        final days = <Map<String, dynamic>>[];
        for (var date = startDate;
            !date.isAfter(endDate);
            date = date.add(const Duration(days: 1))) {
          final key = _buildDateKey(date);
          days.add({
            'date': key,
            'pointUsageUsers': groupedUsers[key]?.length ?? 0,
          });
        }
        result = days;
      } else if (period == 'month') {
        final months = <Map<String, dynamic>>[];
        final now = DateTime.now();
        final maxMonth = baseDate.year == now.year ? now.month : 12;
        for (var month = 1; month <= maxMonth; month++) {
          final key = _buildGroupKey(DateTime(baseDate.year, month, 1), period);
          months.add({
            'date': key,
            'pointUsageUsers': groupedUsers[key]?.length ?? 0,
          });
        }
        result = months;
      } else {
        result = groupedUsers.entries.map((entry) {
          return {
            'date': entry.key,
            'pointUsageUsers': entry.value.length,
          };
        }).toList();
      }

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      debugPrint('=== PointUsageUserTrendNotifier END ===');

      _minAvailableDate = earliestDate;
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      debugPrint('Error fetching point usage user trend data: $e');
      debugPrint('StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final pointUsageUserTrendNotifierProvider = StateNotifierProvider<PointUsageUserTrendNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return PointUsageUserTrendNotifier();
});

// 全ユーザー推移の状態管理
class AllUserTrendNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  AllUserTrendNotifier() : super(const AsyncValue.loading());

  DateTime? _minAvailableDate;
  DateTime? get minAvailableDate => _minAvailableDate;

  Future<void> fetchTrendData(String storeId, String period, {DateTime? anchorDate}) async {
    try {
      debugPrint('=== AllUserTrendNotifier START ===');
      debugPrint('Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      DateTime endDate;
      final baseDate = anchorDate ?? DateTime.now();

      switch (period) {
        case 'day':
          startDate = DateTime(baseDate.year, baseDate.month, 1);
          endDate = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);
          break;
        case 'week':
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(baseDate.year, 1, 1);
          endDate = DateTime(baseDate.year, 12, 31, 23, 59, 59, 999);
          break;
        case 'year':
          endDate = baseDate;
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
      }

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, int> groupedUsers = {};
      DateTime? earliestDate;
      int baseCumulative = 0;

      for (final userDoc in usersSnapshot.docs) {
        final data = userDoc.data();
        // isOwner/isStoreOwner を除外
        if (data['isOwner'] == true || data['isStoreOwner'] == true) continue;

        final createdAt = _parseCreatedAt(data['createdAt']);
        if (createdAt == null) continue;
        if (earliestDate == null || createdAt.isBefore(earliestDate!)) {
          earliestDate = createdAt;
        }

        // 表示期間より前のユーザーは baseCumulative にカウント
        if (createdAt.isBefore(startDate)) {
          baseCumulative++;
          continue;
        }

        // 表示期間より後のユーザーはスキップ
        if (createdAt.isAfter(endDate)) continue;

        final groupKey = _buildGroupKey(createdAt, period);
        groupedUsers[groupKey] = (groupedUsers[groupKey] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> result;
      var cumulative = baseCumulative;
      if (period == 'day') {
        final days = <Map<String, dynamic>>[];
        for (var date = startDate;
            !date.isAfter(endDate);
            date = date.add(const Duration(days: 1))) {
          final key = _buildDateKey(date);
          final newUsers = groupedUsers[key] ?? 0;
          cumulative += newUsers;
          days.add({
            'date': key,
            'totalUsers': newUsers,
            'cumulativeUsers': cumulative,
          });
        }
        result = days;
      } else if (period == 'month') {
        final months = <Map<String, dynamic>>[];
        final now = DateTime.now();
        final maxMonth = baseDate.year == now.year ? now.month : 12;
        for (var month = 1; month <= maxMonth; month++) {
          final key = _buildGroupKey(DateTime(baseDate.year, month, 1), period);
          final newUsers = groupedUsers[key] ?? 0;
          cumulative += newUsers;
          months.add({
            'date': key,
            'totalUsers': newUsers,
            'cumulativeUsers': cumulative,
          });
        }
        result = months;
      } else {
        final sorted = groupedUsers.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final items = <Map<String, dynamic>>[];
        for (final entry in sorted) {
          cumulative += entry.value;
          items.add({
            'date': entry.key,
            'totalUsers': entry.value,
            'cumulativeUsers': cumulative,
          });
        }
        result = items;
      }

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      debugPrint('=== AllUserTrendNotifier END ===');

      _minAvailableDate = earliestDate;
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      debugPrint('Error fetching all user trend data: $e');
      debugPrint('StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final allUserTrendNotifierProvider = StateNotifierProvider<AllUserTrendNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AllUserTrendNotifier();
});

// 全ユーザーログイン数推移の状態管理
class AllLoginTrendNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  AllLoginTrendNotifier() : super(const AsyncValue.loading());

  DateTime? _minAvailableDate;
  DateTime? get minAvailableDate => _minAvailableDate;

  Future<void> fetchTrendData(String storeId, String period, {DateTime? anchorDate}) async {
    try {
      debugPrint('=== AllLoginTrendNotifier START ===');

      state = const AsyncValue.loading();

      final baseDate = anchorDate ?? DateTime.now();
      final startDate = DateTime(baseDate.year, baseDate.month, 1);
      final endDate = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);

      final startKey = _buildDateKey(startDate);
      final endKey = _buildDateKey(DateTime(baseDate.year, baseDate.month + 1, 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('daily_login_stats')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
          .where(FieldPath.documentId, isLessThan: endKey)
          .get();

      final Map<String, int> loginsByDate = {};
      DateTime? earliestDate;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final loginCount = data['loginCount'];
        final count = loginCount is int ? loginCount
            : loginCount is num ? loginCount.toInt() : 0;
        loginsByDate[doc.id] = count;

        final date = DateTime.tryParse(doc.id);
        if (date != null) {
          if (earliestDate == null || date.isBefore(earliestDate!)) {
            earliestDate = date;
          }
        }
      }

      final List<Map<String, dynamic>> result = [];
      for (var date = startDate;
          !date.isAfter(endDate);
          date = date.add(const Duration(days: 1))) {
        final key = _buildDateKey(date);
        result.add({
          'date': key,
          'loginCount': loginsByDate[key] ?? 0,
        });
      }

      debugPrint('=== AllLoginTrendNotifier END: ${result.length} data points ===');

      _minAvailableDate = earliestDate;
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      debugPrint('Error fetching all login trend data: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final allLoginTrendNotifierProvider = StateNotifierProvider<AllLoginTrendNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AllLoginTrendNotifier();
});

// 全ポイント発行数推移の状態管理
class TotalPointIssueTrendNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  TotalPointIssueTrendNotifier() : super(const AsyncValue.loading());

  DateTime? _minAvailableDate;
  DateTime? get minAvailableDate => _minAvailableDate;

  Future<void> fetchTrendData(String storeId, String period, {DateTime? anchorDate}) async {
    try {
      debugPrint('=== TotalPointIssueTrendNotifier START ===');
      debugPrint('Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      DateTime endDate;
      final baseDate = anchorDate ?? DateTime.now();

      switch (period) {
        case 'day':
          startDate = DateTime(baseDate.year, baseDate.month, 1);
          endDate = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59, 999);
          break;
        case 'week':
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(baseDate.year, 1, 1);
          endDate = DateTime(baseDate.year, 12, 31, 23, 59, 59, 999);
          break;
        case 'year':
          endDate = baseDate;
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          endDate = baseDate;
          startDate = endDate.subtract(const Duration(days: 7));
      }

      final storesSnapshot = await FirebaseFirestore.instance.collection('stores').get();
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, int> groupedData = {};
      DateTime? earliestDate;

      for (final storeDoc in storesSnapshot.docs) {
        final storeDocId = storeDoc.id;
        for (final userDoc in usersSnapshot.docs) {
          final transactionsSnapshot = await FirebaseFirestore.instance
              .collection('point_transactions')
              .doc(storeDocId)
              .collection(userDoc.id)
              .where('description', isEqualTo: 'ポイント付与')
              .get();

          for (final transDoc in transactionsSnapshot.docs) {
            final data = transDoc.data();
            final createdAt = _parseCreatedAt(data['createdAt']);
            if (createdAt == null) continue;
            if (earliestDate == null || createdAt.isBefore(earliestDate!)) {
              earliestDate = createdAt;
            }
            final isWithinRange = period == 'day' || period == 'month'
                ? !createdAt.isBefore(startDate) && !createdAt.isAfter(endDate)
                : _isWithinRange(createdAt, startDate, endDate);
            if (!isWithinRange) continue;

            final groupKey = _buildGroupKey(createdAt, period);
            final amount = (data['amount'] as num?)?.toInt() ?? 0;
            groupedData[groupKey] = (groupedData[groupKey] ?? 0) + amount;
          }
        }
      }

      final List<Map<String, dynamic>> result;
      if (period == 'day') {
        final days = <Map<String, dynamic>>[];
        for (var date = startDate;
            !date.isAfter(endDate);
            date = date.add(const Duration(days: 1))) {
          final key = _buildDateKey(date);
          days.add({
            'date': key,
            'totalPointsIssued': groupedData[key] ?? 0,
          });
        }
        result = days;
      } else if (period == 'month') {
        final months = <Map<String, dynamic>>[];
        final now = DateTime.now();
        final maxMonth = baseDate.year == now.year ? now.month : 12;
        for (var month = 1; month <= maxMonth; month++) {
          final key = _buildGroupKey(DateTime(baseDate.year, month, 1), period);
          months.add({
            'date': key,
            'totalPointsIssued': groupedData[key] ?? 0,
          });
        }
        result = months;
      } else {
        result = groupedData.entries.map((entry) {
          return {
            'date': entry.key,
            'totalPointsIssued': entry.value,
          };
        }).toList();
      }

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      debugPrint('=== TotalPointIssueTrendNotifier END ===');

      _minAvailableDate = earliestDate;
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      debugPrint('Error fetching total point issue trend data: $e');
      debugPrint('StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final totalPointIssueTrendNotifierProvider = StateNotifierProvider<TotalPointIssueTrendNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return TotalPointIssueTrendNotifier();
});

// 週間統計プロバイダー
final weeklyStatsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('store_stats')
        .doc(storeId)
        .collection('daily')
        .snapshots()
        .asyncMap((_) async {
      final now = DateTime.now();
      final startOfWeek = now.subtract(const Duration(days: 7));
      final startKey = _buildDateKey(startOfWeek);
      final endKey = _buildDateKey(now);

      final dailySnapshot = await FirebaseFirestore.instance
          .collection('store_stats')
          .doc(storeId)
          .collection('daily')
          .where('date', isGreaterThanOrEqualTo: startKey)
          .where('date', isLessThanOrEqualTo: endKey)
          .get();

      int totalSales = 0;
      int visitorCount = 0;
      for (final doc in dailySnapshot.docs) {
        final data = doc.data();
        totalSales += (data['totalSales'] as num?)?.toInt() ?? 0;
        visitorCount += (data['visitorCount'] as num?)?.toInt() ?? 0;
      }

      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('transactions')
          .where('type', isEqualTo: 'stamp')
          .where('createdAt', isGreaterThanOrEqualTo: startOfWeek)
          .where('createdAt', isLessThanOrEqualTo: now)
          .get();

      final userVisitCounts = <String, int>{};
      for (final doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        if (userId == null) continue;
        userVisitCounts[userId] = (userVisitCounts[userId] ?? 0) + 1;
      }
      final uniqueUsers = userVisitCounts.keys.toSet();
      final repeatUsers = userVisitCounts.values.where((count) => count > 1).length;
      final repeatRate = uniqueUsers.isNotEmpty
          ? (repeatUsers / uniqueUsers.length * 100).toInt()
          : 0;

      final newCustomersSnapshot = await FirebaseFirestore.instance
          .collection('store_users')
          .doc(storeId)
          .collection('users')
          .where('firstVisitAt', isGreaterThanOrEqualTo: startOfWeek)
          .where('firstVisitAt', isLessThanOrEqualTo: now)
          .get();
      final newCustomers = newCustomersSnapshot.docs.length;

      final avgSpending = visitorCount > 0
          ? (totalSales / visitorCount).round()
          : 0;

      return {
        'visitorCount': visitorCount,
        'newCustomers': newCustomers,
        'totalSales': totalSales,
        'avgSpending': avgSpending,
        'repeatRate': repeatRate,
      };
    }).handleError((error) {
      debugPrint('Error fetching weekly stats: $error');
      return {
        'visitorCount': 0,
        'newCustomers': 0,
        'totalSales': 0,
        'avgSpending': 0,
        'repeatRate': 0,
      };
    });
  } catch (e) {
    debugPrint('Error creating weekly stats stream: $e');
    return Stream.value({
      'visitorCount': 0,
      'newCustomers': 0,
      'totalSales': 0,
      'avgSpending': 0,
      'repeatRate': 0,
    });
  }
});

// 月間統計プロバイダー
final monthlyStatsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('store_stats')
        .doc(storeId)
        .collection('daily')
        .snapshots()
        .asyncMap((_) async {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startKey = _buildDateKey(startOfMonth);
      final endKey = _buildDateKey(now);

      final dailySnapshot = await FirebaseFirestore.instance
          .collection('store_stats')
          .doc(storeId)
          .collection('daily')
          .where('date', isGreaterThanOrEqualTo: startKey)
          .where('date', isLessThanOrEqualTo: endKey)
          .get();

      int totalSales = 0;
      int visitorCount = 0;
      int monthlyPointsIssued = 0;
      int monthlyPointsUsed = 0;
      int monthlySpecialPointsUsed = 0;
      for (final doc in dailySnapshot.docs) {
        final data = doc.data();
        totalSales += (data['totalSales'] as num?)?.toInt() ?? 0;
        visitorCount += (data['visitorCount'] as num?)?.toInt() ?? 0;
        monthlyPointsIssued += (data['pointsIssued'] as num?)?.toInt() ?? 0;
        monthlyPointsUsed += (data['pointsUsed'] as num?)?.toInt() ?? 0;
      }

      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('transactions')
          .where('type', isEqualTo: 'stamp')
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('createdAt', isLessThanOrEqualTo: now)
          .get();

      final userVisitCounts = <String, int>{};
      for (final doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        if (userId == null) continue;
        userVisitCounts[userId] = (userVisitCounts[userId] ?? 0) + 1;
      }
      final uniqueUsers = userVisitCounts.keys.toSet();
      final repeatUsers = userVisitCounts.values.where((count) => count > 1).length;
      final repeatRate = uniqueUsers.isNotEmpty
          ? (repeatUsers / uniqueUsers.length * 100).toInt()
          : 0;

      final useTransactionsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('transactions')
          .where('type', isEqualTo: 'use')
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('createdAt', isLessThanOrEqualTo: now)
          .get();
      for (final doc in useTransactionsSnapshot.docs) {
        final data = doc.data();
        monthlySpecialPointsUsed += (data['usedSpecialPoints'] as num?)?.toInt() ?? 0;
      }

      final newCustomersSnapshot = await FirebaseFirestore.instance
          .collection('store_users')
          .doc(storeId)
          .collection('users')
          .where('firstVisitAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('firstVisitAt', isLessThanOrEqualTo: now)
          .get();
      final newCustomers = newCustomersSnapshot.docs.length;

      final avgSpending = visitorCount > 0
          ? (totalSales / visitorCount).round()
          : 0;

      return {
        'visitorCount': visitorCount,
        'newCustomers': newCustomers,
        'totalSales': totalSales,
        'avgSpending': avgSpending,
        'repeatRate': repeatRate,
        'monthlyPointsIssued': monthlyPointsIssued,
        'monthlyPointsUsed': monthlyPointsUsed,
        'monthlySpecialPointsUsed': monthlySpecialPointsUsed,
      };
    }).handleError((error) {
      debugPrint('Error fetching monthly stats: $error');
      return {
        'visitorCount': 0,
        'newCustomers': 0,
        'totalSales': 0,
        'avgSpending': 0,
        'repeatRate': 0,
        'monthlyPointsIssued': 0,
        'monthlyPointsUsed': 0,
        'monthlySpecialPointsUsed': 0,
      };
    });
  } catch (e) {
    debugPrint('Error creating monthly stats stream: $e');
    return Stream.value({
      'visitorCount': 0,
      'newCustomers': 0,
      'totalSales': 0,
      'avgSpending': 0,
      'repeatRate': 0,
      'monthlyPointsIssued': 0,
      'monthlyPointsUsed': 0,
      'monthlySpecialPointsUsed': 0,
    });
  }
});

// 今日の新規顧客プロバイダー（store_users の firstVisitAt を基準に取得）
final todayNewCustomersProvider = StreamProvider.family<int, String>((ref, storeId) {
  try {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return firestore
        .collection('store_users')
        .doc(storeId)
        .collection('users')
        .where('firstVisitAt', isGreaterThanOrEqualTo: startOfDay)
        .where('firstVisitAt', isLessThan: endOfDay)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      debugPrint('Error fetching today new customers: $error');
    });
  } catch (e) {
    debugPrint('Error creating today new customers stream: $e');
    return Stream.value(0);
  }
});

// 全来店記録 円グラフ用プロバイダー
final allVisitPieChartDataProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, storeId) async {
  try {
    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .collection('transactions')
        .get();

    final genderCounts = <String, int>{
      '男性': 0,
      '女性': 0,
      'その他': 0,
      '未設定': 0,
    };

    final ageGroupCounts = <String, int>{
      '~19': 0,
      '20s': 0,
      '30s': 0,
      '40s': 0,
      '50s': 0,
      '60+': 0,
      '未設定': 0,
    };

    final userVisitCounts = <String, int>{};

    for (final doc in transactionsSnapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      if (userId == null) continue;

      // 性別集計
      final gender = data['userGender'] as String?;
      if (gender == '男性') {
        genderCounts['男性'] = genderCounts['男性']! + 1;
      } else if (gender == '女性') {
        genderCounts['女性'] = genderCounts['女性']! + 1;
      } else if (gender == 'その他' || gender == '回答しない') {
        genderCounts['その他'] = genderCounts['その他']! + 1;
      } else {
        genderCounts['未設定'] = genderCounts['未設定']! + 1;
      }

      // 年齢別集計
      final ageGroup = data['userAgeGroup'] as String?;
      if (ageGroup != null && ageGroupCounts.containsKey(ageGroup)) {
        ageGroupCounts[ageGroup] = ageGroupCounts[ageGroup]! + 1;
      } else {
        ageGroupCounts['未設定'] = ageGroupCounts['未設定']! + 1;
      }

      // ユーザーごとの来店回数集計
      userVisitCounts[userId] = (userVisitCounts[userId] ?? 0) + 1;
    }

    // 新規/リピート: ユニークユーザー単位で分類
    int newUsers = 0;
    int repeatUsers = 0;
    for (final count in userVisitCounts.values) {
      if (count == 1) {
        newUsers++;
      } else {
        repeatUsers++;
      }
    }

    return {
      'gender': genderCounts,
      'ageGroup': ageGroupCounts,
      'newRepeat': {
        '新規': newUsers,
        'リピート': repeatUsers,
      },
      'totalTransactions': transactionsSnapshot.docs.length,
    };
  } catch (e) {
    debugPrint('Error fetching pie chart data: $e');
    return {
      'gender': <String, int>{},
      'ageGroup': <String, int>{},
      'newRepeat': <String, int>{},
      'totalTransactions': 0,
    };
  }
});
