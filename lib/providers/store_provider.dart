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

  Future<void> fetchTrendData(String storeId, String period) async {
    try {
      debugPrint('=== StoreUserTrendNotifier START ===');
      debugPrint('StoreId: $storeId, Period: $period');
      
      state = const AsyncValue.loading();
      
      DateTime startDate;
      DateTime endDate = DateTime.now();
      
      switch (period) {
        case 'week':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          if (endDate.month == 1) {
            startDate = DateTime(endDate.year - 1, 12, endDate.day);
          } else {
            startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          }
          break;
        case 'year':
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }
      
      debugPrint('Date Range: ${startDate.toLocal()} to ${endDate.toLocal()}');
      
      // 全ユーザーを取得
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      debugPrint('Found ${usersSnapshot.docs.length} users');
      
      final List<Map<String, dynamic>> allTransactions = [];
      
      // 各ユーザーのトランザクションを取得
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final transactionsSnapshot = await FirebaseFirestore.instance
            .collection('point_transactions')
            .doc(storeId)
            .collection(userId)
            .get();
        
        debugPrint('User $userId: ${transactionsSnapshot.docs.length} transactions');
        
        for (final transDoc in transactionsSnapshot.docs) {
          final data = transDoc.data();
          data['userId'] = userId;
          data['transactionId'] = transDoc.id;
          allTransactions.add(data);
        }
      }
      
      debugPrint('Total transactions: ${allTransactions.length}');
      
      // ポイント付与のトランザクションのみフィルタ
      final pointAwardTransactions = allTransactions.where((data) {
        return data['description'] == 'ポイント付与';
      }).toList();
      
      debugPrint('Point award transactions: ${pointAwardTransactions.length}');
      
      // 日付範囲でフィルタ
      final filteredTransactions = pointAwardTransactions.where((data) {
        final createdAt = data['createdAt'];
        if (createdAt == null) return false;
        
        DateTime docDate;
        if (createdAt is DateTime) {
          docDate = createdAt;
        } else if (createdAt is Timestamp) {
          docDate = createdAt.toDate();
        } else if (createdAt is String) {
          try {
            docDate = DateTime.parse(createdAt);
          } catch (e) {
            return false;
          }
        } else {
          return false;
        }
        
        return docDate.isAfter(startDate) && docDate.isBefore(endDate);
      }).toList();
      
      debugPrint('Filtered transactions in date range: ${filteredTransactions.length}');
      
      if (filteredTransactions.isEmpty) {
        debugPrint('No transactions found, returning empty list');
        state = const AsyncValue.data([]);
        debugPrint('=== StoreUserTrendNotifier END ===');
        return;
      }
      
      // 日付ごとにユーザーIDをグループ化
      final Map<String, Set<String>> dailyUsers = {};
      
      for (final data in filteredTransactions) {
        final createdAt = data['createdAt'];
        DateTime docDate;
        
        if (createdAt is DateTime) {
          docDate = createdAt;
        } else if (createdAt is Timestamp) {
          docDate = createdAt.toDate();
        } else if (createdAt is String) {
          try {
            docDate = DateTime.parse(createdAt);
          } catch (e) {
            continue;
          }
        } else {
          continue;
        }
        
        final userId = data['userId'] as String?;
        if (userId == null) continue;
        
        final dateKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}-${docDate.day.toString().padLeft(2, '0')}';
        dailyUsers.putIfAbsent(dateKey, () => <String>{});
        dailyUsers[dateKey]!.add(userId);
      }
      
      debugPrint('Daily users: ${dailyUsers.keys.length} days');
      
      // 期間に応じてグループ化
      final Map<String, Set<String>> groupedData = {};
      
      for (final entry in dailyUsers.entries) {
        final dateStr = entry.key;
        final users = entry.value;
        
        final dateParts = dateStr.split('-');
        if (dateParts.length != 3) continue;
        
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final docDate = DateTime(year, month, day);
        
        String groupKey;
        switch (period) {
          case 'week':
            groupKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}-${docDate.day.toString().padLeft(2, '0')}';
            break;
          case 'month':
            groupKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}';
            break;
          case 'year':
            groupKey = '${docDate.year}';
            break;
          default:
            groupKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}-${docDate.day.toString().padLeft(2, '0')}';
        }
        
        groupedData.putIfAbsent(groupKey, () => <String>{});
        groupedData[groupKey]!.addAll(users);
      }
      
      // 結果をリストに変換してソート
      final result = groupedData.entries.map((entry) {
        return {
          'date': entry.key,
          'userCount': entry.value.length,
        };
      }).toList();
      
      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      
      debugPrint('Result: ${result.length} data points');
      if (result.isNotEmpty) {
        debugPrint('Sample data: ${result.take(3)}');
      }
      debugPrint('=== StoreUserTrendNotifier END ===');
      
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      debugPrint('Error fetching user trend data: $e');
      debugPrint('StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
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

  Future<void> fetchTrendData(String storeId, String period) async {
    try {
      debugPrint('=== NewCustomerTrendNotifier START ===');
      debugPrint('StoreId: $storeId, Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      final endDate = DateTime.now();

      switch (period) {
        case 'week':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          if (endDate.month == 1) {
            startDate = DateTime(endDate.year - 1, 12, endDate.day);
          } else {
            startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          }
          break;
        case 'year':
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      debugPrint('Date Range: ${startDate.toLocal()} to ${endDate.toLocal()}');

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      debugPrint('Found ${usersSnapshot.docs.length} users');

      final Map<String, DateTime> firstVisitByUser = {};

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
        }
      }

      debugPrint('First visits: ${firstVisitByUser.length}');

      final Map<String, int> groupedData = {};
      for (final entry in firstVisitByUser.entries) {
        final visitDate = entry.value;
        if (!(visitDate.isAfter(startDate) && visitDate.isBefore(endDate))) {
          continue;
        }

        String groupKey;
        switch (period) {
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

      final result = groupedData.entries.map((entry) {
        return {
          'date': entry.key,
          'newCustomerCount': entry.value,
        };
      }).toList();

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      if (result.isNotEmpty) {
        debugPrint('Sample data: ${result.take(3)}');
      }
      debugPrint('=== NewCustomerTrendNotifier END ===');

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

  Future<void> fetchTrendData(String storeId, String period) async {
    try {
      debugPrint('=== PointIssueTrendNotifier START ===');
      debugPrint('StoreId: $storeId, Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      final endDate = DateTime.now();

      switch (period) {
        case 'week':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          if (endDate.month == 1) {
            startDate = DateTime(endDate.year - 1, 12, endDate.day);
          } else {
            startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          }
          break;
        case 'year':
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, int> groupedData = {};

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
          if (!_isWithinRange(createdAt, startDate, endDate)) continue;

          final groupKey = _buildGroupKey(createdAt, period);
          final amount = (data['amount'] as num?)?.toInt() ?? 0;
          groupedData[groupKey] = (groupedData[groupKey] ?? 0) + amount;
        }
      }

      final result = groupedData.entries.map((entry) {
        return {
          'date': entry.key,
          'pointsIssued': entry.value,
        };
      }).toList();

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      debugPrint('=== PointIssueTrendNotifier END ===');

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

  Future<void> fetchTrendData(String storeId, String period) async {
    try {
      debugPrint('=== PointUsageUserTrendNotifier START ===');
      debugPrint('StoreId: $storeId, Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      final endDate = DateTime.now();

      switch (period) {
        case 'week':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          if (endDate.month == 1) {
            startDate = DateTime(endDate.year - 1, 12, endDate.day);
          } else {
            startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          }
          break;
        case 'year':
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, Set<String>> groupedUsers = {};

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
          if (!_isWithinRange(createdAt, startDate, endDate)) continue;

          final groupKey = _buildGroupKey(createdAt, period);
          groupedUsers.putIfAbsent(groupKey, () => <String>{});
          groupedUsers[groupKey]!.add(userId);
        }
      }

      final result = groupedUsers.entries.map((entry) {
        return {
          'date': entry.key,
          'pointUsageUsers': entry.value.length,
        };
      }).toList();

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      debugPrint('=== PointUsageUserTrendNotifier END ===');

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

  Future<void> fetchTrendData(String storeId, String period) async {
    try {
      debugPrint('=== AllUserTrendNotifier START ===');
      debugPrint('Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      final endDate = DateTime.now();

      switch (period) {
        case 'week':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          if (endDate.month == 1) {
            startDate = DateTime(endDate.year - 1, 12, endDate.day);
          } else {
            startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          }
          break;
        case 'year':
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, int> groupedUsers = {};

      for (final userDoc in usersSnapshot.docs) {
        final data = userDoc.data();
        final createdAt = _parseCreatedAt(data['createdAt']);
        if (createdAt == null) continue;
        if (!_isWithinRange(createdAt, startDate, endDate)) continue;

        final groupKey = _buildGroupKey(createdAt, period);
        groupedUsers[groupKey] = (groupedUsers[groupKey] ?? 0) + 1;
      }

      final result = groupedUsers.entries.map((entry) {
        return {
          'date': entry.key,
          'totalUsers': entry.value,
        };
      }).toList();

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      debugPrint('=== AllUserTrendNotifier END ===');

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

// 全ポイント発行数推移の状態管理
class TotalPointIssueTrendNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  TotalPointIssueTrendNotifier() : super(const AsyncValue.loading());

  Future<void> fetchTrendData(String storeId, String period) async {
    try {
      debugPrint('=== TotalPointIssueTrendNotifier START ===');
      debugPrint('Period: $period');

      state = const AsyncValue.loading();

      DateTime startDate;
      final endDate = DateTime.now();

      switch (period) {
        case 'week':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          if (endDate.month == 1) {
            startDate = DateTime(endDate.year - 1, 12, endDate.day);
          } else {
            startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          }
          break;
        case 'year':
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      final storesSnapshot = await FirebaseFirestore.instance.collection('stores').get();
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, int> groupedData = {};

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
            if (!_isWithinRange(createdAt, startDate, endDate)) continue;

            final groupKey = _buildGroupKey(createdAt, period);
            final amount = (data['amount'] as num?)?.toInt() ?? 0;
            groupedData[groupKey] = (groupedData[groupKey] ?? 0) + amount;
          }
        }
      }

      final result = groupedData.entries.map((entry) {
        return {
          'date': entry.key,
          'totalPointsIssued': entry.value,
        };
      }).toList();

      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      debugPrint('Result: ${result.length} data points');
      debugPrint('=== TotalPointIssueTrendNotifier END ===');

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
          .where('type', isEqualTo: 'award')
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
          .where('type', isEqualTo: 'award')
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
