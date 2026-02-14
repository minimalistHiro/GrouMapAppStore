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

class MenuCreateView extends ConsumerStatefulWidget {
  final String storeId;

  const MenuCreateView({Key? key, required this.storeId}) : super(key: key);

  @override
  ConsumerState<MenuCreateView> createState() => _MenuCreateViewState();
}

class _MenuCreateViewState extends ConsumerState<MenuCreateView> {
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
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
    });
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

  Future<int> _resolveNextSortOrder() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('menu')
          .orderBy('sortOrder', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return 1;
      final maxOrder = snapshot.docs.first.data()['sortOrder'];
      if (maxOrder is int) return maxOrder + 1;
      if (maxOrder is num) return maxOrder.toInt() + 1;
      return 1;
    } catch (e) {
      return 1;
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
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      final sortOrder = await _resolveNextSortOrder();
      final menuId = FirebaseFirestore.instance.collection('stores').doc().id;

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メニューアイテムを追加しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: '新規メニュー作成'),
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

              // 追加ボタン
              CustomButton(
                text: _isSaving ? '追加中...' : 'メニューを追加',
                onPressed: _isSaving ? () {} : _addMenuItem,
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
            aspectRatio: 1.0,
            child: Container(
              width: 200,
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
