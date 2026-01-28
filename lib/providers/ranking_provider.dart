import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/ranking_model.dart';

// ランキングサービスプロバイダー
final rankingProvider = Provider<RankingService>((ref) {
  return RankingService();
});

// ランキング状態管理（クエリ別に状態を管理）
class RankingNotifier extends StateNotifier<Map<String, AsyncValue<List<RankingModel>>>> {
  final RankingService _rankingService;
  
  RankingNotifier(this._rankingService) : super({});
  
  Future<void> loadRanking(RankingQuery query) async {
    final queryKey = _getQueryKey(query);
    
    debugPrint('RankingNotifier: Loading ranking for ${query.type}, ${query.period}');
    
    // このクエリの状態をローディングに設定
    state = {
      ...state,
      queryKey: const AsyncValue.loading(),
    };
    
    try {
      final data = await _rankingService.getRankingDataOnce(query);
      debugPrint('RankingNotifier: Loaded ${data.length} ranking items');
      
      // データを更新
      state = {
        ...state,
        queryKey: AsyncValue.data(data),
      };
    } catch (error, stackTrace) {
      debugPrint('RankingNotifier: Error loading ranking: $error');
      
      // エラーを設定
      state = {
        ...state,
        queryKey: AsyncValue.error(error, stackTrace),
      };
    }
  }
  
  AsyncValue<List<RankingModel>> getRankingForQuery(RankingQuery query) {
    final queryKey = _getQueryKey(query);
    return state[queryKey] ?? const AsyncValue.loading();
  }
  
  // 強制的に再読み込み
  Future<void> refresh(RankingQuery query) async {
    debugPrint('RankingNotifier: Refreshing ranking for ${query.type}, ${query.period}');
    await loadRanking(query);
  }
  
  String _getQueryKey(RankingQuery query) {
    return '${query.type}_${query.period}_${query.limit}';
  }
}

// ランキングプロバイダー
final rankingNotifierProvider = StateNotifierProvider<RankingNotifier, Map<String, AsyncValue<List<RankingModel>>>>((ref) {
  final rankingService = ref.watch(rankingProvider);
  return RankingNotifier(rankingService);
});

// ランキングデータプロバイダー（クエリごとにデータを取得）
final rankingDataProvider = Provider.family<AsyncValue<List<RankingModel>>, RankingQuery>((ref, query) {
  final notifier = ref.watch(rankingNotifierProvider.notifier);
  final state = ref.watch(rankingNotifierProvider);
  
  // クエリに対応する状態を取得
  final queryKey = '${query.type}_${query.period}_${query.limit}';
  final currentState = state[queryKey];
  
  // データが存在しない場合、または強制的に再読み込みする場合
  if (currentState == null) {
    // 非同期でデータを読み込む
    Future.microtask(() => notifier.loadRanking(query));
    return const AsyncValue.loading();
  }
  
  return currentState;
});

// ユーザーのランキング位置プロバイダー
final userRankingProvider = StreamProvider.family<RankingModel?, String>((ref, userId) {
  final rankingService = ref.watch(rankingProvider);
  return rankingService.getUserRanking(userId);
});

// ランキング期間プロバイダー
final rankingPeriodsProvider = StreamProvider<List<RankingPeriod>>((ref) {
  final rankingService = ref.watch(rankingProvider);
  return rankingService.getRankingPeriods();
});

// ユーザーのランキング履歴プロバイダー
final userRankingHistoryProvider = StreamProvider.family<List<UserRankingHistory>, String>((ref, userId) {
  final rankingService = ref.watch(rankingProvider);
  return rankingService.getUserRankingHistory(userId);
});

class RankingQuery {
  final RankingType type;
  final RankingPeriodType period;
  final int limit;
  final String? periodId;

  const RankingQuery({
    required this.type,
    required this.period,
    this.limit = 100,
    this.periodId,
  });
}

class RankingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ランキングデータを一度だけ取得（FutureProvider用）
  Future<List<RankingModel>> getRankingDataOnce(RankingQuery query) async {
    try {
      debugPrint('RankingService: Getting ranking data once for type: ${query.type}, period: ${query.period}');
      
      final snapshot = await _firestore
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 10));
      
      debugPrint('RankingService: Retrieved ${snapshot.docs.length} users from database');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('RankingService: No users found in database');
        return <RankingModel>[];
      }
      
      // ユーザーデータをRankingModelに変換（非同期処理が必要）
      final rankings = <RankingModel>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (_shouldExcludeUser(data)) {
            continue;
          }
          final userId = doc.id;
          final profileImageUrl = data['profileImageUrl'];
          
          debugPrint('RankingService: User $userId - profileImageUrl: $profileImageUrl');
          
          // スタンプ数を計算（users/{userId}/storesの全ドキュメントのstampsを合計）
          int totalStamps = 0;
          try {
            final storesSnapshot = await _firestore
                .collection('users')
                .doc(userId)
                .collection('stores')
                .get();
            
            for (final storeDoc in storesSnapshot.docs) {
              final storeData = storeDoc.data();
              final stamps = storeData['stamps'] ?? 0;
              totalStamps += stamps as int;
            }
            
            debugPrint('RankingService: User $userId - Total stamps: $totalStamps');
          } catch (e) {
            debugPrint('RankingService: Error calculating stamps for $userId: $e');
          }
          
          // バッジ数を計算（user_badges/{userId}/badgesのドキュメント数）
          int badgeCount = 0;
          try {
            final badgesSnapshot = await _firestore
                .collection('user_badges')
                .doc(userId)
                .collection('badges')
                .get();
            
            badgeCount = badgesSnapshot.docs.length;
            
            debugPrint('RankingService: User $userId - Total badges: $badgeCount');
          } catch (e) {
            debugPrint('RankingService: Error calculating badges for $userId: $e');
          }
          
          rankings.add(RankingModel(
            userId: userId,
            displayName: data['displayName'] ?? 'Unknown User',
            photoURL: data['profileImageUrl'], // profileImageUrlから取得
            totalPoints: data['points'] ?? 0, // pointsフィールドから取得
            currentLevel: data['level'] ?? 1, // levelフィールドから取得
            badgeCount: badgeCount, // 計算したバッジ数
            stampCount: totalStamps, // 計算した合計値
            totalPayment: (data['paid'] ?? 0).toDouble(), // paidフィールドから取得
            rank: 0, // 後で設定
            lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        } catch (e) {
          debugPrint('RankingService: Error parsing user data for ${doc.id}: $e');
        }
      }
      
      debugPrint('RankingService: Successfully parsed ${rankings.length} user rankings');
      
      // ランキングタイプに応じてソート
      rankings.sort((a, b) {
        switch (query.type) {
          case RankingType.totalPoints:
            return b.totalPoints.compareTo(a.totalPoints);
          case RankingType.badgeCount:
            return b.badgeCount.compareTo(a.badgeCount);
          case RankingType.level:
            return b.currentLevel.compareTo(a.currentLevel);
          case RankingType.stampCount:
            return b.stampCount.compareTo(a.stampCount);
          case RankingType.totalPayment:
            return b.totalPayment.compareTo(a.totalPayment);
        }
      });
      
      // 期間フィルターを適用
      final filteredRankings = _applyPeriodFilterToList(rankings, query.period);
      debugPrint('RankingService: After period filter: ${filteredRankings.length} users');
      
      // ランクを設定
      final rankedList = filteredRankings.asMap().entries.map((entry) {
        final index = entry.key;
        final ranking = entry.value;
        return ranking.copyWith(rank: index + 1);
      }).toList();
      
      // 制限を適用
      final limitedList = rankedList.take(query.limit).toList();
      
      debugPrint('RankingService: Generated final ranking with ${limitedList.length} users');
      return limitedList;
    } catch (e) {
      debugPrint('RankingService: Error getting ranking data: $e');
      return <RankingModel>[];
    }
  }

  // ランキングデータを取得（実際のユーザーデータから）
  Stream<List<RankingModel>> getRankingData(RankingQuery query) {
    try {
      debugPrint('Getting ranking data for type: ${query.type}, period: ${query.period}');
      
      return _firestore
          .collection('users')
          .snapshots()
          .timeout(const Duration(seconds: 15))
          .map((snapshot) {
        debugPrint('Retrieved ${snapshot.docs.length} users from database');
        
        if (snapshot.docs.isEmpty) {
          debugPrint('No users found in database');
          return <RankingModel>[];
        }
        
        // ユーザーデータをRankingModelに変換（同期的に処理）
        final rankings = <RankingModel>[];
        
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            if (_shouldExcludeUser(data)) {
              continue;
            }
            final userId = doc.id;
            final profileImageUrl = data['profileImageUrl'];
            
            debugPrint('RankingService: User $userId - profileImageUrl: $profileImageUrl');
            
            // スタンプ数とバッジ数は後で非同期で取得する必要があるため、ここでは0としておく
            // Streamでは非同期処理が難しいため、基本的にはgetRankingDataOnceを使用することを推奨
            rankings.add(RankingModel(
              userId: userId,
              displayName: data['displayName'] ?? 'Unknown User',
              photoURL: profileImageUrl, // profileImageUrlから取得
              totalPoints: data['points'] ?? 0, // pointsフィールドから取得
              currentLevel: data['level'] ?? 1, // levelフィールドから取得
              badgeCount: 0, // Streamでは簡易的に0を設定（サブコレクションから計算が必要）
              stampCount: 0, // Streamでは簡易的に0を設定（サブコレクションから計算が必要）
              totalPayment: (data['paid'] ?? 0).toDouble(), // paidフィールドから取得
              rank: 0, // 後で設定
              lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
            ));
          } catch (e) {
            debugPrint('Error parsing user data for ${doc.id}: $e');
          }
        }
        
        debugPrint('Successfully parsed ${rankings.length} user rankings');
        
        // ランキングタイプに応じてソート
        rankings.sort((a, b) {
          switch (query.type) {
            case RankingType.totalPoints:
              return b.totalPoints.compareTo(a.totalPoints);
            case RankingType.badgeCount:
              return b.badgeCount.compareTo(a.badgeCount);
            case RankingType.level:
              return b.currentLevel.compareTo(a.currentLevel);
            case RankingType.stampCount:
              return b.stampCount.compareTo(a.stampCount);
            case RankingType.totalPayment:
              return b.totalPayment.compareTo(a.totalPayment);
          }
        });
        
        // 期間フィルターを適用
        final filteredRankings = _applyPeriodFilterToList(rankings, query.period);
        debugPrint('After period filter: ${filteredRankings.length} users');
        
        // ランクを設定
        final rankedList = filteredRankings.asMap().entries.map((entry) {
          final index = entry.key;
          final ranking = entry.value;
          return ranking.copyWith(rank: index + 1);
        }).toList();
        
        // 制限を適用
        final limitedList = rankedList.take(query.limit).toList();
        
        debugPrint('Generated final ranking with ${limitedList.length} users');
        return limitedList;
      }).handleError((error) {
        debugPrint('Error in ranking data stream: $error');
        // 権限エラーの場合は空のリストを返す
        if (error.toString().contains('permission-denied')) {
          return <RankingModel>[];
        }
        // その他のエラーも空のリストを返す
        return <RankingModel>[];
      });
    } catch (e) {
      debugPrint('Error getting ranking data: $e');
      return Stream.value([]);
    }
  }

  bool _shouldExcludeUser(Map<String, dynamic> data) {
    final isStoreOwner = data['isStoreOwner'] == true;
    final isOwner = data['isOwner'] == true;
    final displayName = data['displayName'];
    final hasValidName = displayName is String && displayName.trim().isNotEmpty;
    return isStoreOwner || isOwner || !hasValidName;
  }

  // ユーザーのランキング位置を取得
  Stream<RankingModel?> getUserRanking(String userId) {
    try {
      return _firestore
          .collection('rankings')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        
        final data = snapshot.docs.first.data();
        return RankingModel.fromJson(data);
      });
    } catch (e) {
      debugPrint('Error getting user ranking: $e');
      return Stream.value(null);
    }
  }

  // ランキング期間を取得
  Stream<List<RankingPeriod>> getRankingPeriods() {
    try {
      return _firestore
          .collection('ranking_periods')
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return RankingPeriod.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting ranking periods: $e');
      return Stream.value([]);
    }
  }

  // ユーザーのランキング履歴を取得
  Stream<List<UserRankingHistory>> getUserRankingHistory(String userId) {
    try {
      return _firestore
          .collection('user_ranking_history')
          .where('userId', isEqualTo: userId)
          .orderBy('achievedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserRankingHistory.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting user ranking history: $e');
      return Stream.value([]);
    }
  }

  // ランキングを更新（実際にはusersコレクションを更新）
  // 注: badgeCountとstampCountはサブコレクションから計算されるため、ここでは更新しない
  Future<void> updateUserRanking({
    required String userId,
    required String displayName,
    required String? photoURL,
    required int totalPoints,
    required int currentLevel,
    required int badgeCount, // 互換性のために残すが使用しない
    String? periodId,
  }) async {
    try {
      final rankingData = {
        'displayName': displayName,
        'profileImageUrl': photoURL,
        'points': totalPoints,
        'level': currentLevel,
        // badgeCountは含めない（サブコレクションから計算）
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .set(rankingData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user ranking: $e');
      throw Exception('ランキングの更新に失敗しました: $e');
    }
  }

  // ランキング期間を作成
  Future<void> createRankingPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    List<String> rewards = const [],
  }) async {
    try {
      final periodData = {
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
        'isActive': true,
        'rewards': rewards,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('ranking_periods').add(periodData);
    } catch (e) {
      debugPrint('Error creating ranking period: $e');
      throw Exception('ランキング期間の作成に失敗しました: $e');
    }
  }

  // ランキング期間を終了
  Future<void> endRankingPeriod(String periodId) async {
    try {
      await _firestore
          .collection('ranking_periods')
          .doc(periodId)
          .update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error ending ranking period: $e');
      throw Exception('ランキング期間の終了に失敗しました: $e');
    }
  }

  // 期間フィルターをリストに適用
  List<RankingModel> _applyPeriodFilterToList(List<RankingModel> rankings, RankingPeriodType period) {
    final now = DateTime.now();
    
    switch (period) {
      case RankingPeriodType.daily:
        final startOfDay = DateTime(now.year, now.month, now.day);
        return rankings.where((ranking) => 
          ranking.lastUpdated.isAfter(startOfDay)).toList();
      
      case RankingPeriodType.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return rankings.where((ranking) => 
          ranking.lastUpdated.isAfter(startOfWeekDay)).toList();
      
      case RankingPeriodType.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return rankings.where((ranking) => 
          ranking.lastUpdated.isAfter(startOfMonth)).toList();
      
      case RankingPeriodType.allTime:
        return rankings;
    }
  }

  // 期間フィルターを適用（クエリ用 - 将来の拡張用）
  Query _applyPeriodFilter(Query collection, RankingPeriodType period) {
    final now = DateTime.now();
    
    switch (period) {
      case RankingPeriodType.daily:
        final startOfDay = DateTime(now.year, now.month, now.day);
        return collection.where('lastUpdated', isGreaterThanOrEqualTo: startOfDay);
      
      case RankingPeriodType.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return collection.where('lastUpdated', isGreaterThanOrEqualTo: startOfWeekDay);
      
      case RankingPeriodType.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return collection.where('lastUpdated', isGreaterThanOrEqualTo: startOfMonth);
      
      case RankingPeriodType.allTime:
        return collection;
    }
  }

  // ソートフィールドを取得
  String _getOrderByField(RankingType type) {
    switch (type) {
      case RankingType.totalPoints:
        return 'points';
      case RankingType.badgeCount:
        return 'badgeCount';
      case RankingType.level:
        return 'level';
      case RankingType.stampCount:
        return 'stamps'; // 実際にはサブコレクションから計算
      case RankingType.totalPayment:
        return 'paid';
    }
  }
}
