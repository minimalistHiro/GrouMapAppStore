import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pill_tab_bar.dart';
import 'menu_create_view.dart';
import 'menu_item_edit_view.dart';
import 'menu_option_groups_view.dart';

class MenuEditView extends ConsumerStatefulWidget {
  static const List<String> menuCategories = ['コース', '料理', 'ドリンク', 'デザート'];

  final String? storeId;
  const MenuEditView({Key? key, this.storeId}) : super(key: key);

  @override
  ConsumerState<MenuEditView> createState() => _MenuEditViewState();
}

class _MenuEditViewState extends ConsumerState<MenuEditView> {
  String? _selectedStoreId;
  bool _isLoading = false;
  int _selectedCategoryIndex = 0;

  // メニューアイテムリスト
  List<Map<String, dynamic>> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storeId = widget.storeId ?? ref.read(userStoreIdProvider).when(
        data: (data) => data,
        loading: () => null,
        error: (error, stackTrace) => null,
      );

      if (storeId == null) {
        throw Exception('店舗情報が見つかりません');
      }

      _selectedStoreId = storeId;
      await _loadMenuItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMenuItems() async {
    if (_selectedStoreId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(_selectedStoreId)
          .collection('menu')
          .get();

      final items = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      if (mounted) {
        setState(() {
          _menuItems = _sortMenuItems(items);
        });
      }
    } catch (e) {
      print('メニューアイテムの読み込みに失敗: $e');
    }
  }

  int _parseSortOrder(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  int _parseCreatedAtMillis(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().millisecondsSinceEpoch;
    }
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  List<Map<String, dynamic>> _sortMenuItems(List<Map<String, dynamic>> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      final aOrder = _parseSortOrder(a['sortOrder']);
      final bOrder = _parseSortOrder(b['sortOrder']);
      final aHasOrder = aOrder > 0;
      final bHasOrder = bOrder > 0;

      if (aHasOrder && bHasOrder) {
        return aOrder.compareTo(bOrder);
      }
      if (aHasOrder != bHasOrder) {
        return aHasOrder ? -1 : 1;
      }

      final aCreated = _parseCreatedAtMillis(a['createdAt']);
      final bCreated = _parseCreatedAtMillis(b['createdAt']);
      return bCreated.compareTo(aCreated);
    });
    return sorted;
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    final category = MenuEditView.menuCategories[_selectedCategoryIndex];
    return _menuItems
        .where((item) => item['category'] == category)
        .toList();
  }

  void _navigateToOptionGroups() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MenuOptionGroupsView(
          storeId: _selectedStoreId!,
        ),
      ),
    );
  }

  Future<void> _navigateToCreateMenu() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MenuCreateView(
          storeId: _selectedStoreId!,
        ),
      ),
    );
    if (result == true) {
      await _loadMenuItems();
    }
  }

  Future<void> _navigateToEditItem(Map<String, dynamic> item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MenuItemEditView(
          menuItem: item,
          storeId: _selectedStoreId!,
        ),
      ),
    );
    if (result == true) {
      await _loadMenuItems();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    final filteredItems = _getFilteredItems();
    if (newIndex > oldIndex) newIndex -= 1;

    final movedItem = filteredItems.removeAt(oldIndex);
    filteredItems.insert(newIndex, movedItem);

    // filteredItemsの新しい順序をsortOrderに反映
    setState(() {
      for (int i = 0; i < filteredItems.length; i++) {
        final id = filteredItems[i]['id'];
        final menuItem = _menuItems.firstWhere((item) => item['id'] == id);
        menuItem['sortOrder'] = i + 1;
      }
      _menuItems = _sortMenuItems(_menuItems);
    });

    _updateSortOrders(filteredItems);
  }

  Future<void> _updateSortOrders(List<Map<String, dynamic>> reorderedItems) async {
    if (_selectedStoreId == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < reorderedItems.length; i++) {
        final docRef = FirebaseFirestore.instance
            .collection('stores')
            .doc(_selectedStoreId)
            .collection('menu')
            .doc(reorderedItems[i]['id']);
        batch.update(docRef, {
          'sortOrder': i + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('並び替えの保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMenuItem(String menuId) async {
    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(_selectedStoreId)
          .collection('menu')
          .doc(menuId)
          .delete();

      await _loadMenuItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メニューアイテムを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('メニューを削除'),
          content: Text('「${item['name']}」を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMenuItem(item['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CommonHeader(title: 'メニュー編集'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredItems = _getFilteredItems();

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: const CommonHeader(title: 'メニュー編集'),
      body: Column(
        children: [
          // 上部固定エリア
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 新規メニュー作成ボタン
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: '新規メニューを作成',
                    onPressed: _navigateToCreateMenu,
                  ),
                ),
                const SizedBox(height: 8),
                // オプション管理ボタン
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'オプション管理',
                    onPressed: _selectedStoreId != null
                        ? () => _navigateToOptionGroups()
                        : null,
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFFFF6B35),
                    borderColor: const Color(0xFFFF6B35),
                    icon: const Icon(Icons.tune, size: 18, color: Color(0xFFFF6B35)),
                  ),
                ),
                const SizedBox(height: 16),
                // カテゴリフィルタバー
                PillTabBar(
                  labels: MenuEditView.menuCategories,
                  selectedIndex: _selectedCategoryIndex,
                  onChanged: (index) {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                ),
              ],
            ),
          ),
          // メニューリスト
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'このカテゴリにメニューはありません',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    buildDefaultDragHandles: false,
                    onReorder: _onReorder,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildMenuItemCard(item, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item, int index) {
    return Card(
      key: ValueKey(item['id']),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _navigateToEditItem(item),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ドラッグハンドル
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              // 画像
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item['imageUrl'] != null
                      ? Image.network(
                          item['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.restaurant,
                              color: Colors.grey[400],
                              size: 30,
                            );
                          },
                        )
                      : Icon(
                          Icons.restaurant,
                          color: Colors.grey[400],
                          size: 30,
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // メニュー情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'メニュー名なし',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['category'] ?? 'カテゴリなし',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${(item['price'] ?? 0).toString()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ),

              // 削除ボタン
              IconButton(
                onPressed: () => _showDeleteDialog(item),
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
