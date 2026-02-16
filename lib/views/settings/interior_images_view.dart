import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';

class InteriorImagesView extends ConsumerStatefulWidget {
  final String? storeId;
  const InteriorImagesView({Key? key, this.storeId}) : super(key: key);

  @override
  ConsumerState<InteriorImagesView> createState() => _InteriorImagesViewState();
}

class _InteriorImagesViewState extends ConsumerState<InteriorImagesView> {
  static const int _maxImages = 5;
  static const int _maxCaptionLength = 20;

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? _storeId;
  bool _isLoading = false;
  bool _isSaving = false;

  List<_InteriorImageEntry> _entries = [];
  final Set<String> _initialEntryIds = {};

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.captionController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('ログイン情報が見つかりません。再ログインしてください。');
        return;
      }

      final storeId = widget.storeId ?? ref.read(userStoreIdProvider).when(
        data: (data) => data,
        loading: () => null,
        error: (error, stackTrace) => null,
      );

      if (storeId == null) {
        _showError('店舗情報が見つかりません。');
        return;
      }

      _storeId = storeId;
      await _loadInteriorImages();
    } catch (e) {
      _showError('データの読み込みに失敗しました。', details: e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInteriorImages() async {
    if (_storeId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(_storeId)
          .collection('interior_images')
          .get();

      final images = snapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList();

      final sorted = _sortImages(images);

      if (mounted) {
        setState(() {
          _entries = sorted
              .map((image) => _InteriorImageEntry(
                    id: image['id'] as String?,
                    imageUrl: image['imageUrl'] as String?,
                    caption: (image['caption'] ?? '').toString(),
                  ))
              .toList();
          _initialEntryIds
            ..clear()
            ..addAll(_entries.where((entry) => entry.id != null).map((entry) => entry.id!));
        });
      }
    } catch (e) {
      _showError('店内画像の読み込みに失敗しました。', details: e.toString());
    }
  }

  Future<void> _pickImageFor(_InteriorImageEntry entry) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          entry.imageBytes = imageBytes;
        });
      }
    } catch (e) {
      _showError('画像の選択に失敗しました。', details: e.toString());
    }
  }

  void _addEntry() {
    if (_entries.length >= _maxImages) {
      _showError('店内画像は最大$_maxImages枚まで登録できます。');
      return;
    }
    setState(() {
      _entries.add(_InteriorImageEntry());
    });
  }

  void _removeEntry(int index) {
    final entry = _entries[index];
    setState(() {
      _entries.removeAt(index);
      entry.captionController.dispose();
    });
  }

  void _reorderEntries(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final entry = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, entry);
    });
  }

  Future<void> _confirmRemoveEntry(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この画像を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _removeEntry(index);
    }
  }

  Future<void> _saveAll() async {
    if (_storeId == null) return;

    if (_entries.isEmpty) {
      _showError('店内画像を追加してください。');
      return;
    }

    for (final entry in _entries) {
      final caption = entry.captionController.text.trim();
      if (caption.length > _maxCaptionLength) {
        _showError('説明は$_maxCaptionLength文字以内で入力してください。');
        return;
      }
    }
    if (_entries.length > _maxImages) {
      _showError('店内画像は最大$_maxImages枚まで登録できます。');
      return;
    }
    final invalidEntries = _entries.where((entry) => entry.imageBytes == null && entry.imageUrl == null).toList();
    if (invalidEntries.isNotEmpty) {
      _showError('画像が未選択の項目があります。画像を選択してください。');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final currentIds = _entries.where((entry) => entry.id != null).map((entry) => entry.id!).toSet();
      final removedIds = _initialEntryIds.difference(currentIds);
      for (final removedId in removedIds) {
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(_storeId)
            .collection('interior_images')
            .doc(removedId)
            .delete();
      }

      for (int index = 0; index < _entries.length; index++) {
        final entry = _entries[index];
        final caption = entry.captionController.text.trim();
        String? imageUrl = entry.imageUrl;

        if (entry.imageBytes != null) {
          imageUrl = await _uploadImage(entry.imageBytes!);
        }

        if (imageUrl == null) {
          continue;
        }

        if (entry.id == null) {
          final imageId = FirebaseFirestore.instance.collection('stores').doc().id;
          entry.id = imageId;
          await FirebaseFirestore.instance
              .collection('stores')
              .doc(_storeId)
              .collection('interior_images')
              .doc(imageId)
              .set({
            'imageUrl': imageUrl,
            'caption': caption,
            'sortOrder': index + 1,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });
        } else {
          await FirebaseFirestore.instance
              .collection('stores')
              .doc(_storeId)
              .collection('interior_images')
              .doc(entry.id)
              .update({
            'imageUrl': imageUrl,
            'caption': caption,
            'sortOrder': index + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('保存に失敗しました。', details: e.toString());
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
    final fileName = '${_storeId}_interior_$timestamp.jpg';
    final ref = _storage.ref().child('interior_images/$fileName');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'storeId': _storeId ?? '',
        'uploadedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'uploadedAt': timestamp.toString(),
      },
    );

    final uploadTask = ref.putData(imageBytes, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
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

  List<Map<String, dynamic>> _sortImages(List<Map<String, dynamic>> items) {
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

  void _showError(String message, {String? details}) {
    if (!mounted) return;
    ErrorDialog.show(
      context,
      title: 'エラー',
      message: message,
      details: details,
      onDismiss: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CommonHeader(title: '店内画像設定'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CommonHeader(title: '店内画像設定'),
      body: _buildListSection(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: CustomButton(
            text: '保存する',
            onPressed: _isSaving ? null : _saveAll,
            isLoading: _isSaving,
          ),
        ),
      ),
    );
  }

  Widget _buildListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '店内画像',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_entries.length} / $_maxImages',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: _entries.isEmpty
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  children: [
                    Container(
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
                      child: const Text(
                        '店内画像を追加してください。',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAddTile(),
                  ],
                )
              : ReorderableListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  buildDefaultDragHandles: false,
                  onReorder: _reorderEntries,
                  children: [
                    ..._entries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        key: ValueKey(item.localId),
                        margin: const EdgeInsets.only(bottom: 16),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '画像 ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.drag_handle, color: Colors.grey),
                                    ),
                                    IconButton(
                                      onPressed: () => _confirmRemoveEntry(index),
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _pickImageFor(item),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                    color: Colors.grey[100],
                                    image: item.imageBytes != null
                                        ? DecorationImage(
                                            image: MemoryImage(item.imageBytes!),
                                            fit: BoxFit.cover,
                                          )
                                        : (item.imageUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(item.imageUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null),
                                  ),
                                  child: item.imageBytes == null && item.imageUrl == null
                                      ? const Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add_photo_alternate, color: Colors.grey),
                                              SizedBox(height: 6),
                                              Text(
                                                'タップして画像を選択',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: item.captionController,
                              maxLength: _maxCaptionLength,
                              decoration: const InputDecoration(
                                labelText: '説明（20文字以内）',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    _buildAddTile(key: const ValueKey('add_tile')),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAddTile({Key? key}) {
    final isLimit = _entries.length >= _maxImages;
    return Container(
      key: key,
      child: GestureDetector(
        onTap: isLimit ? null : _addEntry,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: isLimit ? Colors.grey : const Color(0xFFFF6B35),
              ),
              const SizedBox(width: 8),
              Text(
                isLimit ? 'これ以上追加できません' : '画像を追加',
                style: TextStyle(
                  color: isLimit ? Colors.grey : const Color(0xFFFF6B35),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteriorImageEntry {
  _InteriorImageEntry({this.id, this.imageUrl, String? caption})
      : captionController = TextEditingController(text: caption ?? '');

  final String localId = UniqueKey().toString();
  String? id;
  String? imageUrl;
  Uint8List? imageBytes;
  final TextEditingController captionController;
}
