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
        .where('description', isEqualTo: 'ポイント支払い')
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

// 今日の訪問者プロバイダー（point_transactionsから取得）
final todayVisitorsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, storeId) {
  final firestore = FirebaseFirestore.instance;
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  final controller = StreamController<List<Map<String, dynamic>>>();
  final Map<String, StreamSubscription<QuerySnapshot>> userSubs = {};
  StreamSubscription<QuerySnapshot>? usersRootSub;

  void emitCombined() async {
    try {
      // Combine all current snapshots into a single sorted list
      final List<Map<String, dynamic>> all = [];
      await Future.wait(userSubs.entries.map((e) async {
        // Read latest once from each subcollection
        final snap = await firestore
            .collection('point_transactions')
            .doc(storeId)
            .collection(e.key)
            .get();
        for (final d in snap.docs) {
          final data = d.data();
          // ポイント付与のみをフィルタリング
          if (data['description'] == 'ポイント付与') {
            // 今日のデータのみをフィルタリング
            final createdAt = data['createdAt'];
            if (createdAt != null) {
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
              
              if (docDate.isAfter(startOfDay) && docDate.isBefore(endOfDay)) {
                all.add({
                  ...data,
                  'transactionId': d.id,
                  'userName': data['userName'] ?? 'ゲストユーザー',
                  'pointsEarned': data['amount'] ?? 0,
                  'timestamp': data['createdAt'],
                  'storeName': data['storeName'] ?? '店舗名不明',
                });
              }
            }
          }
        }
      }));
      
      // 作成日時で降順ソート
      all.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime is DateTime && bTime is DateTime) {
          return bTime.compareTo(aTime);
        } else if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });
      
      if (!controller.isClosed) controller.add(all);
    } catch (e) {
      debugPrint('Error in emitCombined: $e');
      if (!controller.isClosed) controller.add([]);
    }
  }

  // Watch users and attach per-user listeners
  usersRootSub = firestore.collection('users').snapshots().listen((usersSnap) {
    final incoming = usersSnap.docs.map((d) => d.id).toSet();
    final current = userSubs.keys.toSet();

    // Add new user listeners
    for (final userId in incoming.difference(current)) {
      final sub = firestore
          .collection('point_transactions')
          .doc(storeId)
          .collection(userId)
          .snapshots()
          .listen((_) {
        emitCombined();
      });
      userSubs[userId] = sub;
    }

    // Remove obsolete listeners
    for (final userId in current.difference(incoming)) {
      userSubs.remove(userId)?.cancel();
    }

    // Emit after topology change
    emitCombined();
  });

  ref.onDispose(() {
    usersRootSub?.cancel();
    for (final s in userSubs.values) {
      s.cancel();
    }
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
            .where('description', isEqualTo: 'ポイント支払い')
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
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: 7));
    
    return FirebaseFirestore.instance
        .collection('point_transactions')
        .doc(storeId)
        .snapshots()
        .asyncMap((storeDoc) async {
      // ユーザーのサブコレクションからデータを取得
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final List<Map<String, dynamic>> allTransactions = [];
      
      for (final userDoc in usersSnap.docs) {
        final transactionsSnap = await FirebaseFirestore.instance
            .collection('point_transactions')
            .doc(storeId)
            .collection(userDoc.id)
            .get();
        
        for (final transDoc in transactionsSnap.docs) {
          final data = transDoc.data();
          data['userId'] = userDoc.id;
          data['transactionId'] = transDoc.id;
          allTransactions.add(data);
        }
      }
      
      // 週間のデータのみをフィルタリング（来店=ポイント付与）
      final weeklyTransactions = allTransactions.where((data) {
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
        
        if (!(docDate.isAfter(startOfWeek) && docDate.isBefore(now))) {
          return false;
        }

        return data['description'] == 'ポイント付与';
      }).toList();
      
      // 来店者数（ポイント付与の取引数）
      final visitorCount = weeklyTransactions.length;
      
      // ユニークユーザー数
      final uniqueUsers = weeklyTransactions
          .map((t) => t['userId'] as String?)
          .where((id) => id != null)
          .toSet();
      
      // 配布ポイント総数
      final totalPointsAwarded = weeklyTransactions.fold<int>(
        0,
        (sum, t) => sum + ((t['amount'] ?? 0) as int),
      );
      
      // リピート率（複数回来店したユーザーの割合）
      final userVisitCounts = <String, int>{};
      for (final transaction in weeklyTransactions) {
        final userId = transaction['userId'] as String?;
        if (userId != null) {
          userVisitCounts[userId] = (userVisitCounts[userId] ?? 0) + 1;
        }
      }
      final repeatUsers = userVisitCounts.values.where((count) => count > 1).length;
      final repeatRate = uniqueUsers.isNotEmpty 
          ? (repeatUsers / uniqueUsers.length * 100).toInt() 
          : 0;
      
      // 平均客単価（配布ポイント ÷ 来店者数）
      final avgSpending = visitorCount > 0 
          ? (totalPointsAwarded / visitorCount).round() 
          : 0;
      
      return {
        'visitorCount': visitorCount,
        'totalSales': totalPointsAwarded,
        'avgSpending': avgSpending,
        'repeatRate': repeatRate,
      };
    }).handleError((error) {
      debugPrint('Error fetching weekly stats: $error');
      return {
        'visitorCount': 0,
        'totalSales': 0,
        'avgSpending': 0,
        'repeatRate': 0,
      };
    });
  } catch (e) {
    debugPrint('Error creating weekly stats stream: $e');
    return Stream.value({
      'visitorCount': 0,
      'totalSales': 0,
      'avgSpending': 0,
      'repeatRate': 0,
    });
  }
});

