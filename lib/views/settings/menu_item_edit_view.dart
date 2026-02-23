import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import 'menu_edit_view.dart';

class MenuItemEditView extends ConsumerStatefulWidget {
  final Map<String, dynamic> menuItem;
  final String storeId;

  const MenuItemEditView({
    Key? key,
    required this.menuItem,
    required this.storeId,
  }) : super(key: key);

  @override
  ConsumerState<MenuItemEditView> createState() => _MenuItemEditViewState();
}

class _MenuItemEditViewState extends ConsumerState<MenuItemEditView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  bool _isSaving = false;
  String _selectedCategory = '';
  
  // 画像関連
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Uint8List? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _loadMenuItemData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _loadMenuItemData() {
    _nameController.text = widget.menuItem['name'] ?? '';
    _descriptionController.text = widget.menuItem['description'] ?? '';
    _priceController.text = (widget.menuItem['price'] ?? 0).toString();
    _selectedCategory = widget.menuItem['category'] ?? '';
    _currentImageUrl = widget.menuItem['imageUrl'];
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

  Future<void> _updateMenuItem() async {
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

      // メニューアイテムを更新
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('menu')
          .doc(widget.menuItem['id'])
          .update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メニューアイテムを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // 更新完了を通知
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新に失敗しました: $e'),
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
    final fileName = '${widget.storeId}_menu_$timestamp.jpg';
    final ref = _storage.ref().child('menu_images/$fileName');
    
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'storeId': widget.storeId,
        'uploadedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'uploadedAt': timestamp.toString(),
      },
    );
    
    final uploadTask = ref.putData(imageBytes, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: 'メニュー編集'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 画像選択
              _buildImageSection(),
              
              const SizedBox(height: 24),
              
              // カテゴリ選択
              DropdownButtonFormField<String>(
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'カテゴリ *',
                  border: OutlineInputBorder(),
                ),
                items: MenuEditView.menuCategories.map((category) {
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
              
              // 更新ボタン
              CustomButton(
                text: _isSaving ? '更新中...' : 'メニューを更新',
                onPressed: _isSaving ? () {} : _updateMenuItem,
                isLoading: _isSaving,
              ),
            ],
          ),
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
                color: const Color(0xFFFBF6F2),
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
}
