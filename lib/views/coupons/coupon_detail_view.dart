import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import 'edit_coupon_view.dart';

class StoreCouponDetailView extends StatefulWidget {
  final Map<String, dynamic> coupon;

  const StoreCouponDetailView({Key? key, required this.coupon}) : super(key: key);

  @override
  State<StoreCouponDetailView> createState() => _StoreCouponDetailViewState();
}

class _StoreCouponDetailViewState extends State<StoreCouponDetailView> {
  @override
  void initState() {
    super.initState();
    _incrementViewCount();
  }

  Future<void> _incrementViewCount() async {
    try {
      final storeId = widget.coupon['storeId'] as String?;
      final couponId = widget.coupon['couponId'] as String? ?? widget.coupon['id'] as String?;
      if (storeId == null || storeId.isEmpty || couponId == null || couponId.isEmpty) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(couponId)
          .update({
        'viewCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 詳細画面の表示に影響しないため握りつぶす
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  String _formatValidUntil() {
    try {
      final validUntil = _parseDate(widget.coupon['validUntil']);
      if (validUntil == null) return '期限不明';
      if (widget.coupon['noExpiry'] == true || validUntil.year >= 2100) {
        return '無期限';
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final couponDate = DateTime(validUntil.year, validUntil.month, validUntil.day);

      String dateText;
      if (couponDate.isAtSameMomentAs(today)) {
        dateText = '今日';
      } else if (couponDate.isAtSameMomentAs(tomorrow)) {
        dateText = '明日';
      } else {
        dateText = '${validUntil.month}月${validUntil.day}日';
      }

      return '$dateText ${validUntil.hour.toString().padLeft(2, '0')}:${validUntil.minute.toString().padLeft(2, '0')}まで';
    } catch (_) {
      return '期限不明';
    }
  }

  String _getDiscountText() {
    final discountType = widget.coupon['discountType'] ?? 'percentage';
    final discountValue = (widget.coupon['discountValue'] as num?) ?? 0;

    if (discountType == 'percentage') {
      return '${discountValue.toInt()}%OFF';
    } else if (discountType == 'fixed_amount') {
      return '${discountValue.toInt()}円OFF';
    } else if (discountType == 'fixed_price') {
      return '${discountValue.toInt()}円';
    }
    return '特典あり';
  }

  IconData _getCouponIcon() {
    final couponType = widget.coupon['couponType'] ?? 'discount';
    switch (couponType) {
      case 'free_shipping':
        return Icons.local_shipping;
      case 'buy_one_get_one':
        return Icons.shopping_bag;
      case 'cashback':
        return Icons.monetization_on;
      case 'points_multiplier':
        return Icons.stars;
      case 'gift':
        return Icons.card_giftcard;
      case 'special_offer':
        return Icons.campaign;
      default:
        return Icons.local_offer;
    }
  }

  String _getCouponTypeText() {
    final couponType = widget.coupon['couponType'] ?? 'discount';
    switch (couponType) {
      case 'free_shipping':
        return '送料無料';
      case 'buy_one_get_one':
        return '買い得';
      case 'cashback':
        return 'キャッシュバック';
      case 'points_multiplier':
        return 'ポイント倍増';
      case 'gift':
        return 'プレゼント';
      case 'special_offer':
        return '特別オファー';
      default:
        return '割引';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: 'クーポン'),
      backgroundColor: const Color(0xFFFBF6F2),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: CustomButton(
            text: 'クーポンを編集',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditCouponView(couponData: widget.coupon),
                ),
              );
            },
            backgroundColor: const Color(0xFFFF6B35),
            textColor: Colors.white,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          _buildCouponHeader(),
          _buildCouponInfo(),
          _buildCouponDetails(),
          _buildStoreInfo(),
          _buildNotice(),
        ],
      ),
    );
  }

  Widget _buildCouponHeader() {
    final imageUrl = widget.coupon['imageUrl'] as String?;
    final Widget imageContent = imageUrl != null
        ? Image.network(
            imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFFFF6B35),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildNoImageHeader();
            },
          )
        : _buildNoImageHeader();

    return SliverToBoxAdapter(
      child: AspectRatio(
        aspectRatio: 1,
        child: imageContent,
      ),
    );
  }

  Widget _buildNoImageHeader() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFFF6B35),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              'クーポン画像なし',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponInfo() {
    final requiredStampCount =
        (widget.coupon['requiredStampCount'] as num?)?.toInt() ?? 0;

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.coupon['title'] ?? 'タイトルなし',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.coupon['description'] ?? '説明なし',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '必要スタンプ: $requiredStampCount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getDiscountText(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCouponIcon(),
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCouponTypeText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
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

  Widget _buildCouponDetails() {
    final usageLimit = (widget.coupon['usageLimit'] as num?)?.toInt() ?? 0;
    final usedCount = (widget.coupon['usedCount'] as num?)?.toInt() ?? 0;
    final noUsageLimit = widget.coupon['noUsageLimit'] == true;
    final createdAt = _parseDate(widget.coupon['createdAt']);
    final createdAtText = createdAt != null
        ? '${createdAt.year}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')}'
        : '日付不明';

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'クーポン詳細',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.access_time,
              label: '有効期限',
              value: _formatValidUntil(),
              valueColor: Colors.red[700]!,
            ),
            if (!noUsageLimit) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.inventory,
                label: '残り枚数',
                value: '${usageLimit - usedCount}枚',
                valueColor: Colors.green[700]!,
              ),
            ],
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: '作成日',
              value: createdAtText,
              valueColor: Colors.grey[700]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfo() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '店舗情報',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.store,
              label: '店舗名',
              value: widget.coupon['storeName'] ?? '店舗名なし',
              valueColor: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotice() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 20),
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'クーポンは店舗で提示してご利用ください。\n有効期限を過ぎたクーポンは使用できません。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
