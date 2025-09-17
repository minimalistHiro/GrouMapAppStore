import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'sign_up_view.dart';

class StoreInfoView extends ConsumerStatefulWidget {
  const StoreInfoView({Key? key}) : super(key: key);

  @override
  ConsumerState<StoreInfoView> createState() => _StoreInfoViewState();
}

class _StoreInfoViewState extends ConsumerState<StoreInfoView> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _xController = TextEditingController();
  final _facebookController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  String _selectedCategory = 'カフェ';
  bool _isLoading = false;

  // 営業時間のコントローラー
  final Map<String, Map<String, TextEditingController>> _businessHoursControllers = {};
  final Map<String, bool> _businessDaysOpen = {};
  
  // タグのコントローラー
  final _tagsController = TextEditingController();
  List<String> _tags = [];
  
  // 位置情報の状態
  double? _selectedLatitude;
  double? _selectedLongitude;
  
  // 店舗アイコン画像の状態
  File? _selectedIconImage;
  Uint8List? _webIconImageBytes;
  String? _iconImageUrl;
  
  // 店舗イメージ画像の状態
  File? _selectedStoreImage;
  Uint8List? _webStoreImageBytes;
  String? _storeImageUrl;

  final List<String> _categories = [
    'カフェ',
    'レストラン',
    '居酒屋',
    'ファストフード',
    'スイーツ',
    'その他',
  ];

  @override
  void initState() {
    super.initState();
    _initializeBusinessHoursControllers();
    _initializeLocationControllers();
  }

  void _initializeBusinessHoursControllers() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (String day in days) {
      _businessHoursControllers[day] = {
        'open': TextEditingController(text: '09:00'),
        'close': TextEditingController(text: '18:00'),
      };
      _businessDaysOpen[day] = true;
    }
    _businessDaysOpen['sunday'] = false; // 日曜日はデフォルトで閉店
  }

  void _initializeLocationControllers() {
    _selectedLatitude = 35.6581; // 東京のデフォルト位置
    _selectedLongitude = 139.7017;
    _updateLocationControllers();
  }
  
  void _updateLocationControllers() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      _latitudeController.text = _selectedLatitude!.toStringAsFixed(6);
      _longitudeController.text = _selectedLongitude!.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _xController.dispose();
    _facebookController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _tagsController.dispose();
    
    for (var controllers in _businessHoursControllers.values) {
      controllers['open']?.dispose();
      controllers['close']?.dispose();
    }
    
    super.dispose();
  }

  Future<void> _getCoordinatesFromAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('住所を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // 簡易的な座標設定（実際のAPIを使う場合はNominatimなど）
    // ここでは東京の座標を設定
    setState(() {
      _selectedLatitude = 35.6581;
      _selectedLongitude = 139.7017;
      _updateLocationControllers();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('座標を設定しました（デフォルト：東京）'),
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {
      _isLoading = false;
    });
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showTimePickerDialog(TextEditingController controller) {
    TimeOfDay currentTime = TimeOfDay.now();
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        if (parts.length == 2) {
          currentTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      } catch (e) {}
    }

    int selectedHour = currentTime.hour;
    int selectedMinute = currentTime.minute;
    selectedMinute = (selectedMinute / 5).round() * 5;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('時間を選択'),
              content: SizedBox(
                height: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ListWheelScrollView(
                        itemExtent: 50,
                        diameterRatio: 1.5,
                        controller: FixedExtentScrollController(initialItem: selectedHour),
                        onSelectedItemChanged: (index) => setDialogState(() => selectedHour = index),
                        children: List.generate(24, (index) => Center(
                          child: Text('${index.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 20, fontWeight: selectedHour == index ? FontWeight.bold : FontWeight.normal, color: selectedHour == index ? const Color(0xFFFF6B35) : Colors.black87)),
                        )),
                      ),
                    ),
                    const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListWheelScrollView(
                        itemExtent: 50,
                        diameterRatio: 1.5,
                        controller: FixedExtentScrollController(initialItem: selectedMinute ~/ 5),
                        onSelectedItemChanged: (index) => setDialogState(() => selectedMinute = index * 5),
                        children: List.generate(12, (index) {
                          final minute = index * 5;
                          return Center(
                            child: Text('${minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 20, fontWeight: selectedMinute == minute ? FontWeight.bold : FontWeight.normal, color: selectedMinute == minute ? const Color(0xFFFF6B35) : Colors.black87)),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
                TextButton(
                  onPressed: () {
                    final timeString = '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                    controller.text = timeString;
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 店舗アイコン画像を選択
  Future<void> _pickIconImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webIconImageBytes = bytes;
            _selectedIconImage = null;
            _iconImageUrl = null; // 新しい画像を選択したらURLをリセット
          });
        } else {
          setState(() {
            _selectedIconImage = File(image.path);
            _webIconImageBytes = null;
            _iconImageUrl = null; // 新しい画像を選択したらURLをリセット
          });
        }
        
        // Firebase Storageにアップロード
        await _uploadIconImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像選択エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 店舗イメージ画像を選択
  Future<void> _pickStoreImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webStoreImageBytes = bytes;
            _selectedStoreImage = null;
            _storeImageUrl = null; // 新しい画像を選択したらURLをリセット
          });
        } else {
          setState(() {
            _selectedStoreImage = File(image.path);
            _webStoreImageBytes = null;
            _storeImageUrl = null; // 新しい画像を選択したらURLをリセット
          });
        }
        
        // Firebase Storageにアップロード
        await _uploadStoreImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗イメージ画像選択エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 店舗アイコン画像をアップロード
  Future<String?> _uploadIconImage() async {
    if (_selectedIconImage == null && _webIconImageBytes == null) return null;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('store_icons')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      String downloadUrl;
      
      if (kIsWeb && _webIconImageBytes != null) {
        final uploadTask = storageRef.putData(_webIconImageBytes!);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else if (_selectedIconImage != null) {
        // モバイル用：FileからUint8Listを取得してアップロード
        final bytes = await _selectedIconImage!.readAsBytes();
        final uploadTask = storageRef.putData(bytes);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else {
        throw Exception('画像が選択されていません');
      }
      
      setState(() {
        _iconImageUrl = downloadUrl;
      });
      
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像アップロードエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
  
  // 店舗イメージ画像をアップロード
  Future<String?> _uploadStoreImage() async {
    if (_selectedStoreImage == null && _webStoreImageBytes == null) return null;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('store_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      String downloadUrl;
      
      if (kIsWeb && _webStoreImageBytes != null) {
        final uploadTask = storageRef.putData(_webStoreImageBytes!);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else if (_selectedStoreImage != null) {
        // モバイル用：FileからUint8Listを取得してアップロード
        final bytes = await _selectedStoreImage!.readAsBytes();
        final uploadTask = storageRef.putData(bytes);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else {
        throw Exception('画像が選択されていません');
      }
      
      setState(() {
        _storeImageUrl = downloadUrl;
      });
      
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗イメージ画像アップロードエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  void _handleNext() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 画像URLを取得（既にアップロード済みの場合はそれを使用）
        String? iconImageUrl = _iconImageUrl;
        if (iconImageUrl == null && (_selectedIconImage != null || _webIconImageBytes != null)) {
          iconImageUrl = await _uploadIconImage();
        }
        
        String? storeImageUrl = _storeImageUrl;
        if (storeImageUrl == null && (_selectedStoreImage != null || _webStoreImageBytes != null)) {
          storeImageUrl = await _uploadStoreImage();
        }

        // 店舗情報を次の画面に渡す
        final storeInfo = {
          'name': _storeNameController.text.trim(),
          'category': _selectedCategory,
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'description': _descriptionController.text.trim(),
          'location': {
            'latitude': _selectedLatitude ?? 0.0,
            'longitude': _selectedLongitude ?? 0.0,
          },
          'businessHours': {
            'monday': {
              'open': _businessHoursControllers['monday']!['open']!.text,
              'close': _businessHoursControllers['monday']!['close']!.text,
              'isOpen': _businessDaysOpen['monday'] ?? false,
            },
            'tuesday': {
              'open': _businessHoursControllers['tuesday']!['open']!.text,
              'close': _businessHoursControllers['tuesday']!['close']!.text,
              'isOpen': _businessDaysOpen['tuesday'] ?? false,
            },
            'wednesday': {
              'open': _businessHoursControllers['wednesday']!['open']!.text,
              'close': _businessHoursControllers['wednesday']!['close']!.text,
              'isOpen': _businessDaysOpen['wednesday'] ?? false,
            },
            'thursday': {
              'open': _businessHoursControllers['thursday']!['open']!.text,
              'close': _businessHoursControllers['thursday']!['close']!.text,
              'isOpen': _businessDaysOpen['thursday'] ?? false,
            },
            'friday': {
              'open': _businessHoursControllers['friday']!['open']!.text,
              'close': _businessHoursControllers['friday']!['close']!.text,
              'isOpen': _businessDaysOpen['friday'] ?? false,
            },
            'saturday': {
              'open': _businessHoursControllers['saturday']!['open']!.text,
              'close': _businessHoursControllers['saturday']!['close']!.text,
              'isOpen': _businessDaysOpen['saturday'] ?? false,
            },
            'sunday': {
              'open': _businessHoursControllers['sunday']!['open']!.text,
              'close': _businessHoursControllers['sunday']!['close']!.text,
              'isOpen': _businessDaysOpen['sunday'] ?? false,
            },
          },
          'tags': _tags,
          'socialMedia': {
            'instagram': _instagramController.text.trim(),
            'x': _xController.text.trim(),
            'facebook': _facebookController.text.trim(),
            'website': _websiteController.text.trim(),
          },
          'iconImageUrl': iconImageUrl,
          'storeImageUrl': storeImageUrl,
        };

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SignUpView(storeInfo: storeInfo),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('画像アップロードに失敗しました: $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // ロゴ
                Center(
                  child: Image.asset(
                    'assets/images/groumap_store_icon.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.store, size: 100, color: Color(0xFFFF6B35)),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // タイトル
                const Text(
                  '店舗情報を入力',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'お店の基本情報を教えてください',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // 店舗名入力
                CustomTextField(
                  controller: _storeNameController,
                  labelText: '店舗名 *',
                  hintText: '例：GrouMap店舗',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '店舗名を入力してください';
                    }
                    if (value.trim().length < 2) {
                      return '店舗名は2文字以上で入力してください';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 店舗アイコン画像
                _buildIconImageSection(),
                
                const SizedBox(height: 16),
                
                // 店舗イメージ画像
                _buildStoreImageSection(),
                
                const SizedBox(height: 16),
                
                // カテゴリ選択
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'カテゴリ *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                          items: _categories.map((String category) => 
                            DropdownMenuItem<String>(
                              value: category, 
                              child: Text(category),
                            ),
                          ).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _selectedCategory = newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 住所入力
                CustomTextField(
                  controller: _addressController,
                  labelText: '住所 *',
                  hintText: '例：埼玉県川口市芝5-5-13',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '住所を入力してください';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 電話番号入力
                CustomTextField(
                  controller: _phoneController,
                  labelText: '電話番号',
                  hintText: '例：03-1234-5678',
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: 16),
                
                // 店舗説明入力
                CustomTextField(
                  controller: _descriptionController,
                  labelText: '店舗説明',
                  hintText: '店舗の特徴や魅力を説明してください',
                  maxLines: 4,
                ),
                
                const SizedBox(height: 20),
                
                // 位置情報
                _buildLocationSection(),
                
                const SizedBox(height: 20),
                
                // 営業時間
                _buildBusinessHoursSection(),
                
                const SizedBox(height: 20),
                
                // タグ
                _buildTagsSection(),
                
                const SizedBox(height: 20),
                
                // SNS・ウェブサイト
                _buildSocialMediaSection(),
                
                const SizedBox(height: 32),
                
                // 次へボタン
                CustomButton(
                  text: _isLoading ? 'アップロード中...' : '次へ',
                  onPressed: _isLoading ? () {} : _handleNext,
                ),
                
                const SizedBox(height: 16),
                
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
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '入力した情報は店舗登録に使用されます。',
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
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '位置情報',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _latitudeController,
                labelText: '緯度',
                hintText: '例：35.6581',
                keyboardType: TextInputType.number,
                enabled: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _longitudeController,
                labelText: '経度',
                hintText: '例：139.7017',
                keyboardType: TextInputType.number,
                enabled: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _getCoordinatesFromAddress,
            icon: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.search, size: 18),
            label: Text(_isLoading ? '座標取得中...' : '住所から座標を取得'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '営業時間',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildBusinessDayRow('月曜日', 'monday'),
              const Divider(),
              _buildBusinessDayRow('火曜日', 'tuesday'),
              const Divider(),
              _buildBusinessDayRow('水曜日', 'wednesday'),
              const Divider(),
              _buildBusinessDayRow('木曜日', 'thursday'),
              const Divider(),
              _buildBusinessDayRow('金曜日', 'friday'),
              const Divider(),
              _buildBusinessDayRow('土曜日', 'saturday'),
              const Divider(),
              _buildBusinessDayRow('日曜日', 'sunday'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessDayRow(String dayName, String dayKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              dayName,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Switch(
            value: _businessDaysOpen[dayKey] ?? true,
            onChanged: (value) => setState(() => _businessDaysOpen[dayKey] = value),
            activeColor: const Color(0xFFFF6B35),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTimePicker(
                    controller: _businessHoursControllers[dayKey]!['open']!,
                    enabled: _businessDaysOpen[dayKey] ?? true,
                    label: '開店時間',
                  ),
                ),
                const SizedBox(width: 8),
                const Text('〜'),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimePicker(
                    controller: _businessHoursControllers[dayKey]!['close']!,
                    enabled: _businessDaysOpen[dayKey] ?? true,
                    label: '閉店時間',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required TextEditingController controller,
    required bool enabled,
    required String label,
  }) {
    return GestureDetector(
      onTap: enabled ? () => _showTimePickerDialog(controller) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: enabled ? Colors.white : Colors.grey[100],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.text.isEmpty ? '時間を選択' : controller.text,
                style: TextStyle(
                  fontSize: 14,
                  color: enabled ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ),
            if (enabled) const Icon(Icons.access_time, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'タグ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  hintText: '例：カフェ、本屋、Wi-Fi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('追加'),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text(tag),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _removeTag(tag),
              backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SNS・ウェブサイト',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _websiteController,
          labelText: 'ウェブサイト',
          hintText: '例：https://example.com',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _instagramController,
                labelText: 'Instagram',
                hintText: '例：https://instagram.com/username',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _xController,
                labelText: 'X (Twitter)',
                hintText: '例：https://x.com/username',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _facebookController,
          labelText: 'Facebook',
          hintText: '例：https://facebook.com/page',
        ),
      ],
    );
  }

  Widget _buildIconImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '店舗アイコン画像',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              if (_selectedIconImage != null || _webIconImageBytes != null)
                Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: _buildIconImage(),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickIconImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('画像を選択'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '推奨サイズ: 512x512px、JPG形式',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStoreImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '店舗イメージ画像',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              if (_selectedStoreImage != null || _webStoreImageBytes != null)
                Container(
                  width: 400,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildStoreImage(),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickStoreImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('店舗イメージ画像を選択'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '推奨サイズ: 1600x800px（2:1比率）、JPG形式',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // アイコン画像を表示（Web対応）
  Widget _buildIconImage() {
    // アップロード済みの画像URLがある場合はそれを優先
    if (_iconImageUrl != null && _iconImageUrl!.isNotEmpty) {
      return Image.network(
        _iconImageUrl!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: 120,
            height: 120,
            color: Colors.grey[300],
            child: const CircularProgressIndicator(
              color: Color(0xFFFF6B35),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildSelectedIconImage();
        },
      );
    } 
    // 選択した画像がある場合はそれを表示
    else if (_selectedIconImage != null || _webIconImageBytes != null) {
      return _buildSelectedIconImage();
    } 
    // どちらもない場合はデフォルトアイコン
    else {
      return Container(
        width: 120,
        height: 120,
        color: Colors.grey[300],
        child: const Icon(
          Icons.store,
          size: 60,
          color: Colors.grey,
        ),
      );
    }
  }

  // 選択したアイコン画像を表示するヘルパーメソッド
  Widget _buildSelectedIconImage() {
    if (_selectedIconImage != null) {
      return FutureBuilder<Uint8List>(
        future: _selectedIconImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            );
          } else if (snapshot.hasError) {
            return Container(
              width: 120,
              height: 120,
              color: Colors.grey[300],
              child: const Icon(
                Icons.store,
                size: 60,
                color: Colors.grey,
              ),
            );
          } else {
            return Container(
              width: 120,
              height: 120,
              color: Colors.grey[300],
              child: const CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            );
          }
        },
      );
    } else if (_webIconImageBytes != null) {
      return Image.memory(
        _webIconImageBytes!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.store, size: 60, color: Colors.grey),
        ),
      );
    } else {
      return Container(
        width: 120,
        height: 120,
        color: Colors.grey[300],
        child: const Icon(
          Icons.store,
          size: 60,
          color: Colors.grey,
        ),
      );
    }
  }

  // 店舗イメージ画像を表示（Web対応）
  Widget _buildStoreImage() {
    // アップロード済みの画像URLがある場合はそれを優先
    if (_storeImageUrl != null && _storeImageUrl!.isNotEmpty) {
      return Image.network(
        _storeImageUrl!,
        width: 400,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: 400,
            height: 200,
            color: Colors.grey[300],
            child: const CircularProgressIndicator(
              color: Color(0xFFFF6B35),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildSelectedStoreImage();
        },
      );
    } 
    // 選択した画像がある場合はそれを表示
    else if (_selectedStoreImage != null || _webStoreImageBytes != null) {
      return _buildSelectedStoreImage();
    } 
    // どちらもない場合はデフォルトアイコン
    else {
      return Container(
        width: 400,
        height: 200,
        color: Colors.grey[300],
        child: const Icon(
          Icons.store,
          size: 60,
          color: Colors.grey,
        ),
      );
    }
  }

  // 選択した店舗イメージ画像を表示するヘルパーメソッド
  Widget _buildSelectedStoreImage() {
    if (_selectedStoreImage != null) {
      return FutureBuilder<Uint8List>(
        future: _selectedStoreImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: 400,
              height: 200,
              fit: BoxFit.cover,
            );
          } else if (snapshot.hasError) {
            return Container(
              width: 400,
              height: 200,
              color: Colors.grey[300],
              child: const Icon(
                Icons.store,
                size: 60,
                color: Colors.grey,
              ),
            );
          } else {
            return Container(
              width: 400,
              height: 200,
              color: Colors.grey[300],
              child: const CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            );
          }
        },
      );
    } else if (_webStoreImageBytes != null) {
      return Image.memory(
        _webStoreImageBytes!,
        width: 400,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.store, size: 60, color: Colors.grey),
        ),
      );
    } else {
      return Container(
        width: 400,
        height: 200,
        color: Colors.grey[300],
        child: const Icon(
          Icons.store,
          size: 60,
          color: Colors.grey,
        ),
      );
    }
  }
}