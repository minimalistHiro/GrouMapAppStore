import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import 'create_coupon_view.dart';
import 'edit_coupon_view.dart';

class CouponsManageView extends ConsumerStatefulWidget {
  final String? targetStoreId;
  final String? targetStoreName;
  final bool lockTargetStore;

  const CouponsManageView({
    Key? key,
    this.targetStoreId,
    this.targetStoreName,
    this.lockTargetStore = false,
  }) : super(key: key);

  @override
  ConsumerState<CouponsManageView> createState() => _CouponsManageViewState();
}

class _CouponsManageViewState extends ConsumerState<CouponsManageView> {
  static const Color _accentColor = Color(0xFFFF6B35);
  static const Color _backgroundColor = Color(0xFFFBF6F2);
  static const int _maxCouponsPerStore = 3;

  String _selectedFilter = 'all';
  final List<String> _filterOptions = ['all', 'active', 'expired', 'inactive'];

  String? _sanitizeStoreName(String? name) {
    if (name == null) return null;
    final trimmed = name.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<String?> _resolveStoreName(String storeId,
      {String? fallbackName}) async {
    final normalizedFallback = _sanitizeStoreName(fallbackName);
    if (normalizedFallback != null) {
      return normalizedFallback;
    }
    try {
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();
      final storeData = storeDoc.data();
      return _sanitizeStoreName(storeData?['name'] as String?);
    } catch (_) {
      return normalizedFallback;
    }
  }

  Future<void> _openCreateCouponView({
    required String storeId,
    String? storeName,
  }) async {
    final resolvedStoreName =
        await _resolveStoreName(storeId, fallbackName: storeName);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateCouponView(
          initialStoreId: storeId,
          initialStoreName: resolvedStoreName,
          lockStore: widget.lockTargetStore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const CommonHeader(title: 'クーポン管理'),
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

          final targetStoreId = widget.targetStoreId;
          if (targetStoreId != null && targetStoreId.isNotEmpty) {
            return _buildCouponsContent(
              storeId: targetStoreId,
              storeName: widget.targetStoreName,
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
              return _buildCouponsContent(storeId: storeId);
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

  Widget _buildCouponsContent({
    required String storeId,
    String? storeName,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .snapshots(),
      builder: (context, snapshot) {
        final totalCouponCount = snapshot.data?.docs.length ?? 0;
        return Column(
          children: [
            _buildFilterSection(),
            Expanded(
              child: _buildCouponsListFromSnapshot(
                snapshot: snapshot,
                storeId: storeId,
                storeName: storeName,
                totalCouponCount: totalCouponCount,
              ),
            ),
            _buildCreateCouponButton(
              storeId: storeId,
              storeName: storeName,
              totalCouponCount: totalCouponCount,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: _accentColor, size: 20),
          const SizedBox(width: 12),
          const Text(
            'ステータス:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                iconEnabledColor: _accentColor,
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

  Widget _buildCouponsListFromSnapshot({
    required AsyncSnapshot<QuerySnapshot> snapshot,
    required String storeId,
    String? storeName,
    required int totalCouponCount,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: _accentColor),
      );
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
      final aTime = (a.data() as Map<String, dynamic>)['createdAt']?.toDate() ??
          DateTime(1970);
      final bTime = (b.data() as Map<String, dynamic>)['createdAt']?.toDate() ??
          DateTime(1970);
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
      final isLimitReached = totalCouponCount >= _maxCouponsPerStore;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('クーポンがありません'),
            const SizedBox(height: 8),
            Text(isLimitReached
                ? 'フィルター条件に一致するクーポンがありません'
                : '新しいクーポンを作成してみましょう！'),
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
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon, String storeId) {
    // 終了日の表示用フォーマット
    String formatEndDate() {
      try {
        final endDate = coupon['validUntil']?.toDate();
        if (endDate == null) return '期限不明';
        if (coupon['noExpiry'] == true || endDate.year >= 2100) return '無期限';

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
        if (coupon['noExpiry'] == true || validUntil.year >= 2100) return false;
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditCouponView(couponData: coupon),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _accentColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      getDiscountText(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _accentColor,
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

                  if (coupon['noUsageLimit'] != true) ...[
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${coupon['usedCount'] ?? 0}/${coupon['usageLimit'] ?? 0}回使用',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // アクションボタン
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isActive ? Icons.pause : Icons.play_arrow,
                          size: 20,
                          color: isActive ? Colors.orange : Colors.green,
                        ),
                        onPressed: () {
                          _toggleCouponStatus(
                              coupon['couponId'], storeId, !isActive);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
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

  Widget _buildCreateCouponButton({
    required String storeId,
    String? storeName,
    required int totalCouponCount,
  }) {
    final isLimitReached = totalCouponCount >= _maxCouponsPerStore;
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLimitReached)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'クーポンは1店舗あたり最大${_maxCouponsPerStore}枚まで作成できます',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          CustomButton(
            text: '新規クーポンを作成',
            icon: Icon(
              Icons.add,
              color: isLimitReached ? Colors.grey.shade600 : Colors.white,
              size: 18,
            ),
            onPressed: isLimitReached
                ? null
                : () => _openCreateCouponView(
                      storeId: storeId,
                      storeName: storeName,
                    ),
            height: 48,
            backgroundColor:
                isLimitReached ? Colors.grey.shade400 : _accentColor,
          ),
        ],
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

  Future<void> _toggleCouponStatus(
      String couponId, String storeId, bool isActive) async {
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
