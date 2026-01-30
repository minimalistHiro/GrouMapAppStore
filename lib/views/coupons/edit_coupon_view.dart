import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class EditCouponView extends StatefulWidget {
  final Map<String, dynamic> couponData;
  
  const EditCouponView({Key? key, required this.couponData}) : super(key: key);

  @override
  State<EditCouponView> createState() => _EditCouponViewState();
}

class _EditCouponViewState extends State<EditCouponView> {
  static final DateTime _noExpirySentinel = DateTime(2100, 12, 31);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _usageLimitController = TextEditingController();

  String _selectedDiscountType = 'percentage';
  String _selectedCouponType = 'discount';
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  int? _selectedRequiredStampCount;
  bool _isNoExpiry = false;
  bool _isActive = true;
  bool _isLoading = false;
  
  // 画像関連
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;
  
  final List<String> _discountTypes = ['percentage', 'fixed_amount', 'fixed_price'];
  final List<String> _couponTypes = ['discount', 'gift', 'special_offer'];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _titleController.text = widget.couponData['title'] ?? '';
    _descriptionController.text = widget.couponData['description'] ?? '';
    _discountValueController.text = (widget.couponData['discountValue'] ?? 0).toString();
    _usageLimitController.text = (widget.couponData['usageLimit'] ?? 0).toString();
    _selectedRequiredStampCount = (widget.couponData['requiredStampCount'] as num?)?.toInt();
    
    _selectedDiscountType = widget.couponData['discountType'] ?? 'percentage';
    _selectedCouponType = widget.couponData['couponType'] ?? 'discount';
    
    // 日時の設定
    if (widget.couponData['validFrom'] != null) {
      _validFrom = widget.couponData['validFrom'].toDate();
    }
    if (widget.couponData['validUntil'] != null) {
      _validUntil = widget.couponData['validUntil'].toDate();
    }
    _isNoExpiry = widget.couponData['noExpiry'] == true || _validUntil.year >= 2100;
    if (_isNoExpiry) {
      _validUntil = _noExpirySentinel;
    }
    _isActive = widget.couponData['isActive'] ?? true;
    
    // 既存の画像URL
    _existingImageUrl = widget.couponData['imageUrl'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  // 画像を選択
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
          _selectedImageBytes = imageBytes;
          _existingImageUrl = null; // 新しい画像を選択したら既存のURLをクリア
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

  // 画像を削除
  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _updateCoupon() async {
    if (_selectedRequiredStampCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('スタンプ達成数を選択してください'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final couponId = widget.couponData['couponId'];
      if (couponId == null) {
        throw Exception('クーポンIDが見つかりません');
      }

      String? imageUrl = _existingImageUrl;

      // 新しい画像が選択されている場合はFirebase Storageに保存
      if (_selectedImageBytes != null) {
        print('画像保存開始');
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final imageFileName = 'coupons/$couponId/image_$timestamp.jpg';
        
        try {
          print('Firebase Storage保存試行: $imageFileName');
          final ref = _storage.ref().child(imageFileName);
          
          // メタデータを設定
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'couponId': couponId,
              'uploadedBy': user.uid,
              'uploadedAt': timestamp.toString(),
            },
          );
          
          final uploadTask = ref.putData(_selectedImageBytes!, metadata);
          final snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
          
          print('Firebase Storage保存完了 - $imageUrl');
        } catch (e) {
          print('Firebase Storage保存エラー: $e');
          // フォールバックとしてBase64で保存
          try {
            final base64String = base64Encode(_selectedImageBytes!);
            imageUrl = 'data:image/jpeg;base64,$base64String';
            print('Base64フォールバック保存完了');
          } catch (base64Error) {
            print('Base64保存エラー: $base64Error');
            imageUrl = 'error:image_failed_to_load';
          }
        }
      }

      // storeIdを取得
      final storeId = widget.couponData['storeId'];
      if (storeId == null) {
        throw Exception('店舗IDが見つかりません');
      }

      final validUntil = _isNoExpiry ? _noExpirySentinel : _validUntil;

      // Firestoreにクーポン情報を更新
      await FirebaseFirestore.instance
          .collection('coupons')
          .doc(storeId)
          .collection('coupons')
          .doc(couponId)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'discountType': _selectedDiscountType,
        'discountValue': double.parse(_discountValueController.text),
        'couponType': _selectedCouponType,
        'usageLimit': int.parse(_usageLimitController.text),
        'requiredStampCount': _selectedRequiredStampCount!,
        'validFrom': Timestamp.fromDate(_validFrom),
        'validUntil': Timestamp.fromDate(validUntil),
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'noExpiry': _isNoExpiry,
        'isActive': _isActive,
      });

      // 公開クーポンも更新
      await FirebaseFirestore.instance
          .collection('public_coupons')
          .doc(couponId)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'discountType': _selectedDiscountType,
        'discountValue': double.parse(_discountValueController.text),
        'couponType': _selectedCouponType,
        'usageLimit': int.parse(_usageLimitController.text),
        'requiredStampCount': _selectedRequiredStampCount!,
        'validFrom': Timestamp.fromDate(_validFrom),
        'validUntil': Timestamp.fromDate(validUntil),
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'noExpiry': _isNoExpiry,
        'isActive': _isActive,
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
                    'クーポン更新完了',
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
            content: Text('クーポン更新に失敗しました: $e'),
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
          'クーポン編集',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
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
                      Icons.edit,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'クーポンを編集',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'クーポン内容を更新しましょう',
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
              
              // クーポンタイプ
              _buildCouponTypeDropdown(),
              
