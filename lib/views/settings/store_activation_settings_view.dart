import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/common_header.dart';
import '../../widgets/custom_switch_tile.dart';
import 'store_settings_detail_view.dart';

class StoreActivationSettingsView extends StatefulWidget {
  const StoreActivationSettingsView({super.key});

  @override
  State<StoreActivationSettingsView> createState() =>
      _StoreActivationSettingsViewState();
}

class _StoreActivationSettingsViewState
    extends State<StoreActivationSettingsView> {
  final Set<String> _updatingStoreIds = <String>{};

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

  Future<void> _toggleStoreActive(String storeId, bool isActive) async {
    setState(() {
      _updatingStoreIds.add(storeId);
    });

    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .update({'isActive': isActive});
    } catch (e) {
      if (mounted) {
        _showErrorDialog('更新に失敗しました。時間をおいて再度お試しください。');
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingStoreIds.remove(storeId);
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('エラー'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: '店舗設定'),
      body: Container(
        color: const Color(0xFFFBF6F2),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('stores').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('店舗情報の読み込みに失敗しました'));
            }

            final docs = snapshot.data?.docs ?? [];
            final approvedDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isApproved = data['isApproved'] == true;
              final status = data['approvalStatus'] as String?;
              return isApproved || status == 'approved';
            }).toList();

            if (approvedDocs.isEmpty) {
              return const Center(child: Text('承認済みの店舗がありません'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: approvedDocs.length,
              itemBuilder: (context, index) {
                final store = approvedDocs[index];
                final data = store.data() as Map<String, dynamic>;
                final String category = data['category'] ?? 'その他';
                final String name = data['name'] ?? '店舗名未設定';
                final String? iconImageUrl = data['iconImageUrl'] as String?;
                final bool isActive = data['isActive'] as bool? ?? true;
                final bool isUpdating = _updatingStoreIds.contains(store.id);
                final Color baseColor = _getDefaultStoreColor(category);
                final String visibilityStatusText = isUpdating
                    ? '設定を更新しています...'
                    : isActive
                        ? '現在、ユーザーに公開中です'
                        : '現在、ユーザーには非表示です';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => StoreSettingsDetailView(
                                storeId: store.id,
                                storeName: name,
                              ),
                            ),
                          );
                        },
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
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
                                    const SizedBox(height: 6),
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 0),
                      CustomSwitchListTile(
                        title: const Text('店舗一覧に表示'),
                        subtitle: Text(visibilityStatusText),
                        value: isActive,
                        onChanged: isUpdating
                            ? null
                            : (value) => _toggleStoreActive(store.id, value),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
