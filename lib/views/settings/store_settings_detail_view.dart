import 'package:archive/archive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../utils/save_zip.dart';
import '../../providers/store_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import 'store_profile_edit_view.dart';
import 'store_location_edit_view.dart';
import 'menu_edit_view.dart';
import 'interior_images_view.dart';
import 'payment_methods_settings_view.dart';
import '../coupons/coupons_manage_view.dart';
import '../analytics/store_user_trend_view.dart';
import '../analytics/new_customer_trend_view.dart';
import '../analytics/coupon_usage_trend_view.dart';
import '../analytics/recommendation_trend_view.dart';

class StoreSettingsDetailView extends ConsumerWidget {
  final String storeId;
  final String storeName;

  const StoreSettingsDetailView({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  Color _getDefaultStoreColor(String category) {
    switch (category) {
      case 'レストラン':
        return Colors.red;
      case 'カフェ':
        return Colors.brown;
      case 'ショップ':
        return Colors.blue;
      case '美容院':
        return Colors.pink;
      case '薬局':
        return Colors.green;
      case 'コンビニ':
        return Colors.orange;
      case 'スーパー':
        return Colors.lightGreen;
      case '書店':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getDefaultStoreIcon(String category) {
    switch (category) {
      case 'レストラン':
        return Icons.restaurant;
      case 'カフェ':
        return Icons.local_cafe;
      case 'ショップ':
        return Icons.shopping_bag;
      case '美容院':
        return Icons.content_cut;
      case '薬局':
        return Icons.local_pharmacy;
      case 'コンビニ':
        return Icons.store;
      case 'スーパー':
        return Icons.shopping_cart;
      case '書店':
        return Icons.menu_book;
      default:
        return Icons.store;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeDataAsync = ref.watch(storeDataProvider(storeId));
    ref.watch(storeCouponsProvider(storeId));

    return Scaffold(
      appBar: CommonHeader(title: storeName),
      body: storeDataAsync.when(
        data: (storeData) {
          if (storeData == null) {
            return const Center(child: Text('店舗情報が見つかりません'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStoreInfoCard(storeData),
                const SizedBox(height: 24),
                _buildSection(
                  title: '店舗情報編集',
                  children: [
                    _buildSettingsItem(
                      icon: Icons.store,
                      title: '店舗プロフィール',
                      subtitle: '店舗の基本情報を編集',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                StoreProfileEditView(storeId: storeId),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.location_on,
                      title: '店舗位置情報',
                      subtitle: '店舗の位置情報を設定',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                StoreLocationEditView(storeId: storeId),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.restaurant_menu,
                      title: 'メニューを編集',
                      subtitle: '店舗のメニューを管理',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                MenuEditView(storeId: storeId),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.photo_library,
                      title: '店内画像設定',
                      subtitle: '店内画像を最大5枚まで登録',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                InteriorImagesView(storeId: storeId),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.payment,
                      title: '店舗決済方法設定',
                      subtitle: '利用可能な決済方法を設定',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                PaymentMethodsSettingsView(storeId: storeId),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.local_offer,
                      title: 'クーポン管理',
                      subtitle: 'この店舗のクーポンを管理',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CouponsManageView(
                              targetStoreId: storeId,
                              targetStoreName: storeName,
                              lockTargetStore: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'ポスター用プロンプトをコピー',
                        icon: const Icon(Icons.copy,
                            size: 20, color: Colors.white),
                        onPressed: () =>
                            _copyPosterPrompt(context, ref, storeData),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.download, color: Colors.white),
                        onPressed: () =>
                            _downloadPosterImages(context, ref, storeData),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDataSection(context),
                const SizedBox(height: 24),
                _buildCoinExchangeCouponUsageCard(ref),
                const SizedBox(height: 24),
                _buildPieChartsSection(ref),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  Widget _buildStoreInfoCard(Map<String, dynamic> storeData) {
    final String category = storeData['category'] ?? 'その他';
    final String name = storeData['name'] ?? '店舗名未設定';
    final String? iconImageUrl = storeData['iconImageUrl'] as String?;
    final String address = storeData['address'] ?? '';
    final Color baseColor = _getDefaultStoreColor(category);

    return Container(
      width: double.infinity,
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: baseColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: iconImageUrl != null
                  ? Image.network(
                      iconImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: baseColor.withOpacity(0.1),
                        child: Icon(
                          _getDefaultStoreIcon(category),
                          size: 28,
                          color: baseColor,
                        ),
                      ),
                    )
                  : Container(
                      color: baseColor.withOpacity(0.1),
                      child: Icon(
                        _getDefaultStoreIcon(category),
                        size: 28,
                        color: baseColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
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
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF6B35)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _copyPosterPrompt(
      BuildContext context, WidgetRef ref, Map<String, dynamic> storeData) {
    final buffer = StringBuffer();

    // 店舗名
    final name = storeData['name'] ?? '店舗名未設定';
    buffer.writeln('# $name');
    buffer.writeln();

    // 基本情報
    buffer.writeln('## 基本情報');
    final address = storeData['address'] ?? '';
    if (address.isNotEmpty) {
      buffer.writeln('- **住所**: $address');
    }
    final phone = storeData['phone'] ?? '';
    if (phone.isNotEmpty) {
      buffer.writeln('- **電話番号**: $phone');
    }
    final description = storeData['description'] ?? '';
    if (description.isNotEmpty) {
      buffer.writeln('- **店舗説明**: $description');
    }
    buffer.writeln();

    // 営業時間
    final businessHours = storeData['businessHours'] as Map<String, dynamic>?;
    if (businessHours != null) {
      buffer.writeln('## 営業時間');
      const dayOrder = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ];
      const dayNames = {
        'monday': '月曜日',
        'tuesday': '火曜日',
        'wednesday': '水曜日',
        'thursday': '木曜日',
        'friday': '金曜日',
        'saturday': '土曜日',
        'sunday': '日曜日',
      };
      for (final day in dayOrder) {
        final dayData = businessHours[day] as Map<String, dynamic>?;
        if (dayData != null) {
          final isOpen = dayData['isOpen'] ?? false;
          final dayName = dayNames[day] ?? day;
          if (isOpen) {
            final open = dayData['open'] ?? '';
            final close = dayData['close'] ?? '';
            buffer.writeln('- **$dayName**: $open〜$close');
          } else {
            buffer.writeln('- **$dayName**: 定休日');
          }
        }
      }
      buffer.writeln();
    }

    // クーポン情報
    final couponsAsync = ref.read(storeCouponsProvider(storeId));
    couponsAsync.when(
      data: (coupons) {
        final activeCoupons =
            coupons.where((c) => c['isActive'] == true).toList();
        if (activeCoupons.isNotEmpty) {
          buffer.writeln('## クーポン情報');
          for (final coupon in activeCoupons) {
            final title = coupon['title'] ?? '';
            buffer.writeln('### $title');
            final couponDescription = coupon['description'] ?? '';
            if (couponDescription.isNotEmpty) {
              buffer.writeln('- **内容**: $couponDescription');
            }
            final noExpiry = coupon['noExpiry'] ?? false;
            if (noExpiry) {
              buffer.writeln('- **期限**: 無期限');
            } else {
              final validUntil = coupon['validUntil'];
              if (validUntil != null) {
                final date = validUntil.toDate();
                buffer.writeln(
                    '- **期限**: ${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}');
              }
            }
            final requiredStampCount = coupon['requiredStampCount'];
            if (requiredStampCount != null) {
              buffer.writeln('- **必要スタンプ数**: $requiredStampCount');
            }
            buffer.writeln();
          }
        }
        _doCopy(context, buffer.toString());
      },
      loading: () {
        _doCopy(context, buffer.toString());
      },
      error: (_, __) {
        _doCopy(context, buffer.toString());
      },
    );
  }

  Future<void> _downloadPosterImages(BuildContext context, WidgetRef ref,
      Map<String, dynamic> storeData) async {
    // ローディングダイアログ表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final archive = Archive();
      final storeName = storeData['name'] ?? '店舗';

      // 店舗イメージ画像
      final storeImageUrl = storeData['storeImageUrl'] as String?;
      if (storeImageUrl != null && storeImageUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(storeImageUrl));
        if (response.statusCode == 200) {
          archive.addFile(ArchiveFile('store_image.jpg',
              response.bodyBytes.length, response.bodyBytes));
        }
      }

      // クーポン画像
      final couponsAsync = ref.read(storeCouponsProvider(storeId));
      List<Map<String, dynamic>> coupons = [];
      couponsAsync.whenData((data) => coupons = data);

      for (var i = 0; i < coupons.length; i++) {
        final coupon = coupons[i];
        final imageUrl = coupon['imageUrl'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              final title = coupon['title'] ?? 'coupon';
              final safeTitle = title.replaceAll(
                  RegExp(r'[^\w\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]'), '_');
              archive.addFile(ArchiveFile('coupon_${i + 1}_$safeTitle.jpg',
                  response.bodyBytes.length, response.bodyBytes));
            }
          } catch (_) {
            // 個別クーポン画像の取得失敗はスキップ
          }
        }
      }

      if (archive.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('お知らせ'),
              content: const Text('ダウンロード可能な画像がありません'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'))
              ],
            ),
          );
        }
        return;
      }

      // ZIP作成・保存
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) throw Exception('ZIPの作成に失敗しました');

      final safeStoreName = storeName.replaceAll(
          RegExp(r'[^\w\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]'), '_');
      final fileName = '${safeStoreName}_poster_images.zip';

      if (context.mounted) Navigator.of(context).pop();

      await saveZipFile(Uint8List.fromList(zipData), fileName);
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('エラー'),
            content: Text('画像のダウンロードに失敗しました: $e'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'))
            ],
          ),
        );
      }
    }
  }

  void _doCopy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text.trimRight()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ポスター用プロンプトをコピーしました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDataSection(BuildContext context) {
    final dataItems = [
      {
        'title': '店舗利用者推移',
        'icon': Icons.people_outline,
      },
      {
        'title': '新規顧客推移',
        'icon': Icons.person_add_outlined,
      },
      {
        'title': 'クーポン利用者推移',
        'icon': Icons.local_offer_outlined,
      },
      {
        'title': 'おすすめ表示推移',
        'icon': Icons.recommend_outlined,
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined,
                  color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                'データ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dataItems.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = dataItems[index];

              return InkWell(
                onTap: () {
                  _navigateToDataDetail(context, item['title'] as String);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: const Color(0xFFFF6B35),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.black38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToDataDetail(BuildContext context, String dataType) {
    switch (dataType) {
      case '店舗利用者推移':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreUserTrendView(storeId: storeId),
          ),
        );
        break;
      case '新規顧客推移':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewCustomerTrendView(storeId: storeId),
          ),
        );
        break;
      case 'クーポン利用者推移':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CouponUsageTrendView(storeId: storeId),
          ),
        );
        break;
      case 'おすすめ表示推移':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecommendationTrendView(storeId: storeId),
          ),
        );
        break;
    }
  }

  Widget _buildCoinExchangeCouponUsageCard(WidgetRef ref) {
    final usedCountAsync =
        ref.watch(coinExchangeCouponUsedCountProvider(storeId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monetization_on_outlined,
                  color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                '100円引きクーポン利用枚数',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ミッション > コイン交換で取得されたクーポン（累計）',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: usedCountAsync.when(
              data: (count) => Text(
                '$count枚',
                style: const TextStyle(
                  fontSize: 48,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF6B35),
                ),
              ),
              loading: () => const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFFFF6B35),
                ),
              ),
              error: (_, __) => const Text(
                '--枚',
                style: TextStyle(
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartsSection(WidgetRef ref) {
    final pieDataAsync = ref.watch(allVisitPieChartDataProvider(storeId));

    return pieDataAsync.when(
      data: (pieData) {
        final genderData = (pieData['gender'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            ) ??
            <String, int>{};
        final ageGroupData =
            (pieData['ageGroup'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num).toInt()),
                ) ??
                <String, int>{};
        final newRepeatData =
            (pieData['newRepeat'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num).toInt()),
                ) ??
                <String, int>{};

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart, color: Color(0xFFFF6B35), size: 24),
                  SizedBox(width: 8),
                  Text(
                    '全来店記録',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPieChartWithLegend(
                title: '男女比',
                data: genderData,
                colorMap: const {
                  '男性': Color(0xFF4FC3F7),
                  '女性': Color(0xFFFF8A80),
                  'その他': Color(0xFFCE93D8),
                  '未設定': Color(0xFFBDBDBD),
                },
              ),
              const SizedBox(height: 24),
              _buildPieChartWithLegend(
                title: '年齢別',
                data: ageGroupData,
                colorMap: const {
                  '~19': Color(0xFF81D4FA),
                  '20s': Color(0xFF4FC3F7),
                  '30s': Color(0xFF29B6F6),
                  '40s': Color(0xFFFFB74D),
                  '50s': Color(0xFFFF8A65),
                  '60+': Color(0xFFEF5350),
                  '未設定': Color(0xFFBDBDBD),
                },
              ),
              const SizedBox(height: 24),
              _buildPieChartWithLegend(
                title: '新規 / リピート',
                data: newRepeatData,
                colorMap: const {
                  '新規': Color(0xFF66BB6A),
                  'リピート': Color(0xFFFF6B35),
                },
              ),
            ],
          ),
        );
      },
      loading: () => _buildPieChartPlaceholder(),
      error: (error, stackTrace) {
        debugPrint('Error loading pie chart data: $error');
        return _buildPieChartPlaceholder();
      },
    );
  }

  Widget _buildPieChartWithLegend({
    required String title,
    required Map<String, int> data,
    required Map<String, Color> colorMap,
  }) {
    final total = data.values.fold<int>(0, (sum, v) => sum + v);
    final filteredData = Map.fromEntries(
      data.entries.where((e) => e.value > 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (total == 0)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'データがありません',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          )
        else
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    startDegreeOffset: 270,
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: filteredData.entries.map((entry) {
                      final percentage = (entry.value / total * 100);
                      return PieChartSectionData(
                        color: colorMap[entry.key] ?? Colors.grey,
                        value: entry.value.toDouble(),
                        title: '${percentage.round()}%',
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        radius: 45,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredData.entries.map((entry) {
                    final percentage = (entry.value / total * 100);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colorMap[entry.key] ?? Colors.grey,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.value}件 (${percentage.round()}%)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPieChartPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Color(0xFFFF6B35), size: 24),
              SizedBox(width: 8),
              Text(
                '全来店記録',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              '読込中...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