// 月間統計プロバイダー
final monthlyStatsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, storeId) {
  try {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    return FirebaseFirestore.instance
        .collection('point_transactions')
        .doc(storeId)
        .snapshots()
        .asyncMap((storeDoc) async {
      // ユーザーのサブコレクションからデータを取得
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final List<Map<String, dynamic>> allTransactions = [];
      
      for (final userDoc in usersSnap.docs) {
        final transactionsSnap = await FirebaseFirestore.instance
            .collection('point_transactions')
            .doc(storeId)
            .collection(userDoc.id)
            .get();
        
        for (final transDoc in transactionsSnap.docs) {
          final data = transDoc.data();
          data['userId'] = userDoc.id;
          data['transactionId'] = transDoc.id;
          allTransactions.add(data);
        }
      }
      
      // 月間のデータのみをフィルタリング（来店=ポイント付与）
      final monthlyTransactions = allTransactions.where((data) {
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
        
        if (!(docDate.isAfter(startOfMonth) && docDate.isBefore(now))) {
          return false;
        }

        return data['description'] == 'ポイント付与';
      }).toList();
      
      // 来店者数（ポイント付与の取引数）
      final visitorCount = monthlyTransactions.length;
      
      // ユニークユーザー数
      final uniqueUsers = monthlyTransactions
          .map((t) => t['userId'] as String?)
          .where((id) => id != null)
          .toSet();
      
      // 配布ポイント総数
      final totalPointsAwarded = monthlyTransactions.fold<int>(
        0,
        (sum, t) => sum + ((t['amount'] ?? 0) as int),
      );
      
      // 先月のデータを取得して新規顧客数を計算
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      final startOfPreviousMonth = previousMonth;
      final endOfPreviousMonth = DateTime(now.year, now.month, 1);
      
      final previousMonthTransactions = allTransactions.where((data) {
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
        
        return docDate.isAfter(startOfPreviousMonth) && docDate.isBefore(endOfPreviousMonth);
      }).toList();
      
      final previousMonthUsers = previousMonthTransactions
          .where((t) => t['description'] == 'ポイント付与')
          .map((t) => t['userId'] as String?)
          .where((id) => id != null)
          .toSet();
      
      // 新規顧客数（今月来店したが先月は来店していないユーザー）
      final newCustomers = uniqueUsers.difference(previousMonthUsers).length;
      
      return {
        'visitorCount': visitorCount,
        'totalSales': totalPointsAwarded,
        'newCustomers': newCustomers,
      };
    }).handleError((error) {
      debugPrint('Error fetching monthly stats: $error');
      return {
        'visitorCount': 0,
        'totalSales': 0,
        'newCustomers': 0,
      };
    });
  } catch (e) {
    debugPrint('Error creating monthly stats stream: $e');
    return Stream.value({
      'visitorCount': 0,
      'totalSales': 0,
      'newCustomers': 0,
    });
  }
});

// 今日の新規顧客プロバイダー（今日初めて利用したユーザー数を取得）
final todayNewCustomersProvider = StreamProvider.family<int, String>((ref, storeId) {
  final firestore = FirebaseFirestore.instance;
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  final controller = StreamController<int>();
  StreamSubscription<QuerySnapshot>? usersListener;

  void calculateNewCustomers() async {
    try {
      final usersSnapshot = await firestore.collection('users').get();
      int newCustomerCount = 0;
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // このユーザーの全取引履歴を取得
        final transactionsSnapshot = await firestore
            .collection('point_transactions')
            .doc(storeId)
            .collection(userId)
            .where('description', isEqualTo: 'ポイント付与')
            .get();
        
        if (transactionsSnapshot.docs.isEmpty) continue;
        
        // 今日の取引があるかチェック
        final todayTransactions = transactionsSnapshot.docs.where((doc) {
          final data = doc.data();
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
          
          return docDate.isAfter(startOfDay) && docDate.isBefore(endOfDay);
        }).toList();
        
        // 今日の取引がない場合はスキップ
        if (todayTransactions.isEmpty) continue;
        
        // 全取引が今日のもののみか確認（= 今日が初めての利用）
        if (transactionsSnapshot.docs.length == todayTransactions.length) {
          newCustomerCount++;
        }
      }
      
      if (!controller.isClosed) {
        controller.add(newCustomerCount);
      }
    } catch (e) {
      debugPrint('Error calculating new customers: $e');
      if (!controller.isClosed) {
        controller.add(0);
      }
    }
  }

  // ユーザーの変更を監視
  usersListener = firestore.collection('users').snapshots().listen((_) {
    calculateNewCustomers();
  });

  ref.onDispose(() {
    usersListener?.cancel();
    controller.close();
  });

  return controller.stream;
});
