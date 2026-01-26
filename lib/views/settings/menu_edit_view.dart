import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import 'menu_item_edit_view.dart';

class MenuEditView extends ConsumerStatefulWidget {
  const MenuEditView({Key? key}) : super(key: key);

  @override
  ConsumerState<MenuEditView> createState() => _MenuEditViewState();
}

class _MenuEditViewState extends ConsumerState<MenuEditView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  
  String? _selectedStoreId;
  bool _isLoading = false;
  bool _isSaving = false;
  String _selectedCategory = '';
  List<String> _customCategories = [];
  List<String> _defaultCategories = ['ドリンク', 'フード', 'ビール', 'デザート', 'サイドメニュー'];
  
  // 画像関連
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Uint8List? _selectedImage;
  String? _currentImageUrl;
  
  // メニューアイテムリスト
  List<Map<String, dynamic>> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 店舗IDを取得
      final userStoreIdAsync = ref.read(userStoreIdProvider);
      final storeId = userStoreIdAsync.when(
        data: (data) => data,
        loading: () => null,
        error: (error, stackTrace) => null,
      );

      if (storeId == null) {
        throw Exception('店舗情報が見つかりません');
      }

      _selectedStoreId = storeId;

      // 店舗のメニューデータを取得
      await _loadMenuItems();
      
      // カスタムカテゴリを取得
      await _loadCustomCategories();
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

  Future<void> _loadCustomCategories() async {
    if (_selectedStoreId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(_selectedStoreId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final categories = List<String>.from(data['customCategories'] ?? []);
        
        if (mounted) {
          setState(() {
            _customCategories = categories;
          });
        }
      }
    } catch (e) {
      print('カスタムカテゴリの読み込みに失敗: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _selectedImage = imageBytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の選択に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _currentImageUrl = null;
    });
  }

  void _addCustomCategory() {
    final category = _categoryController.text.trim();
    if (category.isNotEmpty && !_customCategories.contains(category) && !_defaultCategories.contains(category)) {
      setState(() {
        _customCategories.add(category);
        _categoryController.clear();
      });
      _saveCustomCategories();
    }
  }

  void _removeCustomCategory(String category) {
    setState(() {
      _customCategories.remove(category);
    });
    _saveCustomCategories();
  }

  Future<void> _saveCustomCategories() async {
    if (_selectedStoreId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(_selectedStoreId)
          .update({
        'customCategories': _customCategories,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('カスタムカテゴリの保存に失敗: $e');
    }
  }

  Future<void> _addMenuItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('カテゴリを選択してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 画像をアップロード
      String? imageUrl = _currentImageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      final sortOrder = _resolveNextSortOrder();

      // メニューアイテムを保存
      final menuId = FirebaseFirestore.instance.collection('stores').doc().id;
      
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(_selectedStoreId)
          .collection('menu')
          .doc(menuId)
          .set({
        'id': menuId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'isAvailable': true,
        'sortOrder': sortOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // フォームをリセット
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _selectedImage = null;
      _currentImageUrl = null;
      _selectedCategory = '';

      // メニューリストを更新
      await _loadMenuItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メニューアイテムを追加しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<String> _uploadImage(Uint8List imageBytes) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${_selectedStoreId}_menu_$timestamp.jpg';
    final ref = _storage.ref().child('menu_images/$fileName');
    
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'storeId': _selectedStoreId!,
        'uploadedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'uploadedAt': timestamp.toString(),
      },
    );
    
    final uploadTask = ref.putData(imageBytes, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
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

  int _resolveNextSortOrder() {
    int maxOrder = 0;
    for (final item in _menuItems) {
      final order = _parseSortOrder(item['sortOrder']);
      if (order > maxOrder) {
        maxOrder = order;
      }
    }
    return maxOrder + 1;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('メニュー編集'),
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー編集'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カテゴリ管理セクション
            _buildCategorySection(),
            
            const SizedBox(height: 24),
            
            // メニュー追加セクション
            _buildAddMenuSection(),
            
            const SizedBox(height: 24),
            
            // メニューリストセクション
            _buildMenuListSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'カテゴリ管理',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 16),
          
          // カスタムカテゴリ追加
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    hintText: '新しいカテゴリ名を入力',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onFieldSubmitted: (_) => _addCustomCategory(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addCustomCategory,
                child: const Text('追加'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // カテゴリ一覧
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // デフォルトカテゴリ
              ..._defaultCategories.map((category) => Chip(
                label: Text(category),
                backgroundColor: Colors.blue[100],
                labelStyle: const TextStyle(color: Colors.blue),
              )),
              
              // カスタムカテゴリ
              ..._customCategories.map((category) => Chip(
                label: Text(category),
                onDeleted: () => _removeCustomCategory(category),
                deleteIcon: const Icon(Icons.close, size: 18),
                backgroundColor: Colors.orange[100],
                labelStyle: const TextStyle(color: Colors.orange),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMenuSection() {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'メニューアイテム追加',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 16),
            
            // 画像選択
            _buildImageSection(),
            
            const SizedBox(height: 16),
            
            // カテゴリ選択
            DropdownButtonFormField<String>(
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'カテゴリ *',
                border: OutlineInputBorder(),
              ),
              items: [..._defaultCategories, ..._customCategories].map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'カテゴリを選択してください';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // メニュー名
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'メニュー名 *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'メニュー名を入力してください';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 説明
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // 価格
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: '価格 *',
                border: OutlineInputBorder(),
                prefixText: '¥',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '価格を入力してください';
                }
                if (double.tryParse(value) == null) {
                  return '有効な価格を入力してください';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // 追加ボタン
            CustomButton(
              text: _isSaving ? '追加中...' : 'メニューを追加',
              onPressed: _isSaving ? () {} : _addMenuItem,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'メニュー画像',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: AspectRatio(
            aspectRatio: 1.0, // 1:1の比率
            child: Container(
              width: 200, // 固定幅で半分のサイズに
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          Image.memory(
                            _selectedImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _currentImageUrl != null
                        ? Stack(
                            children: [
                              Image.network(
                                _currentImageUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder();
                                },
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _removeImage,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _buildImagePlaceholder(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              '画像を選択',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuListSection() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'メニュー一覧',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 16),
          
          if (_menuItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'メニューアイテムがありません',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                return _buildMenuItemCard(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    return Card(
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

  Future<void> _navigateToEditItem(Map<String, dynamic> item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MenuItemEditView(
          menuItem: item,
          storeId: _selectedStoreId!,
          defaultCategories: _defaultCategories,
          customCategories: _customCategories,
        ),
      ),
    );

    // 編集画面から戻ってきたらメニューリストを更新
    if (result == true) {
      await _loadMenuItems();
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
}
