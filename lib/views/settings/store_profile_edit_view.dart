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

class StoreProfileEditView extends ConsumerStatefulWidget {
  const StoreProfileEditView({Key? key}) : super(key: key);

  @override
  ConsumerState<StoreProfileEditView> createState() => _StoreProfileEditViewState();
}

class _StoreProfileEditViewState extends ConsumerState<StoreProfileEditView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedStoreId;
  bool _isLoading = false;
  bool _isSaving = false;
  
  // 画像関連
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Uint8List? _selectedIconImage;
  Uint8List? _selectedStoreImage;
  String? _currentIconImageUrl;
  String? _currentStoreImageUrl;
  
  // 営業時間
  Map<String, Map<String, dynamic>> _businessHours = {
    'monday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
    'tuesday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
    'wednesday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
    'thursday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
    'friday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
    'saturday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
    'sunday': {'open': '09:00', 'close': '18:00', 'isOpen': false},
  };
  
  // ソーシャルメディア
  final _instagramController = TextEditingController();
  final _xController = TextEditingController();
  final _facebookController = TextEditingController();
  final _websiteController = TextEditingController();
  
  // タグ
  final _tagController = TextEditingController();
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
    _xController.dispose();
    _facebookController.dispose();
    _websiteController.dispose();
    _tagController.dispose();
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

      // 店舗データを取得
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      if (storeDoc.exists) {
        final storeData = storeDoc.data()!;
        
        // フォームにデータを設定
        _nameController.text = storeData['name'] ?? '';
        _categoryController.text = storeData['category'] ?? '';
        _addressController.text = storeData['address'] ?? '';
        _phoneController.text = storeData['phone'] ?? '';
        _descriptionController.text = storeData['description'] ?? '';
        
        // 営業時間
        if (storeData['businessHours'] != null) {
          _businessHours = Map<String, Map<String, dynamic>>.from(storeData['businessHours']);
        }
        
        // ソーシャルメディア
        if (storeData['socialMedia'] != null) {
          final socialMedia = Map<String, dynamic>.from(storeData['socialMedia']);
          _instagramController.text = socialMedia['instagram'] ?? '';
          _xController.text = socialMedia['x'] ?? '';
          _facebookController.text = socialMedia['facebook'] ?? '';
          _websiteController.text = socialMedia['website'] ?? '';
        }
        
        // タグ
        if (storeData['tags'] != null) {
          _tags = List<String>.from(storeData['tags']);
        }
        
        // 画像URL
        _currentIconImageUrl = storeData['iconImageUrl'];
        _currentStoreImageUrl = storeData['storeImageUrl'];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗データの読み込みに失敗しました: $e'),
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

  Future<void> _pickIconImage() async {
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
          _selectedIconImage = imageBytes;
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

  Future<void> _pickStoreImage() async {
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
          _selectedStoreImage = imageBytes;
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

  void _removeIconImage() {
    setState(() {
      _selectedIconImage = null;
      _currentIconImageUrl = null;
    });
  }

  void _removeStoreImage() {
    setState(() {
      _selectedStoreImage = null;
      _currentStoreImageUrl = null;
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveStoreData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      if (_selectedStoreId == null) {
        throw Exception('店舗IDが見つかりません');
      }

      // 画像をアップロード
      String? iconImageUrl = _currentIconImageUrl;
      String? storeImageUrl = _currentStoreImageUrl;

      if (_selectedIconImage != null) {
        iconImageUrl = await _uploadImage(_selectedIconImage!, 'store_icons');
      }

      if (_selectedStoreImage != null) {
        storeImageUrl = await _uploadImage(_selectedStoreImage!, 'store_images');
      }

      // 住所から座標を取得（簡易版）
      final location = await _getLocationFromAddress(_addressController.text);

      // Firestoreに保存
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(_selectedStoreId)
          .update({
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'businessHours': _businessHours,
        'socialMedia': {
          'instagram': _instagramController.text.trim(),
          'x': _xController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'website': _websiteController.text.trim(),
        },
        'tags': _tags,
        'location': location,
        'iconImageUrl': iconImageUrl,
        'storeImageUrl': storeImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('店舗情報を更新しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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

  Future<String> _uploadImage(Uint8List imageBytes, String folder) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${_selectedStoreId}_$timestamp.jpg';
    final ref = _storage.ref().child('$folder/$fileName');
    
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

  Future<Map<String, double>> _getLocationFromAddress(String address) async {
    // 簡易版：固定座標を返す（実際の実装ではGeocoding APIを使用）
    return {
      'latitude': 35.6762,
      'longitude': 139.6503,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('店舗プロフィール編集'),
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
        title: const Text('店舗プロフィール編集'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveStoreData,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基本情報セクション
              _buildSection(
                title: '基本情報',
                children: [
                  _buildInputField(
                    controller: _nameController,
                    label: '店舗名 *',
                    hint: '例：カフェ・ド・パリ',
                    icon: Icons.store,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '店舗名を入力してください';
                      }
                      return null;
                    },
                  ),
                  _buildInputField(
                    controller: _categoryController,
                    label: 'カテゴリ *',
                    hint: '例：カフェ、レストラン',
                    icon: Icons.category,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'カテゴリを入力してください';
                      }
                      return null;
                    },
                  ),
                  _buildInputField(
                    controller: _addressController,
                    label: '住所 *',
                    hint: '例：東京都渋谷区...',
                    icon: Icons.location_on,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '住所を入力してください';
                      }
                      return null;
                    },
                  ),
                  _buildInputField(
                    controller: _phoneController,
                    label: '電話番号',
                    hint: '例：03-1234-5678',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildInputField(
                    controller: _descriptionController,
                    label: '店舗説明',
                    hint: '店舗の特徴や魅力を入力してください',
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 画像セクション
              _buildImageSection(),
              
              const SizedBox(height: 24),
              
              // 営業時間セクション
              _buildBusinessHoursSection(),
              
              const SizedBox(height: 24),
              
              // ソーシャルメディアセクション
              _buildSocialMediaSection(),
              
              const SizedBox(height: 24),
              
              // タグセクション
              _buildTagsSection(),
              
              const SizedBox(height: 32),
              
              // 保存ボタン
              CustomButton(
                text: _isSaving ? '保存中...' : '保存',
                onPressed: _isSaving ? () {} : _saveStoreData,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
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
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[50],
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
      ),
    );
  }

  Widget _buildImageSection() {
    return _buildSection(
      title: '店舗画像',
      children: [
        // アイコン画像
        _buildImageField(
          label: '店舗アイコン',
          currentImageUrl: _currentIconImageUrl,
          selectedImage: _selectedIconImage,
          onPick: _pickIconImage,
          onRemove: _removeIconImage,
        ),
        
        const SizedBox(height: 16),
        
        // 店舗画像
        _buildImageField(
          label: '店舗画像',
          currentImageUrl: _currentStoreImageUrl,
          selectedImage: _selectedStoreImage,
          onPick: _pickStoreImage,
          onRemove: _removeStoreImage,
        ),
      ],
    );
  }

  Widget _buildImageField({
    required String label,
    String? currentImageUrl,
    Uint8List? selectedImage,
    required VoidCallback onPick,
    required VoidCallback onRemove,
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
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: selectedImage != null
                ? Stack(
                    children: [
                      Image.memory(
                        selectedImage,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onRemove,
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
                : currentImageUrl != null
                    ? Stack(
                        children: [
                          Image.network(
                            currentImageUrl,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder(onPick);
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: onRemove,
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
                    : _buildImagePlaceholder(onPick),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(VoidCallback onPick) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        height: 120,
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

  Widget _buildBusinessHoursSection() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayNames = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];

    return _buildSection(
      title: '営業時間',
      children: [
        ...days.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final dayName = dayNames[index];
          final dayData = _businessHours[day]!;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    dayName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 16),
                Checkbox(
                  value: dayData['isOpen'],
                  onChanged: (value) {
                    setState(() {
                      _businessHours[day]!['isOpen'] = value ?? false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: dayData['open'],
                          enabled: dayData['isOpen'],
                          decoration: const InputDecoration(
                            labelText: '開始',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onChanged: (value) {
                            _businessHours[day]!['open'] = value;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('〜'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: dayData['close'],
                          enabled: dayData['isOpen'],
                          decoration: const InputDecoration(
                            labelText: '終了',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onChanged: (value) {
                            _businessHours[day]!['close'] = value;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSocialMediaSection() {
    return _buildSection(
      title: 'ソーシャルメディア',
      children: [
        _buildInputField(
          controller: _instagramController,
          label: 'Instagram',
          hint: '@username',
          icon: Icons.camera_alt,
        ),
        _buildInputField(
          controller: _xController,
          label: 'X (Twitter)',
          hint: '@username',
          icon: Icons.alternate_email,
        ),
        _buildInputField(
          controller: _facebookController,
          label: 'Facebook',
          hint: 'facebook.com/username',
          icon: Icons.facebook,
        ),
        _buildInputField(
          controller: _websiteController,
          label: 'ウェブサイト',
          hint: 'https://example.com',
          icon: Icons.language,
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return _buildSection(
      title: 'タグ',
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: 'タグを入力',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addTag,
              child: const Text('追加'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: () => _removeTag(tag),
              deleteIcon: const Icon(Icons.close, size: 18),
            )).toList(),
          ),
      ],
    );
  }
}