              const SizedBox(height: 20),
              
              // 割引タイプ
              _buildDiscountTypeDropdown(),
              
              const SizedBox(height: 20),
              
              // タイトル
              _buildInputField(
                controller: _titleController,
                label: 'クーポンタイトル *',
                hint: '例：新メニュー割引クーポン',
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
              
              // 説明
              _buildInputField(
                controller: _descriptionController,
                label: 'クーポン説明 *',
                hint: 'クーポンの詳細説明を入力してください',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '説明を入力してください';
                  }
                  if (value.trim().length < 10) {
                    return '説明は10文字以上で入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // 割引値
              _buildInputField(
                controller: _discountValueController,
                label: '割引値 *',
                hint: _selectedDiscountType == 'percentage' ? '例：20' : '例：500',
                icon: Icons.monetization_on,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '割引値を入力してください';
                  }
                  final discountValue = double.tryParse(value);
                  if (discountValue == null) {
                    return '有効な数値を入力してください';
                  }
                  if (_selectedDiscountType == 'percentage' && (discountValue < 1 || discountValue > 100)) {
                    return 'パーセンテージは1-100の範囲で入力してください';
                  }
                  if (discountValue <= 0) {
                    return '0より大きい値を入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // 発券枚数
              _buildInputField(
                controller: _usageLimitController,
                label: '発券枚数 *',
                hint: '例：100',
                icon: Icons.confirmation_number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '発券枚数を入力してください';
                  }
                  final usageLimit = int.tryParse(value);
                  if (usageLimit == null) {
                    return '有効な整数を入力してください';
                  }
                  if (usageLimit <= 0) {
                    return '1以上の値を入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),

              // スタンプ条件
              _buildRequiredStampCountDropdown(),

              const SizedBox(height: 20),
              
              // 有効期限
              _buildValidUntilPicker(),

              const SizedBox(height: 20),

              // 公開状態
              _buildActiveToggle(),
              
              const SizedBox(height: 20),
              
              // 画像選択
              _buildImageSection(),
              
              const SizedBox(height: 32),
              
              // 更新ボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateCoupon,
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
                          'クーポンを更新',
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
                        'クーポンの更新は即座に反映されます。',
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
          keyboardType: keyboardType ??
              (icon == Icons.monetization_on || icon == Icons.confirmation_number
              ? TextInputType.number
              : TextInputType.text),
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

  Widget _buildCouponTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'クーポンタイプ *',
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
              value: _selectedCouponType,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              items: _couponTypes.map((String type) {
                String label;
                switch (type) {
                  case 'discount':
                    label = '割引クーポン';
                    break;
                  case 'gift':
                    label = 'プレゼントクーポン';
                    break;
                  case 'special_offer':
                    label = '特別オファー';
                    break;
                  default:
                    label = type;
                }
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCouponType = newValue;
                  });
                }
              },
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
              items: _discountTypes.map((String type) {
                String label;
                switch (type) {
                  case 'percentage':
                    label = 'パーセンテージ割引 (%)';
                    break;
                  case 'fixed_amount':
                    label = '固定金額割引 (円)';
                    break;
                  case 'fixed_price':
                    label = '固定価格 (円)';
                    break;
                  default:
                    label = type;
                }
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(label),
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

  Widget _buildRequiredStampCountDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'スタンプ達成数（何個目で利用可能）*',
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
            child: DropdownButton<int>(
              value: _selectedRequiredStampCount,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              hint: const Text('選択してください'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              items: List<int>.generate(11, (index) => index)
                  .map((count) => DropdownMenuItem<int>(
                        value: count,
                        child: Text('$count 個'),
                      ))
                  .toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedRequiredStampCount = newValue;
                });
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
        Row(
          children: [
            const Text(
              '有効期限 *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Checkbox(
                  value: _isNoExpiry,
                  onChanged: (value) {
                    setState(() {
                      _isNoExpiry = value ?? false;
                      if (_isNoExpiry) {
                        _validUntil = _noExpirySentinel;
                      } else {
                        _validUntil = DateTime.now().add(const Duration(days: 30));
                      }
                    });
                  },
                ),
                const Text('無期限'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isNoExpiry
              ? null
              : () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _validUntil,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _validUntil = picked;
                      if (_validFrom.isAfter(_validUntil)) {
                        _validFrom = _validUntil;
                      }
                    });
                  }
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isNoExpiry ? Colors.grey[100] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isNoExpiry
                        ? '無期限'
                        : '${_validUntil.year}年${_validUntil.month}月${_validUntil.day}日',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isNoExpiry ? Colors.black87 : Colors.black87,
                    ),
                  ),
                ),
                if (!_isNoExpiry) const Icon(Icons.arrow_drop_down),
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
              // 画像の表示
              if (_existingImageUrl != null || _selectedImageBytes != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _existingImageUrl != null
                        ? Image.network(
                            _existingImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              );
                            },
                          )
                        : Image.memory(
                            _selectedImageBytes!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              
              // 画像操作ボタン
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text(_existingImageUrl != null || _selectedImageBytes != null ? '画像を変更' : '画像を追加'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (_existingImageUrl != null || _selectedImageBytes != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.delete),
                        label: const Text('画像を削除'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '公開状態',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(
                _isActive ? Icons.toggle_on : Icons.toggle_off,
                color: _isActive ? const Color(0xFF2196F3) : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isActive ? 'アクティブ' : '非アクティブ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _isActive ? '公開中のクーポンです' : '非公開のクーポンです',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isActive,
                activeColor: const Color(0xFF2196F3),
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
