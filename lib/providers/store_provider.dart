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
      
      // 週間のデータのみをフィルタリング
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
        
        return docDate.isAfter(startOfWeek) && docDate.isBefore(now);
      }).toList();
      
      // ポイント付与の取引のみ
      final pointAwardTransactions = weeklyTransactions
          .where((t) => t['description'] == 'ポイント付与')
          .toList();
      
      // ポイント支払いの取引のみ
      final pointPaymentTransactions = weeklyTransactions
          .where((t) => t['description'] == 'ポイント支払い')
          .toList();
      
      // 来店者数（ポイント付与の取引数）
      final visitorCount = pointAwardTransactions.length;
      
      // ユニークユーザー数
      final uniqueUsers = pointAwardTransactions
          .map((t) => t['userId'] as String?)
          .where((id) => id != null)
          .toSet();
      
      // 使用ポイント総数
      final totalPointsUsed = pointPaymentTransactions.fold<int>(
        0,
        (sum, t) => sum + ((t['amount'] ?? 0) as int).abs(),
      );
      
      // リピート率（複数回来店したユーザーの割合）
      final userVisitCounts = <String, int>{};
      for (final transaction in pointAwardTransactions) {
        final userId = transaction['userId'] as String?;
        if (userId != null) {
          userVisitCounts[userId] = (userVisitCounts[userId] ?? 0) + 1;
        }
      }
      final repeatUsers = userVisitCounts.values.where((count) => count > 1).length;
      final repeatRate = uniqueUsers.isNotEmpty 
          ? (repeatUsers / uniqueUsers.length * 100).toInt() 
          : 0;
      
      // 平均客単価（使用ポイント ÷ 来店者数）
      final avgSpending = visitorCount > 0 
          ? (totalPointsUsed / visitorCount).round() 
          : 0;
      
      return {
        'visitorCount': visitorCount,
        'totalSales': totalPointsUsed,
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
      
      // 月間のデータのみをフィルタリング
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
        
        return docDate.isAfter(startOfMonth) && docDate.isBefore(now);
      }).toList();
      
      // ポイント付与の取引のみ
      final pointAwardTransactions = monthlyTransactions
          .where((t) => t['description'] == 'ポイント付与')
          .toList();
      
      // ポイント支払いの取引のみ
      final pointPaymentTransactions = monthlyTransactions
          .where((t) => t['description'] == 'ポイント支払い')
          .toList();
      
      // 来店者数（ポイント付与の取引数）
      final visitorCount = pointAwardTransactions.length;
      
      // ユニークユーザー数
      final uniqueUsers = pointAwardTransactions
          .map((t) => t['userId'] as String?)
          .where((id) => id != null)
          .toSet();
      
      // 使用ポイント総数
      final totalPointsUsed = pointPaymentTransactions.fold<int>(
        0,
        (sum, t) => sum + ((t['amount'] ?? 0) as int).abs(),
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
        'totalSales': totalPointsUsed,
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
