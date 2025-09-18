import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import 'store_detail_view.dart';

class PendingStoresView extends ConsumerStatefulWidget {
  const PendingStoresView({Key? key}) : super(key: key);

  @override
  ConsumerState<PendingStoresView> createState() => _PendingStoresViewState();
}

class _PendingStoresViewState extends ConsumerState<PendingStoresView> {
  String _selectedFilter = 'all';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).when(
      data: (user) => user,
      loading: () => null,
      error: (_, __) => null,
    );

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('未承認店舗一覧'),
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('ログインが必要です'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '店舗管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'all',
                child: Text('すべて'),
              ),
              const PopupMenuItem<String>(
                value: 'pending',
                child: Text('承認待ち'),
              ),
              const PopupMenuItem<String>(
                value: 'approved',
                child: Text('承認済み'),
              ),
              const PopupMenuItem<String>(
                value: 'rejected',
                child: Text('拒否済み'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 統計情報
          _buildStatsSection(),
          
          // 店舗リスト
          Expanded(
            child: _buildStoresList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stores')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Text('統計情報の取得に失敗しました');
          }

          final stores = snapshot.data?.docs ?? [];
          int pendingCount = 0;
          int approvedCount = 0;
          int rejectedCount = 0;

          for (var doc in stores) {
            final data = doc.data() as Map<String, dynamic>;
            final isApproved = data['isApproved'] ?? false;
            final status = data['approvalStatus'] ?? 'pending';
            
            if (isApproved || status == 'approved') {
              approvedCount++;
            } else if (status == 'pending') {
              pendingCount++;
            } else if (status == 'rejected') {
              rejectedCount++;
            }
          }

          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '承認待ち',
                  pendingCount.toString(),
                  Colors.orange,
                  Icons.pending_actions,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  '承認済み',
                  approvedCount.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  '拒否済み',
                  rejectedCount.toString(),
                  Colors.red,
                  Icons.cancel_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  '合計',
                  stores.length.toString(),
                  Colors.blue,
                  Icons.store,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoresList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stores')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('データの取得に失敗しました'),
                const SizedBox(height: 8),
                Text('${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('再試行'),
                ),
              ],
            ),
          );
        }

        final stores = snapshot.data?.docs ?? [];
        
        // フィルター適用
        List<QueryDocumentSnapshot> filteredStores = stores.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isApproved = data['isApproved'] ?? false;
          final status = data['approvalStatus'] ?? 'pending';
          
          if (_selectedFilter == 'all') return true;
          if (_selectedFilter == 'pending') return status == 'pending' && !isApproved;
          if (_selectedFilter == 'approved') return isApproved || status == 'approved';
          if (_selectedFilter == 'rejected') return status == 'rejected' && !isApproved;
          return false;
        }).toList();
        
        // 作成日時で降順ソート
        filteredStores.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt']?.toDate() ?? DateTime(1970);
          final bTime = (b.data() as Map<String, dynamic>)['createdAt']?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });

        if (filteredStores.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.store, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(_getEmptyMessage()),
                const SizedBox(height: 8),
                const Text('新しい申請が来たらここに表示されます'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredStores.length,
          itemBuilder: (context, index) {
            final store = filteredStores[index];
            final data = store.data() as Map<String, dynamic>;
            return _buildStoreCard(data);
          },
        );
      },
    );
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'pending':
        return '承認待ちの店舗はありません';
      case 'approved':
        return '承認済みの店舗はありません';
      case 'rejected':
        return '拒否済みの店舗はありません';
      default:
        return '店舗はありません';
    }
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final isApproved = store['isApproved'] ?? false;
    final status = store['approvalStatus'] ?? 'pending';
    final createdAt = store['createdAt']?.toDate() ?? DateTime.now();
    final formattedDate = '${createdAt.year}年${createdAt.month}月${createdAt.day}日';
    
    // 実際のステータスを決定
    final actualStatus = isApproved ? 'approved' : status;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToStoreDetail(store),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー部分
              Row(
                children: [
                  // 店舗アイコン
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: store['iconImageUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              store['iconImageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.store,
                                  color: Colors.grey,
                                  size: 24,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.store,
                            color: Colors.grey,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 店舗情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store['name'] ?? '店舗名なし',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store['category'] ?? 'カテゴリなし',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // ステータスバッジ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(actualStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(actualStatus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 住所
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      store['address'] ?? '住所なし',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 電話番号
              if (store['phone'] != null && store['phone'].isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      store['phone'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 8),
              
              // 申請日
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '申請日: $formattedDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // アクションボタン
              if (actualStatus == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : () => _approveStore(store),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('承認'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : () => _rejectStore(store),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('拒否'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '承認待ち';
      case 'approved':
        return '承認済み';
      case 'rejected':
        return '拒否済み';
      default:
        return '不明';
    }
  }

  void _navigateToStoreDetail(Map<String, dynamic> store) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoreDetailView(store: store),
      ),
    );
  }

  Future<void> _approveStore(Map<String, dynamic> store) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(store['storeId'])
          .update({
        'isApproved': true,
        'approvalStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': FirebaseAuth.instance.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${store['name']} を承認しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('承認に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectStore(Map<String, dynamic> store) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(store['storeId'])
          .update({
        'approvalStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${store['name']} を拒否しました'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拒否に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
