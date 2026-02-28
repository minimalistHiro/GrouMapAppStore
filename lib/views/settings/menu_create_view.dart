import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import 'menu_edit_view.dart';
import 'menu_option_group_edit_view.dart';

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

  // オプション関連
  List<Map<String, dynamic>> _selectedOptionGroups = [];
  final Map<String, List<_OptionPriceOverride>> _optionPriceOverrides = {};

  // 画像関連
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Uint8List? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    for (final overrides in _optionPriceOverrides.values) {
      for (final o in overrides) {
        o.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        // ファイルパスから直接変換（HEIC・Live Photoに対応）
        final Uint8List? compressed = await FlutterImageCompress.compressWithFile(
          image.path,
          minWidth: 1024,
          minHeight: 1024,
          quality: 80,
          format: CompressFormat.jpeg,
        );
        if (compressed != null && compressed.isNotEmpty) {
          setState(() {
            _selectedImage = compressed;
          });
        }
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

  Future<void> _showOptionGroupSelector() async {
    // 店舗のオプショングループを取得
    final snapshot = await FirebaseFirestore.instance
        .collection('stores')
        .doc(widget.storeId)
        .collection('menu_option_groups')
        .orderBy('sortOrder')
        .get();

    final allGroups = snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();

    if (!mounted) return;

    final selectedIds =
        _selectedOptionGroups.map((g) => g['id'] as String).toSet();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'オプションを選択',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (allGroups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'オプションが作成されていません\nメニュー管理画面の「オプション管理」から作成してください',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 14),
                        ),
                      ),
                    ),
                  ...allGroups.map((group) {
                    final groupId = group['id'] as String;
                    final isSelected = selectedIds.contains(groupId);
                    final options =
                        (group['options'] as List<dynamic>?) ?? [];
                    final preview = options.map((opt) {
                      final name = opt['name'] ?? '';
                      final mod = (opt['priceModifier'] ?? 0) as num;
                      if (mod > 0) return '$name(+¥${mod.toInt()})';
                      return name;
                    }).join(' / ');

                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(group['name'] ?? ''),
                      subtitle: Text(preview,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                      activeColor: const Color(0xFFFF6B35),
                      onChanged: (value) {
                        setSheetState(() {
                          if (value == true) {
                            selectedIds.add(groupId);
                          } else {
                            selectedIds.remove(groupId);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final result = await Navigator.of(this.context).push(
                        MaterialPageRoute(
                          builder: (context) => MenuOptionGroupEditView(
                            storeId: widget.storeId,
                          ),
                        ),
                      );
                      if (result == true) {
                        _showOptionGroupSelector();
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新規オプションを作成'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: '完了',
                      onPressed: () {
                        final newGroups = allGroups
                            .where((g) =>
                                selectedIds.contains(g['id'] as String))
                            .toList();
                        setState(() {
                          _selectedOptionGroups = newGroups;
                          final existingOverridesData = <String, dynamic>{};
                          for (final entry
                              in _optionPriceOverrides.entries) {
                            existingOverridesData[entry.key] =
                                entry.value
                                    .map((o) => {
                                          'name': o.optionName,
                                          'priceModifier': int.tryParse(
                                                  o.priceController.text
                                                      .trim()) ??
                                              0,
                                        })
                                    .toList();
                          }
                          _initOptionPriceOverrides(
                              newGroups, existingOverridesData);
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _removeOptionGroup(String groupId) {
    setState(() {
      _selectedOptionGroups.removeWhere((g) => g['id'] == groupId);
      final overrides = _optionPriceOverrides.remove(groupId);
      if (overrides != null) {
        for (final o in overrides) {
          o.dispose();
        }
      }
    });
  }

  void _initOptionPriceOverrides(
      List<Map<String, dynamic>> groups,
      Map<String, dynamic> existingOverrides) {
    for (final overrides in _optionPriceOverrides.values) {
      for (final o in overrides) {
        o.dispose();
      }
    }
    _optionPriceOverrides.clear();

    for (final group in groups) {
      final groupId = group['id'] as String;
      final perMenuPricing = group['perMenuPricing'] ?? false;
      if (!perMenuPricing) continue;

      final options = (group['options'] as List<dynamic>?) ?? [];
      final overrideList =
          (existingOverrides[groupId] as List<dynamic>?) ?? [];

      _optionPriceOverrides[groupId] = options.map((opt) {
        final name = (opt['name'] ?? '').toString();
        final defaultPrice = ((opt['priceModifier'] ?? 0) as num).toInt();

        final existingOpt = overrideList.cast<Map<String, dynamic>>().where(
          (o) => o['name'] == name,
        );
        final price = existingOpt.isNotEmpty
            ? ((existingOpt.first['priceModifier'] ?? defaultPrice) as num)
                .toInt()
            : defaultPrice;

        return _OptionPriceOverride(optionName: name, defaultPrice: price);
      }).toList();
    }
  }

  String _buildOptionsPreview(Map<String, dynamic> group) {
    final options = (group['options'] as List<dynamic>?) ?? [];
    return options.map((opt) {
      final name = opt['name'] ?? '';
      final modifier = (opt['priceModifier'] ?? 0) as num;
      if (modifier > 0) return '$name(+¥${modifier.toInt()})';
      return name;
    }).join(' / ');
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

      final optionGroupIds =
          _selectedOptionGroups.map((g) => g['id'] as String).toList();

      // optionPriceOverridesを構築
      final optionPriceOverrides = <String, dynamic>{};
      for (final entry in _optionPriceOverrides.entries) {
        optionPriceOverrides[entry.key] = entry.value
            .map((o) => {
                  'name': o.optionName,
                  'priceModifier':
                      int.tryParse(o.priceController.text.trim()) ?? 0,
                })
            .toList();
      }

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
        'optionGroupIds': optionGroupIds,
        'optionPriceOverrides': optionPriceOverrides,
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

              // オプション選択セクション
              const Text(
                'オプション',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ..._selectedOptionGroups.map((group) {
                final groupId = group['id'] as String;
                final perMenuPricing =
                    group['perMenuPricing'] ?? false;
                final overrides =
                    _optionPriceOverrides[groupId];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      margin: EdgeInsets.only(
                          bottom: perMenuPricing &&
                                  overrides != null &&
                                  overrides.isNotEmpty
                              ? 0
                              : 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: perMenuPricing &&
                                overrides != null &&
                                overrides.isNotEmpty
                            ? const BorderRadius.vertical(
                                top: Radius.circular(8))
                            : BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFFFF6B35),
                                size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          group['name'] ?? '',
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                      ),
                                      if (perMenuPricing) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 6,
                                                  vertical: 1),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.orange[50],
                                            borderRadius:
                                                BorderRadius
                                                    .circular(4),
                                          ),
                                          child: Text(
                                            'メニュー別料金',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors
                                                  .orange[700],
                                              fontWeight:
                                                  FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (!perMenuPricing)
                                    Text(
                                      _buildOptionsPreview(group),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _removeOptionGroup(groupId),
                              icon: const Icon(Icons.close,
                                  size: 18, color: Colors.grey),
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (perMenuPricing &&
                        overrides != null &&
                        overrides.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(
                            12, 8, 12, 12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius:
                              const BorderRadius.vertical(
                                  bottom: Radius.circular(8)),
                          border: Border.all(
                              color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'このメニューでの追加料金',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...overrides.map((override) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(
                                        bottom: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        override.optionName,
                                        style: const TextStyle(
                                            fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 120,
                                      child: TextFormField(
                                        controller: override
                                            .priceController,
                                        decoration:
                                            const InputDecoration(
                                          hintText: '0',
                                          border:
                                              OutlineInputBorder(),
                                          prefixText: '¥',
                                          contentPadding:
                                              EdgeInsets
                                                  .symmetric(
                                                      horizontal:
                                                          10,
                                                      vertical:
                                                          8),
                                          isDense: true,
                                        ),
                                        keyboardType:
                                            TextInputType
                                                .number,
                                        style:
                                            const TextStyle(
                                                fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                );
              }),
              TextButton.icon(
                onPressed: _showOptionGroupSelector,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('オプションを追加'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B35),
                ),
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

/// メニュー別のオプション料金入力を管理するヘルパークラス
class _OptionPriceOverride {
  final String optionName;
  final TextEditingController priceController;

  _OptionPriceOverride({required this.optionName, required int defaultPrice})
      : priceController = TextEditingController(text: defaultPrice.toString());

  void dispose() {
    priceController.dispose();
  }
}
