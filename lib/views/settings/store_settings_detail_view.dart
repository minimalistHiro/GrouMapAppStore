import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_provider.dart';
import '../../widgets/common_header.dart';
import 'store_profile_edit_view.dart';
import 'store_location_edit_view.dart';
import 'menu_edit_view.dart';
import 'interior_images_view.dart';
import 'payment_methods_settings_view.dart';

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
}
