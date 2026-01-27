import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/qr_verification_provider.dart';
import '../../widgets/custom_button.dart';
import '../points/point_usage_checkout_prompt_view.dart';

class CouponSelectForCheckoutView extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final int usedPoints;

  const CouponSelectForCheckoutView({
    Key? key,
    required this.userId,
    required this.userName,
    required this.usedPoints,
  }) : super(key: key);

  @override
  ConsumerState<CouponSelectForCheckoutView> createState() =>
      _CouponSelectForCheckoutViewState();
}

class _CouponSelectForCheckoutViewState
    extends ConsumerState<CouponSelectForCheckoutView> {
  String? _storeId;
  bool _isLoadingStoreId = true;
  final Set<String> _selectedCouponIds = {};

  @override
  void initState() {
    super.initState();
    _loadStoreId();
  }

  Future<void> _loadStoreId() async {
    try {
      final storeSettings = ref.read(storeSettingsProvider);
      if (storeSettings != null && storeSettings.storeId.isNotEmpty) {
        setState(() {
          _storeId = storeSettings.storeId;
          _isLoadingStoreId = false;
        });
        return;
      }

      final authState = ref.read(authStateProvider);
      final storeUser = authState.value;
      if (storeUser == null) {
        setState(() {
          _isLoadingStoreId = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(storeUser.uid)
          .get();
      final data = userDoc.data();
      final currentStoreId = data?['currentStoreId'];
      setState(() {
        _storeId = currentStoreId is String && currentStoreId.isNotEmpty
            ? currentStoreId
            : null;
        _isLoadingStoreId = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingStoreId = false;
      });
    }
  }

  void _proceedToCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PointUsageCheckoutPromptView(
          userId: widget.userId,
          userName: widget.userName,
          usedPoints: widget.usedPoints,
          selectedCouponIds: _selectedCouponIds.toList(),
        ),
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _usedCouponsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('used_coupons')
        .snapshots();
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  DateTime? _parseValidUntil(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('クーポン選択'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingStoreId
          ? const Center(child: CircularProgressIndicator())
          : _storeId == null
              ? _buildStoreIdError()
              : _buildCouponList(_storeId!),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          color: Colors.white,
          child: _selectedCouponIds.isEmpty
              ? SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _proceedToCheckout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B35),
                      side: const BorderSide(color: Color(0xFFFF6B35)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'クーポンを使わず次へ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : CustomButton(
                  text: '選択クーポンを使用して次へ',
                  onPressed: _proceedToCheckout,
                ),
        ),
      ),
    );
  }

  Widget _buildStoreIdError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              '店舗情報が取得できませんでした',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'クーポン選択をスキップして会計に進みます。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: '会計へ進む',
              onPressed: _proceedToCheckout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponList(String storeId) {
    final couponsAsync = ref.watch(storeCouponsProvider(storeId));
    return couponsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('クーポンの取得に失敗しました: $error'),
      ),
      data: (coupons) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _usedCouponsStream(),
          builder: (context, usedSnapshot) {
            if (usedSnapshot.hasError) {
              return const Center(
                child: Text('使用済みクーポンの取得に失敗しました'),
              );
            }

            final usedIds = <String>{};
            final usedDocs = usedSnapshot.data?.docs ?? [];
            for (final doc in usedDocs) {
              final data = doc.data();
              final usedStoreId = data['storeId'] as String?;
              if (usedStoreId != storeId) continue;
              final couponId = (data['couponId'] as String?) ?? doc.id;
              if (couponId.isNotEmpty) {
                usedIds.add(couponId);
              }
            }

            final now = DateTime.now();
            final availableCoupons = coupons.where((coupon) {
              final couponId = (coupon['id'] as String?) ?? '';
              if (couponId.isEmpty) return false;
              final isActive = coupon['isActive'] as bool? ?? true;
              final validUntil = _parseValidUntil(coupon['validUntil']);
              final usedCount = _parseInt(coupon['usedCount']);
              final usageLimit = _parseInt(coupon['usageLimit']);
              if (!isActive) return false;
              if (validUntil == null || !validUntil.isAfter(now)) return false;
              if (usedCount >= usageLimit) return false;
              if (usedIds.contains(couponId)) return false;
              return true;
            }).toList();

            if (availableCoupons.isEmpty) {
              return const Center(
                child: Text('利用可能なクーポンがありません'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableCoupons.length,
              itemBuilder: (context, index) {
                final coupon = availableCoupons[index];
                final couponId = coupon['id'] as String;
                final title = (coupon['title'] as String?) ?? 'タイトルなし';
                final description =
                    (coupon['description'] as String?) ?? '';
                final validUntil = _parseValidUntil(coupon['validUntil']);
                final usageLimit = _parseInt(coupon['usageLimit']);
                final usedCount = _parseInt(coupon['usedCount']);
                final remaining = usageLimit - usedCount;
                final isSelected = _selectedCouponIds.contains(couponId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSelected
                      ? const Color(0xFFFFF2EC)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFFFF6B35)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCouponIds.remove(couponId);
                        } else {
                          _selectedCouponIds.add(couponId);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) {
                              setState(() {
                                if (isSelected) {
                                  _selectedCouponIds.remove(couponId);
                                } else {
                                  _selectedCouponIds.add(couponId);
                                }
                              });
                            },
                            activeColor: const Color(0xFFFF6B35),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '残り$remaining枚',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (validUntil != null)
                                      Text(
                                        '期限: ${validUntil.month}/${validUntil.day} ${validUntil.hour.toString().padLeft(2, '0')}:${validUntil.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
