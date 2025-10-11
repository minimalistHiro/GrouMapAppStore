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

class CreateCouponView extends ConsumerStatefulWidget {
  const CreateCouponView({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateCouponView> createState() => _CreateCouponViewState();
}

class _CreateCouponViewState extends ConsumerState<CreateCouponView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _usageLimitController = TextEditingController();
  
  String _selectedDiscountType = 'percentage';
  String? _selectedStoreId;
  String _selectedStoreName = '';
  DateTime? _selectedValidUntil;
  bool _isLoading = false;
  
  // 写真関連
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Uint8List? _selectedImage;
  
  final List<Map<String, String>> _discountTypes = [
    {'value': 'percentage', 'label': '割合（%）'},
    {'value': 'fixed_amount', 'label': '固定金額（円）'},
    {'value': 'fixed_price', 'label': '固定価格（円）'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  // 写真を選択
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
          content: Text('写真の選択に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 写真を削除
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _createCoupon() async {
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

      // クーポンIDを生成
      final couponId = FirebaseFirestore.instance
          .collection('coupons')
          .doc(_selectedStoreId)
          .collection('coupons')
          .doc()
          .id;

      // 画像をFirebase Storageに保存
      String? imageUrl;
      if (_selectedImage != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final imageFileName = 'coupons/$couponId/image_$timestamp.jpg';
        
        try {
          final ref = _storage.ref().child(imageFileName);
          
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'couponId': couponId,
              'uploadedBy': user.uid,
              'uploadedAt': timestamp.toString(),
            },
          );
          
          final uploadTask = ref.putData(_selectedImage!, metadata);
          final snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          print('Firebase Storage保存エラー: $e');
          // フォールバックとしてBase64で保存
          try {
            final base64String = base64Encode(_selectedImage!);
            imageUrl = 'data:image/jpeg;base64,$base64String';
          } catch (base64Error) {
            print('Base64保存エラー: $base64Error');
            throw Exception('画像の保存に失敗しました');
          }
        }
      }

      // Firestoreにクーポン情報を保存
      await FirebaseFirestore.instance
          .collection('coupons')
          .doc(_selectedStoreId)
          .collection('coupons')
          .doc(couponId)
          .set({
        'couponId': couponId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'storeId': _selectedStoreId,
        'storeName': _selectedStoreName,
        'discountType': _selectedDiscountType,
        'discountValue': double.parse(_discountValueController.text),
        'validUntil': _selectedValidUntil ?? DateTime.now().add(const Duration(days: 30)),
        'usageLimit': int.parse(_usageLimitController.text),
        'usedCount': 0,
        'viewCount': 0,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'imageUrl': imageUrl,
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
                    'クーポン作成完了',
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
                    '「${_titleController.text.trim()}」が正常に作成されました！',
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
            content: Text('クーポン作成に失敗しました: $e'),
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
          '新規クーポン作成',
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
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '新しいクーポンを作成',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'お客様にお得なクーポンを提供しましょう',
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
              
              // 店舗選択
              _buildStoreDropdown(),
              
              const SizedBox(height: 20),
              
              // タイトル
              _buildInputField(
                controller: _titleController,
                label: 'クーポンタイトル *',
                hint: '例：新メニュー20%OFF',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'クーポンタイトルを入力してください';
                  }
                  if (value.trim().length < 3) {
                    return 'タイトルは3文字以上で入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // 説明
              _buildInputField(
                controller: _descriptionController,
                label: 'クーポン説明 *',
                hint: 'クーポンの詳細説明を入力してください',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'クーポン説明を入力してください';
                  }
                  if (value.trim().length < 10) {
                    return '説明は10文字以上で入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // 割引タイプ
              _buildDiscountTypeDropdown(),
              
              const SizedBox(height: 20),
              
              // 割引値
              _buildInputField(
                controller: _discountValueController,
                label: _getDiscountLabel(),
                hint: _getDiscountHint(),
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '割引値を入力してください';
                  }
                  final doubleValue = double.tryParse(value);
                  if (doubleValue == null) {
                    return '有効な数値を入力してください';
                  }
                  if (doubleValue <= 0) {
                    return '0より大きい値を入力してください';
                  }
                  if (_selectedDiscountType == 'percentage' && doubleValue > 100) {
                    return '割合は100%以下で入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // 利用回数制限
              _buildInputField(
                controller: _usageLimitController,
                label: '利用回数制限 *',
                hint: '例：100',
                icon: Icons.confirmation_number,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '利用回数制限を入力してください';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null) {
                    return '有効な整数を入力してください';
                  }
                  if (intValue <= 0) {
                    return '1以上の値を入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // 有効期限
              _buildValidUntilPicker(),
              
              const SizedBox(height: 20),
              
              // 画像選択
              _buildImageSection(),
              
              const SizedBox(height: 32),
              
              // 作成ボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
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
                          'クーポンを作成',
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'クーポンは作成後すぐに利用可能になります。',
                        style: TextStyle(
                          color: Colors.blue[700],
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
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
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
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
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

  Widget _buildDiscountTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '割引タイプ *',
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
              value: _selectedDiscountType,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              items: _discountTypes.map((Map<String, String> type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedDiscountType = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidUntilPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '有効期限 *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedValidUntil ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() {
                _selectedValidUntil = picked;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedValidUntil != null
                        ? '${_selectedValidUntil!.year}年${_selectedValidUntil!.month}月${_selectedValidUntil!.day}日'
                        : '有効期限を選択してください',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedValidUntil != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
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
        const Text(
          'クーポン画像',
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
          child: Column(
            children: [
              // 選択された画像の表示
              if (_selectedImage != null) ...[
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
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
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // 画像追加ボタン
              if (_selectedImage == null)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 120,
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
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'クーポン画像を追加',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '（任意）',
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
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '画像を変更',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDiscountLabel() {
    switch (_selectedDiscountType) {
      case 'percentage':
        return '割引率（%）*';
      case 'fixed_amount':
        return '割引金額（円）*';
      case 'fixed_price':
        return '固定価格（円）*';
      default:
        return '割引値 *';
    }
  }

  String _getDiscountHint() {
    switch (_selectedDiscountType) {
      case 'percentage':
        return '例：20';
      case 'fixed_amount':
        return '例：500';
      case 'fixed_price':
        return '例：1000';
      default:
        return '例：20';
    }
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
}
