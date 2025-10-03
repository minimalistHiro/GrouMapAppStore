import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/badge_provider.dart';
import 'badge_create_view.dart';
import 'badge_edit_view.dart';

class BadgeManageView extends ConsumerStatefulWidget {
  const BadgeManageView({Key? key}) : super(key: key);

  @override
  ConsumerState<BadgeManageView> createState() => _BadgeManageViewState();
}

class _BadgeManageViewState extends ConsumerState<BadgeManageView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'すべて';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgesAsync = ref.watch(badgesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'バッジ管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            tooltip: 'バッジを作成',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BadgeCreateView(),
                ),
              );
            },
          ),
        ],
      ),
      body: badgesAsync.when(
        data: (badges) {
          if (badges.isEmpty) {
            return _buildEmptyState(context);
          }
          
          // 表示順でソート
          final sortedBadges = List<Map<String, dynamic>>.from(badges)
            ..sort((a, b) {
              final orderA = a['order'] as int? ?? 0;
              final orderB = b['order'] as int? ?? 0;
              return orderA.compareTo(orderB);
            });
          
          // カテゴリを動的生成
          final categories = <String>{'すべて'}
            ..addAll(sortedBadges.map((b) => b['category'] as String? ?? '未分類').where((c) => c.isNotEmpty));
          
          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = 'すべて';
          }
          
          // カテゴリでフィルタリング
          final filteredBadges = _selectedCategory == 'すべて'
              ? sortedBadges
              : sortedBadges.where((b) => (b['category'] as String? ?? '未分類') == _selectedCategory).toList();
          
          return _buildBadgeList(context, filteredBadges, categories.toList());
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'バッジの取得に失敗しました',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(badgesProvider),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'バッジがありません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '新しいバッジを作成しましょう',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BadgeCreateView(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('バッジを作成'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeList(BuildContext context, List<Map<String, dynamic>> badges, List<String> categories) {
    return Column(
      children: [
        // 統計情報
        _buildStatsCard(badges),
        
        // カテゴリタブ
        _buildCategoryTabs(categories),
        
        // バッジ一覧（グリッドレイアウト）
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return _buildBadgeCard(context, badge);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs(List<String> categories) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: const Color(0xFFFF6B35).withOpacity(0.2),
              checkmarkColor: const Color(0xFFFF6B35),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(List<Map<String, dynamic>> badges) {
    final totalBadges = badges.length;
    final activeBadges = badges.where((badge) => badge['isActive'] == true).length;
    final inactiveBadges = totalBadges - activeBadges;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              '総バッジ数',
              totalBadges.toString(),
              Icons.workspace_premium,
              Colors.blue,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'アクティブ',
              activeBadges.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              '非アクティブ',
              inactiveBadges.toString(),
              Icons.pause_circle,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
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
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBadgeCard(BuildContext context, Map<String, dynamic> badge) {
    final rarity = badge['rarity'] as String? ?? 'bronze';
    final rarityInfo = rarityOptions.firstWhere(
      (option) => option['value'] == rarity,
      orElse: () => rarityOptions.first,
    );
    final isActive = badge['isActive'] == true;

    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badge),
      onLongPress: () => _showContextMenu(context, badge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // バッジアイコン
              _getBadgeIcon(
                badge['imageUrl'],
                rarityInfo: rarityInfo,
                isActive: isActive,
                size: 75,
              ),
              
              const SizedBox(height: 6),
              
              // バッジ名
              Text(
                badge['name'] ?? 'バッジ名なし',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black87 : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 3),
              
              // レア度表示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: rarityInfo['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: rarityInfo['color'], width: 1),
                ),
                child: Text(
                  rarityInfo['label'],
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: rarityInfo['color'],
                  ),
                ),
              ),
              
              const SizedBox(height: 2),
              
              // アクティブ状態
              Icon(
                isActive ? Icons.check_circle : Icons.pause_circle,
                size: 10,
                color: isActive ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getBadgeIcon(String? imageUrl, {required Map<String, dynamic> rarityInfo, required bool isActive, double size = 24}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Opacity(
          opacity: isActive ? 1.0 : 0.5,
          child: Image.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.workspace_premium,
                size: size,
                color: isActive ? rarityInfo['color'] : Colors.grey,
              );
            },
          ),
        ),
      );
    }
    
    return Icon(
      Icons.workspace_premium,
      size: size,
      color: isActive ? rarityInfo['color'] : Colors.grey,
    );
  }

  void _showContextMenu(BuildContext context, Map<String, dynamic> badge) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('編集'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BadgeEditView(badgeId: badge['id']),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('削除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, badge);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, Map<String, dynamic> badge) {
    final rarity = badge['rarity'] as String? ?? 'bronze';
    final rarityInfo = rarityOptions.firstWhere(
      (option) => option['value'] == rarity,
      orElse: () => rarityOptions.first,
    );
    final category = badge['category'] as String? ?? 'basic';
    final categoryInfo = categoryOptions.firstWhere(
      (option) => option['value'] == category,
      orElse: () => categoryOptions.first,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[100],
              backgroundImage: badge['imageUrl'] != null
                  ? NetworkImage(badge['imageUrl'])
                  : null,
              child: badge['imageUrl'] == null
                  ? Icon(
                      Icons.workspace_premium,
                      color: rarityInfo['color'],
                      size: 48,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              badge['name'] ?? 'バッジ名なし',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge['description'] ?? '説明なし',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rarityInfo['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: rarityInfo['color'], width: 1),
                  ),
                  child: Text(
                    rarityInfo['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: rarityInfo['color'],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Text(
                    categoryInfo['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (badge['isActive'] == true ? Colors.green : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: badge['isActive'] == true ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    badge['isActive'] == true ? Icons.check_circle : Icons.pause_circle,
                    size: 20,
                    color: badge['isActive'] == true ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    badge['isActive'] == true ? 'アクティブ' : '非アクティブ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: badge['isActive'] == true ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '表示順: ${badge['order'] ?? 0}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '要求値: ${badge['requiredValue'] ?? 0}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BadgeEditView(badgeId: badge['id']),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('編集'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バッジを削除'),
        content: Text('「${badge['name']}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: バッジ削除処理を実装
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('バッジを削除しました')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
