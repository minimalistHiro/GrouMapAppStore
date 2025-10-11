import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';

class CreatePostView extends ConsumerStatefulWidget {
  const CreatePostView({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends ConsumerState<CreatePostView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'お知らせ';
  String? _selectedStoreId;
  String _selectedStoreName = '';
  bool _isLoading = false;
  
  // 写真関連
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Uint8List> _selectedImages = [];
  final int _maxImages = 5;
  
  final List<String> _categories = [
    'お知らせ',
    'イベント',
    'キャンペーン',
    'メニュー',
    'その他',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 写真を選択
  Future<void> _pickImages() async {
    try {
      if (_selectedImages.length >= _maxImages) {
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

  // 写真を削除
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 店舗が選択されているかチェック
      if (_selectedStoreId == null || _selectedStoreName.isEmpty) {
        throw Exception('店舗を選択してください');
      }

      // 投稿IDを生成
      final postId = FirebaseFirestore.instance
          .collection('posts')
          .doc(_selectedStoreId)
          .collection('posts')
          .doc()
          .id;

      // 画像をFirebase Storageに保存
      List<String> imageUrls = [];
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
            
            imageUrls.add(downloadUrl);
            print('Firebase Storage保存完了 - $downloadUrl');
          } catch (e) {
            print('Firebase Storage保存エラー: $e');
            // フォールバックとしてBase64で保存
            try {
              final base64String = base64Encode(imageBytes);
              final base64Url = 'data:image/jpeg;base64,$base64String';
              imageUrls.add(base64Url);
              print('Base64フォールバック保存完了');
            } catch (base64Error) {
              print('Base64保存エラー: $base64Error');
              imageUrls.add('error:image_failed_to_load');
            }
          }
        }
      }
      
      // 店舗のアイコン画像URLを取得
      String? storeIconImageUrl;
      try {
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(_selectedStoreId)
            .get();
        
        if (storeDoc.exists) {
          final storeData = storeDoc.data()!;
          storeIconImageUrl = storeData['iconImageUrl'];
        }
      } catch (e) {
        if (kDebugMode) {
          print('店舗アイコン画像URL取得エラー: $e');
        }
      }

      // Firestoreに投稿情報を保存
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(_selectedStoreId)
          .collection('posts')
          .doc(postId)
          .set({
        'postId': postId,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'storeId': _selectedStoreId,
        'storeName': _selectedStoreName,
        'storeIconImageUrl': storeIconImageUrl,
        'category': _selectedCategory,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isPublished': true,
        'views': 0,
        'comments': [],
        'imageUrls': imageUrls,
        'imageCount': imageUrls.length,
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
                    '投稿作成完了',
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
                    '「${_titleController.text.trim()}」が正常に投稿されました！',
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
            content: Text('投稿作成に失敗しました: $e'),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '新規投稿作成',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                      Icons.post_add,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '新しい投稿を作成',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'お客様に情報をお届けしましょう',
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
              
              // 店舗選択
              _buildStoreDropdown(),
              
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
              
              // 作成ボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPost,
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
                          '投稿を作成',
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
                        '投稿は即座に公開されます。虚偽の情報は禁止されています。',
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

  Widget _buildStoreDropdown() {
    return Consumer(
      builder: (context, ref, child) {
        final userStoreIdAsync = ref.watch(userStoreIdProvider);
        
        return userStoreIdAsync.when(
          data: (storeId) {
            if (storeId == null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '作成した店舗がありません',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '先に店舗を作成してください',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final storeDataAsync = ref.watch(storeDataProvider(storeId));
            
            return storeDataAsync.when(
              data: (storeData) {
                if (storeData != null) {
                  _selectedStoreId = storeId;
                  _selectedStoreName = storeData['name'] ?? '店舗名なし';
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '店舗選択 *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
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
                      child: Row(
                        children: [
                          Icon(Icons.store, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedStoreName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  '店舗情報の取得に失敗しました',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              '店舗情報の取得に失敗しました',
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        );
      },
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
              // 選択された画像の表示
              if (_selectedImages.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedImages.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final Uint8List imageBytes = entry.value;
                    
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
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
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // 写真追加ボタン
              if (_selectedImages.length < _maxImages)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
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
                          '${_selectedImages.length}/${_maxImages}枚選択済み',
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
