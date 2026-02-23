import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../settings/store_profile_edit_view.dart';
import '../settings/store_location_edit_view.dart';
import '../settings/menu_edit_view.dart';

class StoreDetailView extends ConsumerStatefulWidget {
  final Map<String, dynamic> store;

  const StoreDetailView({Key? key, required this.store}) : super(key: key);

  @override
  ConsumerState<StoreDetailView> createState() => _StoreDetailViewState();
}

class _StoreDetailViewState extends ConsumerState<StoreDetailView> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final isApproved = store['isApproved'] ?? false;
    final status = store['approvalStatus'] ?? 'pending';
    final actualStatus = isApproved ? 'approved' : status;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          store['name'] ?? '店舗詳細',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (actualStatus == 'pending')
            PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'approve') {
                  _approveStore(store);
                } else if (value == 'reject') {
                  _rejectStore(store);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'approve',
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 8),
                      Text('承認'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'reject',
                  child: Row(
                    children: [
                      Icon(Icons.close, color: Colors.red),
                      SizedBox(width: 8),
                      Text('拒否'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.more_vert),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーカード
            _buildHeaderCard(store, actualStatus),
            
            const SizedBox(height: 20),
            
            // 編集ボタンセクション（承認済みの場合のみ表示）
            if (actualStatus == 'approved')
              _buildEditButtonsSection(),
            
            if (actualStatus == 'approved')
              const SizedBox(height: 20),
            
            // 基本情報
            _buildBasicInfoCard(store),
            
            const SizedBox(height: 20),
            
            // 営業時間
            _buildBusinessHoursCard(store),
            
            const SizedBox(height: 20),
            
            // ソーシャルメディア
            _buildSocialMediaCard(store),
            
            const SizedBox(height: 20),
            
            // 統計情報
            _buildStatsCard(store),
            
            const SizedBox(height: 20),
            
            // アクションボタン（承認待ちの場合のみ）
            if (actualStatus == 'pending')
              _buildActionButtons(store),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> store, String status) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              _getStatusColor(status).withOpacity(0.1),
              _getStatusColor(status).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // 店舗アイコンと名前
            Row(
              children: [
                // 店舗アイコン
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: store['iconImageUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            store['iconImageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.store,
                                color: Colors.grey,
                                size: 40,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.store,
                          color: Colors.grey,
                          size: 40,
                        ),
                ),
                const SizedBox(width: 16),
                
                // 店舗情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store['name'] ?? '店舗名なし',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        store['category'] ?? 'カテゴリなし',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard(Map<String, dynamic> store) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '基本情報',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 住所
            _buildInfoRow(
              Icons.location_on,
              '住所',
              store['address'] ?? '住所なし',
            ),
            
            const SizedBox(height: 12),
            
            // 電話番号
            if (store['phone'] != null && store['phone'].isNotEmpty)
              _buildInfoRow(
                Icons.phone,
                '電話番号',
                store['phone'],
              ),
            
            if (store['phone'] != null && store['phone'].isNotEmpty)
              const SizedBox(height: 12),
            
            // 説明
            if (store['description'] != null && store['description'].isNotEmpty)
              _buildInfoRow(
                Icons.description,
                '説明',
                store['description'],
              ),
            
            if (store['description'] != null && store['description'].isNotEmpty)
              const SizedBox(height: 12),
            
            // 作成日
            _buildInfoRow(
              Icons.calendar_today,
              '申請日',
              _formatDate(store['createdAt']?.toDate()),
            ),
            
            // 承認日時
            if (store['approvedAt'] != null)
              _buildInfoRow(
                Icons.check_circle,
                '承認日時',
                _formatDate(store['approvedAt']?.toDate()),
              ),
            
            // 拒否日時
            if (store['rejectedAt'] != null)
              _buildInfoRow(
                Icons.cancel,
                '拒否日時',
                _formatDate(store['rejectedAt']?.toDate()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHoursCard(Map<String, dynamic> store) {
    final businessHours = store['businessHours'] as Map<String, dynamic>? ?? {};
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayNames = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '営業時間',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...days.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final dayName = dayNames[index];
              final dayData = businessHours[day] as Map<String, dynamic>? ?? {};
              final isOpen = dayData['isOpen'] ?? false;
              final openTime = dayData['open'] ?? '09:00';
              final closeTime = dayData['close'] ?? '18:00';
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        dayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (isOpen)
                      Text('$openTime - $closeTime')
                    else
                      const Text(
                        '定休日',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaCard(Map<String, dynamic> store) {
    final socialMedia = store['socialMedia'] as Map<String, dynamic>? ?? {};
    final socialItems = [
      {'key': 'instagram', 'label': 'Instagram', 'icon': Icons.camera_alt},
      {'key': 'x', 'label': 'X (Twitter)', 'icon': Icons.alternate_email},
      {'key': 'facebook', 'label': 'Facebook', 'icon': Icons.facebook},
      {'key': 'website', 'label': 'ウェブサイト', 'icon': Icons.language},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ソーシャルメディア',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...socialItems.map((item) {
              final value = socialMedia[item['key']] as String? ?? '';
              if (value.isEmpty) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> store) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '統計情報',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '総訪問者数',
                    '${store['totalVisitors'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'ゴールドスタンプ',
                    '${store['goldStamps'] ?? 0}',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '平均評価',
                    '${(store['averageRating'] ?? 0.0).toStringAsFixed(1)}',
                    Icons.star_rate,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '評価数',
                    '${store['totalRatings'] ?? 0}',
                    Icons.rate_review,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> store) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _approveStore(store),
            icon: const Icon(Icons.check, size: 20),
            label: const Text('承認'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _rejectStore(store),
            icon: const Icon(Icons.close, size: 20),
            label: const Text('拒否'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '不明';
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
        Navigator.of(context).pop();
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
        Navigator.of(context).pop();
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

  Widget _buildEditButtonsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '店舗管理',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEditButton(
                    icon: Icons.store,
                    label: 'プロフィール編集',
                    onTap: () => _navigateToProfileEdit(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEditButton(
                    icon: Icons.location_on,
                    label: '位置情報編集',
                    onTap: () => _navigateToLocationEdit(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEditButton(
                    icon: Icons.restaurant_menu,
                    label: 'メニュー編集',
                    onTap: () => _navigateToMenuEdit(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF6F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFFFF6B35),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfileEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoreProfileEditView(),
      ),
    );
  }

  void _navigateToLocationEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoreLocationEditView(),
      ),
    );
  }

  void _navigateToMenuEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MenuEditView(),
      ),
    );
  }
}
