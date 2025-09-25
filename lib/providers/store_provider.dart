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

// 今日の訪問者プロバイダー
final todayVisitorsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, storeId) {
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
      // 今日のデータのみをフィルタリングしてソート
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
      
      // 作成日時で降順ソート
      todayDocs.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        final aTime = aData['createdAt'];
        final bTime = bData['createdAt'];
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        DateTime aDate, bDate;
        if (aTime is DateTime) {
          aDate = aTime;
        } else if (aTime is Timestamp) {
          aDate = aTime.toDate();
        } else {
          return 0;
        }
        
        if (bTime is DateTime) {
          bDate = bTime;
        } else if (bTime is Timestamp) {
          bDate = bTime.toDate();
        } else {
          return 0;
        }
        
        return bDate.compareTo(aDate);
      });
      
      return todayDocs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // 訪問者カード用のデータ形式に変換
        return {
          'id': doc.id,
          'userName': data['userName'] ?? 'ゲストユーザー',
          'pointsEarned': data['amount'] ?? 0,
          'timestamp': data['createdAt'],
          'storeName': data['storeName'] ?? '店舗名不明',
        };
      }).toList();
    }).handleError((error) {
      debugPrint('Error fetching today visitors: $error');
      return [];
    });
  } catch (e) {
    debugPrint('Error creating today visitors stream: $e');
    return Stream.value([]);
  }
});

// 店舗利用者推移プロバイダー
final storeUserTrendProvider = StreamProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) {
  try {
    final storeId = params['storeId'] as String;
    final period = params['period'] as String; // 'week', 'month', 'year'
    
        DateTime startDate;
        // 画像内のデータが未来の日付（2025-09-24）のため、一時的に未来の日付に設定
        DateTime endDate = DateTime(2026, 1, 1);
    
    switch (period) {
      case 'week':
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
        break;
      case 'year':
        startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
        break;
      default:
        startDate = endDate.subtract(const Duration(days: 7));
    }
    
    // point_transactions/{storeId}/{userId}/{transactionId} の構造に対応
    // 直接point_transactionsコレクションにアクセスしてデータを取得
    debugPrint('StoreUserTrendProvider: Starting stream for storeId: $storeId, period: $period');
    
    final controller = StreamController<List<Map<String, dynamic>>>();
    final Map<String, StreamSubscription<QuerySnapshot>> userSubs = {};
    StreamSubscription<QuerySnapshot>? usersRootSub;

    void emitCombined() async {
      // Combine all current snapshots into a single sorted list
      final List<Map<String, dynamic>> all = [];
      await Future.wait(userSubs.entries.map((e) async {
        // Read latest once from each subcollection (cache or server)
        final snap = await FirebaseFirestore.instance
            .collection('point_transactions')
            .doc(storeId)
            .collection(e.key)
            .get();
        for (final d in snap.docs) {
          final data = d.data() as Map<String, dynamic>;
          all.add({
            ...data,
            'transactionId': d.id,
            'userId': e.key,
          });
        }
      }));
      
      // 期間とdescriptionでフィルタリング
      final filteredData = all.where((transaction) {
        // descriptionが「ポイント付与」のもののみ
        if (transaction['description'] != 'ポイント付与') return false;
        
        final createdAt = transaction['createdAt'];
        if (createdAt == null) return false;
        
        DateTime docDate;
        if (createdAt is DateTime) {
          docDate = createdAt;
        } else if (createdAt is Timestamp) {
          docDate = createdAt.toDate();
        } else {
          return false;
        }
        
        return docDate.isAfter(startDate) && docDate.isBefore(endDate);
      }).toList();
      
      // 日付でグループ化してユーザー数をカウント
      final Map<String, Set<String>> dailyUsers = {};
      
      for (final transaction in filteredData) {
        final createdAt = transaction['createdAt'];
        if (createdAt == null) continue;
        
        DateTime docDate;
        if (createdAt is DateTime) {
          docDate = createdAt;
        } else if (createdAt is Timestamp) {
          docDate = createdAt.toDate();
        } else {
          continue;
        }
        
        final dateKey = '${docDate.year}-${docDate.month.toString().padLeft(2, '0')}-${docDate.day.toString().padLeft(2, '0')}';
        dailyUsers.putIfAbsent(dateKey, () => <String>{});
        dailyUsers[dateKey]!.add(transaction['userId'] as String);
      }
      
      // 期間に応じてデータをグループ化
      Map<String, Set<String>> groupedData = {};

      for (final entry in dailyUsers.entries) {
        final dateStr = entry.key;
        final users = entry.value;

        // 日付文字列を解析
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

      debugPrint('StoreUserTrendProvider: Returning ${result.length} data points');
      if (!controller.isClosed) controller.add(result);
    }

    // Watch users under point_transactions/{storeId} and attach per-user listeners
    // まず users コレクションから userId を取得
    usersRootSub = FirebaseFirestore.instance.collection('users').snapshots().listen((usersSnap) {
      final incoming = usersSnap.docs.map((d) => d.id).toSet();
      final current = userSubs.keys.toSet();

      // Add new user listeners
      for (final userId in incoming.difference(current)) {
        final sub = FirebaseFirestore.instance
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
  } catch (e) {
    debugPrint('Error creating store user trend stream: $e');
    return Stream.value([]);
  }
});
