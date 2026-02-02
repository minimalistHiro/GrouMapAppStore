import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class StoreSelectionView extends ConsumerWidget {
  const StoreSelectionView({Key? key}) : super(key: key);

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
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('店舗選択'),
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
        title: const Text('店舗選択'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: _buildStoreList(context, ref, user.uid),
    );
  }

  Widget _buildStoreList(BuildContext context, WidgetRef ref, String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
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
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('エラーが発生しました: ${snapshot.error}'),
                const SizedBox(height: 16),
                CustomButton(
                  text: '再試行',
                  onPressed: () {
                    // プロバイダーを再読み込み
                    ref.invalidate(userStoreIdProvider);
                  },
                ),
              ],
            ),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final createdStores = List<String>.from(userData?['createdStores'] ?? []);
        final currentStoreId = userData?['currentStoreId'] as String?;

        if (createdStores.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.store, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  '作成した店舗がありません',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'まず店舗を作成してください',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: '戻る',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: createdStores.length,
          itemBuilder: (context, index) {
            final storeId = createdStores[index];
            return _buildStoreCard(context, ref, storeId, currentStoreId);
          },
        );
      },
    );
  }

  Widget _buildStoreCard(BuildContext context, WidgetRef ref, String storeId, String? currentStoreId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStoreCardPlaceholder();
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildStoreCardPlaceholder();
        }

        final storeData = snapshot.data!.data() as Map<String, dynamic>;
        final isSelected = currentStoreId == storeId;

        final String category = storeData['category'] ?? 'その他';
        final Color baseColor = _getDefaultStoreColor(category);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: const Color(0xFFFF6B35), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: baseColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: storeData['iconImageUrl'] != null
                    ? Image.network(
                        storeData['iconImageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: baseColor.withOpacity(0.1),
                          child: Icon(
                            _getDefaultStoreIcon(category),
                            size: 30,
                            color: baseColor,
                          ),
                        ),
                      )
                    : Container(
                        color: baseColor.withOpacity(0.1),
                        child: Icon(
                          _getDefaultStoreIcon(category),
                          size: 30,
                          color: baseColor,
                        ),
                      ),
              ),
            ),
            title: Text(
              storeData['name'] ?? '店舗名未設定',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFFF6B35) : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  storeData['category'] ?? 'カテゴリ未設定',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        storeData['address'] ?? '住所未設定',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: isSelected
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '選択中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
            onTap: isSelected
                ? null
                : () => _selectStore(context, ref, storeId),
          ),
        );
      },
    );
  }

  Widget _buildStoreCardPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // 店舗アイコン（プレースホルダー）
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.grey[300],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 店舗情報（プレースホルダー）
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStore(BuildContext context, WidgetRef ref, String storeId) async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // ローディングダイアログを表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('店舗を切り替えています...'),
              ],
            ),
          );
        },
      );

      // ユーザーの現在の店舗IDを更新
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'currentStoreId': storeId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ローディングダイアログを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('店舗を切り替えました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 設定画面に戻る
        Navigator.of(context).pop();
      }
    } catch (e) {
      // ローディングダイアログを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // エラーメッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗の切り替えに失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
