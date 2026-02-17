import 'package:archive/archive.dart';
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

class StoreSettingsDetailView extends ConsumerWidget {
  final String storeId;
  final String storeName;

  const StoreSettingsDetailView({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

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
                            builder: (context) => StoreProfileEditView(storeId: storeId),
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
                            builder: (context) => StoreLocationEditView(storeId: storeId),
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
                            builder: (context) => MenuEditView(storeId: storeId),
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
                            builder: (context) => InteriorImagesView(storeId: storeId),
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
                            builder: (context) => PaymentMethodsSettingsView(storeId: storeId),
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
                        icon: const Icon(Icons.copy, size: 20, color: Colors.white),
                        onPressed: () => _copyPosterPrompt(context, ref, storeData),
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
                        onPressed: () => _downloadPosterImages(context, ref, storeData),
                      ),
                    ),
                  ],
                ),
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

  void _copyPosterPrompt(BuildContext context, WidgetRef ref, Map<String, dynamic> storeData) {
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
      const dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
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
        final activeCoupons = coupons.where((c) => c['isActive'] == true).toList();
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
                buffer.writeln('- **期限**: ${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}');
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

  Future<void> _downloadPosterImages(BuildContext context, WidgetRef ref, Map<String, dynamic> storeData) async {
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
          archive.addFile(ArchiveFile('store_image.jpg', response.bodyBytes.length, response.bodyBytes));
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
              final safeTitle = title.replaceAll(RegExp(r'[^\w\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]'), '_');
              archive.addFile(ArchiveFile('coupon_${i + 1}_$safeTitle.jpg', response.bodyBytes.length, response.bodyBytes));
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
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
            ),
          );
        }
        return;
      }

      // ZIP作成・保存
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) throw Exception('ZIPの作成に失敗しました');

      final safeStoreName = storeName.replaceAll(RegExp(r'[^\w\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]'), '_');
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
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
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
}
