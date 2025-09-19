import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';

class PointsHistoryView extends ConsumerStatefulWidget {
  const PointsHistoryView({Key? key}) : super(key: key);

  @override
  ConsumerState<PointsHistoryView> createState() => _PointsHistoryViewState();
}

class _PointsHistoryViewState extends ConsumerState<PointsHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStoreId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStoreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 店舗IDを取得
      final userStoreIdAsync = ref.read(userStoreIdProvider);
      final storeId = userStoreIdAsync.when(
        data: (data) => data,
        loading: () => null,
        error: (error, stackTrace) => null,
      );

      if (storeId != null) {
        _selectedStoreId = storeId;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗データの読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ポイント履歴'),
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント履歴'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'ポイント発行履歴'),
            Tab(text: 'ポイント利用履歴'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPointsIssuedHistory(),
          _buildPointsUsedHistory(),
        ],
      ),
    );
  }

  Widget _buildPointsIssuedHistory() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.point_of_sale,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'ポイント発行履歴は現在利用できません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsUsedHistory() {
    if (_selectedStoreId == null) {
      return const Center(
        child: Text('店舗情報が見つかりません'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('point_transactions')
          .where('storeId', isEqualTo: _selectedStoreId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('エラーが発生しました: ${snapshot.error}'),
          );
        }

        final allPoints = snapshot.data?.docs ?? [];
        
        // ポイント利用履歴をフィルタリング（descriptionが「ポイント支払い」のデータ）
        final points = allPoints.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final storeId = data['storeId'] ?? '';
          final description = data['description'] ?? '';
          return storeId == _selectedStoreId && description == 'ポイント支払い';
        }).toList();
        
        // 作成日時でソート（降順）
        points.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimeStr = aData['createdAt']?.toString() ?? '';
          final bTimeStr = bData['createdAt']?.toString() ?? '';
          
          if (aTimeStr.isEmpty && bTimeStr.isEmpty) return 0;
          if (aTimeStr.isEmpty) return 1;
          if (bTimeStr.isEmpty) return -1;
          
          // 文字列として比較（ISO 8601形式なので文字列比較で正しくソートされる）
          return bTimeStr.compareTo(aTimeStr);
        });

        if (points.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'ポイント利用履歴がありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: points.length,
          itemBuilder: (context, index) {
            final point = points[index].data() as Map<String, dynamic>;
            return _buildPointUsedCard(point);
          },
        );
      },
    );
  }

  Widget _buildPointIssuedCard(Map<String, dynamic> point) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // アイコン
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.add_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // ポイント情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point['storeName'] ?? '店舗名不明',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${point['amount'] ?? 0}ポイント発行',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point['description'] ?? 'ポイント発行',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(point['createdAt']),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // ポイント数
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${point['amount'] ?? 0}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointUsedCard(Map<String, dynamic> point) {
    final amount = point['amount'] ?? 0;
    final usedAmount = amount; // 正の値のまま使用
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // アイコン
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.remove_circle,
                color: Colors.red,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // ポイント情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point['storeName'] ?? '店舗名不明',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${usedAmount}ポイント利用',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point['description'] ?? 'ポイント利用',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(point['createdAt']),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // ポイント数
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '-$usedAmount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return '日時不明';
    
    try {
      DateTime date;
      
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        // ISO 8601形式の文字列をパース
        date = DateTime.parse(timestamp);
      } else {
        return '日時不明';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}時間前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分前';
      } else {
        return 'たった今';
      }
    } catch (e) {
      print('日時フォーマットエラー: $e, timestamp: $timestamp');
      return '日時不明';
    }
  }
}
