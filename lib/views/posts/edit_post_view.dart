import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../widgets/common_header.dart';
import '../../widgets/image_picker_field.dart';

class EditPostView extends StatefulWidget {
  final Map<String, dynamic> postData;
  
  const EditPostView({Key? key, required this.postData}) : super(key: key);

  @override
  State<EditPostView> createState() => _EditPostViewState();
}

class _EditPostViewState extends State<EditPostView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'お知らせ';
  bool _isLoading = false;
  
  // 写真関連
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Uint8List> _selectedImages = [];
  List<String> _existingImageUrls = [];
  final int _maxImages = 5;
  
  final List<String> _categories = [
    'お知らせ',
    'イベント',
    'キャンペーン',
    'メニュー',
    'その他',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _titleController.text = widget.postData['title'] ?? '';
    _contentController.text = widget.postData['content'] ?? '';
    _selectedCategory = widget.postData['category'] ?? 'お知らせ';
    
    // 既存の画像URLを設定
    if (widget.postData['imageUrls'] != null) {
      _existingImageUrls = List<String>.from(widget.postData['imageUrls']);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 写真を選択
  Future<void> _pickImages() async {
    try {
      if (_selectedImages.length + _existingImageUrls.length >= _maxImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('写真は最大${_maxImages}枚まで選択できます'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _selectedImages.add(imageBytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('写真の選択に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 写真を削除（新規選択したもの）
  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // 写真を削除（既存のもの）
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final postId = widget.postData['postId'];
      if (postId == null) {
        throw Exception('投稿IDが見つかりません');
      }

      // 新しい画像をFirebase Storageに保存
      List<String> newImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        print('画像保存開始: ${_selectedImages.length}枚');
        
        for (int i = 0; i < _selectedImages.length; i++) {
          final imageBytes = _selectedImages[i];
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final imageFileName = 'posts/$postId/image_${i}_$timestamp.jpg';
          
          try {
            print('Firebase Storage保存試行: $imageFileName');
            final ref = _storage.ref().child(imageFileName);
            
            // メタデータを設定
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'postId': postId,
                'uploadedBy': user.uid,
                'uploadedAt': timestamp.toString(),
              },
            );
            
            final uploadTask = ref.putData(imageBytes, metadata);
            final snapshot = await uploadTask;
            final downloadUrl = await snapshot.ref.getDownloadURL();
            
            newImageUrls.add(downloadUrl);
            print('Firebase Storage保存完了 - $downloadUrl');
          } catch (e) {
            print('Firebase Storage保存エラー: $e');
            // フォールバックとしてBase64で保存
            try {
              final base64String = base64Encode(imageBytes);
              final base64Url = 'data:image/jpeg;base64,$base64String';
              newImageUrls.add(base64Url);
              print('Base64フォールバック保存完了');
            } catch (base64Error) {
              print('Base64保存エラー: $base64Error');
              newImageUrls.add('error:image_failed_to_load');
            }
          }
        }
      }

      // 全ての画像URLを結合
      final allImageUrls = [..._existingImageUrls, ...newImageUrls];

      // storeIdを取得
      final storeId = widget.postData['storeId'];
      if (storeId == null) {
        throw Exception('店舗IDが見つかりません');
      }

      // Firestoreに投稿情報を更新
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(storeId)
          .collection('posts')
          .doc(postId)
          .update({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrls': allImageUrls,
        'imageCount': allImageUrls.length,
      });

      // 公開投稿も更新
      await FirebaseFirestore.instance
          .collection('public_posts')
          .doc(postId)
          .update({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrls': allImageUrls,
        'imageCount': allImageUrls.length,
      });

      if (mounted) {
        // 成功ダイアログを表示
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '投稿更新完了',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '「${_titleController.text.trim()}」が正常に更新されました！',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // 前の画面に戻る
                  },
                  child: const Text('OK'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('投稿更新に失敗しました: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: const CommonHeader(title: '投稿編集'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '投稿を編集',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '投稿内容を更新しましょう',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // カテゴリ
              _buildCategoryDropdown(),
              
              const SizedBox(height: 20),
              
              // タイトル
              _buildInputField(
                controller: _titleController,
                label: 'タイトル *',
                hint: '例：新メニュー登場！',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  if (value.trim().length < 3) {
                    return 'タイトルは3文字以上で入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // 写真選択
              _buildImageSection(),
              
              const SizedBox(height: 20),
              
              // 内容
              _buildInputField(
                controller: _contentController,
                label: '投稿内容 *',
                hint: '投稿の詳細内容を入力してください',
                icon: Icons.description,
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '投稿内容を入力してください';
                  }
                  if (value.trim().length < 10) {
                    return '投稿内容は10文字以上で入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // 更新ボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '投稿を更新',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 注意事項
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '投稿の更新は即座に反映されます。',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '写真',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                '最大${_maxImages}枚',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              // 既存の画像の表示
              if (_existingImageUrls.isNotEmpty) ...[
                Text(
                  '既存の画像',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _existingImageUrls.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final String imageUrl = entry.value;

                    return SizedBox(
                      width: 80,
                      child: ImagePickerField(
                        aspectRatio: 1.0,
                        onRemove: () => _removeExistingImage(index),
                        showRemove: true,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, color: Colors.grey, size: 40),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // 新しく選択された画像の表示
              if (_selectedImages.isNotEmpty) ...[
                Text(
                  '新しく追加する画像',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedImages.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final Uint8List imageBytes = entry.value;

                    return SizedBox(
                      width: 80,
                      child: ImagePickerField(
                        aspectRatio: 1.0,
                        onRemove: () => _removeNewImage(index),
                        showRemove: true,
                        child: Image.memory(imageBytes, fit: BoxFit.cover),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // 写真追加ボタン
              if (_selectedImages.length + _existingImageUrls.length < _maxImages)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF6F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                      ),
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
                          '写真を追加',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedImages.length + _existingImageUrls.length}/${_maxImages}枚選択済み',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '最大枚数の写真が選択されています',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'カテゴリ *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
