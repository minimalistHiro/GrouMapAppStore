import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import 'create_coupon_view.dart';
import 'edit_coupon_view.dart';

class CouponsManageView extends ConsumerStatefulWidget {
  const CouponsManageView({Key? key}) : super(key: key);

  @override
  ConsumerState<CouponsManageView> createState() => _CouponsManageViewState();
}

class _CouponsManageViewState extends ConsumerState<CouponsManageView> {
  String _selectedFilter = 'all';
  final List<String> _filterOptions = ['all', 'active', 'expired', 'inactive'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'クーポン管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateCouponView(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final user = FirebaseAuth.instance.currentUser;
          
          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ログインが必要です'),
                ],
              ),
            );
          }
          
          final userStoreIdAsync = ref.watch(userStoreIdProvider);
          
          return userStoreIdAsync.when(
            data: (storeId) {
              if (storeId == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('店舗情報が見つかりません'),
                    ],
                  ),
                );
              }
              
              return Column(
                children: [
                  // フィルター
                  _buildFilterSection(),
                  
                  // クーポン一覧
                  Expanded(
                    child: _buildCouponsList(storeId),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('エラー: $error'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          const Text(
            'ステータス:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                style: const TextStyle(color: Colors.black87),
                items: _filterOptions.map((String option) {
                  String label;
                  switch (option) {
                    case 'all':
                      label = '全て';
                      break;
                    case 'active':
                      label = 'アクティブ';
                      break;
                    case 'expired':
                      label = '期限切れ';
                      break;
                    case 'inactive':
                      label = '非アクティブ';
                      break;
                    default:
                      label = option;
                  }
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFilter = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponsList(String storeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
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
              ],
            ),
          );
        }

        final coupons = snapshot.data?.docs ?? [];
        
        // 作成日時で降順ソート
        coupons.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt']?.toDate() ?? DateTime(1970);
          final bTime = (b.data() as Map<String, dynamic>)['createdAt']?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        
        // フィルター適用
        List<QueryDocumentSnapshot> filteredCoupons = coupons.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final now = DateTime.now();
          final validUntil = data['validUntil']?.toDate() ?? now;
          final isActive = data['isActive'] ?? false;
          
          switch (_selectedFilter) {
            case 'active':
              return isActive && validUntil.isAfter(now);
            case 'expired':
              return validUntil.isBefore(now);
            case 'inactive':
              return !isActive;
            default:
              return true;
          }
        }).toList();

        if (filteredCoupons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('クーポンがありません'),
                const SizedBox(height: 8),
                const Text('新しいクーポンを作成してみましょう！'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateCouponView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新規クーポンを作成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredCoupons.length,
          itemBuilder: (context, index) {
            final coupon = filteredCoupons[index];
            final data = coupon.data() as Map<String, dynamic>;
            return _buildCouponCard(data, storeId);
          },
        );
      },
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon, String storeId) {
    // 終了日の表示用フォーマット
    String formatEndDate() {
      try {
        final endDate = coupon['validUntil']?.toDate();
        if (endDate == null) return '期限不明';
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final couponDate = DateTime(endDate.year, endDate.month, endDate.day);
        
        String dateText;
        if (couponDate.isAtSameMomentAs(today)) {
          dateText = '今日';
        } else if (couponDate.isAtSameMomentAs(tomorrow)) {
          dateText = '明日';
        } else {
          dateText = '${endDate.month}月${endDate.day}日';
        }
        
        return '$dateText ${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}まで';
      } catch (e) {
        return '期限不明';
      }
    }

    // 割引表示用テキスト
    String getDiscountText() {
      final discountType = coupon['discountType'] ?? 'percentage';
      final discountValue = coupon['discountValue'] ?? 0.0;
      
      if (discountType == 'percentage') {
        return '${discountValue.toInt()}%OFF';
      } else if (discountType == 'fixed_amount') {
        return '${discountValue.toInt()}円OFF';
      } else if (discountType == 'fixed_price') {
        return '${discountValue.toInt()}円';
      }
      return '特典あり';
    }

    // ステータス判定
    bool isExpired() {
      try {
        final validUntil = coupon['validUntil']?.toDate();
        if (validUntil == null) return false;
        return validUntil.isBefore(DateTime.now());
      } catch (e) {
        return false;
      }
    }

    final expired = isExpired();
    final isActive = coupon['isActive'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () {
          // クーポン詳細画面に遷移（実装予定）
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('クーポン詳細画面は準備中です')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー部分
              Row(
                children: [
                  // ステータスバッジ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: expired
                          ? Colors.red.withOpacity(0.1)
                          : !isActive
                              ? Colors.grey.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: expired
                            ? Colors.red.withOpacity(0.3)
                            : !isActive
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      expired
                          ? '期限切れ'
                          : !isActive
                              ? '非アクティブ'
                              : 'アクティブ',
                      style: TextStyle(
                        fontSize: 12,
                        color: expired
                            ? Colors.red
                            : !isActive
                                ? Colors.grey
                                : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 割引情報
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      getDiscountText(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // タイトル
              Text(
                coupon['title'] ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // 説明
              Text(
                coupon['description'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // 画像がある場合
              if (coupon['imageUrl'] != null)
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      coupon['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              
              // フッター部分
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    formatEndDate(),
                    style: TextStyle(
                      fontSize: 12,
                      color: expired ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${coupon['usedCount'] ?? 0}/${coupon['usageLimit'] ?? 0}回使用',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // アクションボタン
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditCouponView(couponData: coupon),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isActive ? Icons.pause : Icons.play_arrow,
                          size: 20,
                          color: isActive ? Colors.orange : Colors.green,
                        ),
                        onPressed: () {
                          _toggleCouponStatus(coupon['couponId'], storeId, !isActive);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () {
                          _showDeleteDialog(coupon['couponId'], storeId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(String couponId, String storeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('クーポンを削除'),
          content: const Text('このクーポンを削除しますか？この操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteCoupon(couponId, storeId);
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCoupon(String couponId, String storeId) async {
    try {
      final couponDoc = await FirebaseFirestore.instance
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(couponId)
          .get();
      final imageUrl = couponDoc.data()?['imageUrl'] as String?;
      if (imageUrl != null && !imageUrl.startsWith('data:')) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint('Failed to delete coupon image: $e');
        }
      }

      await FirebaseFirestore.instance
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(couponId)
          .delete();
      await FirebaseFirestore.instance
          .collection('public_coupons')
          .doc(couponId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('クーポンを削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _toggleCouponStatus(String couponId, String storeId, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(couponId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance
          .collection('public_coupons')
          .doc(couponId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isActive ? 'クーポンを有効にしました' : 'クーポンを無効にしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ステータス変更に失敗しました: $e')),
        );
      }
    }
  }
}
