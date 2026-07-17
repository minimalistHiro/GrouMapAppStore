import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/icon_image_picker_field.dart';
import '../../widgets/image_picker_field.dart';
import '../../utils/icon_image_flow.dart';
import '../../widgets/custom_switch_tile.dart';
import '../../theme/store_ui.dart';
import '../../providers/admin_store_provider.dart';
import '../auth/store_location_picker_view.dart';
import 'store_icon_crop_view.dart';

class AdminStoreCreateView extends ConsumerStatefulWidget {
  const AdminStoreCreateView({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminStoreCreateView> createState() => _AdminStoreCreateViewState();
}

class _AdminStoreCreateViewState extends ConsumerState<AdminStoreCreateView> {
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
  String? _selectedCategory;
  String? _selectedSubCategory;
  bool _isLoading = false;
  bool _hasFormError = false;
  bool _isRegularHoliday = false;
  String? _selectedPrefecture;
  String? _selectedCity;
  List<String> _cities = [];
  bool _isLoadingCities = false;

  final Map<String, List<Map<String, TextEditingController>>> _businessHoursControllers = {};
  final Map<String, bool> _businessDaysOpen = {};

  final _tagsController = TextEditingController();
  List<String> _tags = [];

  double? _selectedLatitude;
  double? _selectedLongitude;

  File? _selectedIconImage;
  Uint8List? _webIconImageBytes;
  String? _iconImageUrl;

  File? _selectedStoreImage;
  Uint8List? _webStoreImageBytes;
  String? _storeImageUrl;

  final _businessNameController = TextEditingController();
  String _businessType = 'individual';

  final _counterSeatsController = TextEditingController();
  final _tableSeatsController = TextEditingController();
  final _tatamiSeatsController = TextEditingController();
  final _terraceSeatsController = TextEditingController();
  final _privateRoomSeatsController = TextEditingController();
  final _sofaSeatsController = TextEditingController();
  String _parkingOption = 'none';
  final _accessInfoController = TextEditingController();
  bool _hasTakeout = false;
  String _smokingPolicy = 'no_smoking';
  bool _hasWifi = false;
  bool _isBarrierFree = false;
  bool _isChildFriendly = false;
  bool _isPetFriendly = false;

  final List<String> _categories = [
    'カフェ・喫茶店', 'レストラン', '居酒屋', '和食', '日本料理', '海鮮', '寿司', 'そば', 'うどん',
    'うなぎ', '焼き鳥', 'とんかつ', '串揚げ', '天ぷら', 'お好み焼き', 'もんじゃ焼き', 'しゃぶしゃぶ',
    '鍋', '焼肉', 'ホルモン', 'ラーメン', '中華料理', '餃子', '韓国料理', 'タイ料理', 'カレー',
    '洋食', 'フレンチ', 'スペイン料理', 'ビストロ', 'パスタ', 'ピザ', 'ステーキ', 'ハンバーグ',
    'ハンバーガー', 'ビュッフェ', '食堂', 'パン・サンドイッチ', 'スイーツ', 'ケーキ', 'タピオカ',
    'バー・お酒', 'スナック', '料理旅館', '沖縄料理', 'その他',
  ];

  List<String> get _subCategories {
    if (_selectedCategory == null) return _categories;
    return _categories.where((c) => c != _selectedCategory).toList();
  }

  final List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
    '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
    '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
    '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県',
  ];

  @override
  void initState() {
    super.initState();
    _initializeBusinessHoursControllers();
    _selectedLatitude = null;
    _selectedLongitude = null;
  }

  void _initializeBusinessHoursControllers() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (String day in days) {
      _businessHoursControllers[day] = [
        {'open': TextEditingController(text: '09:00'), 'close': TextEditingController(text: '18:00')},
      ];
      _businessDaysOpen[day] = true;
    }
    _businessDaysOpen['sunday'] = false;
  }

  void _addBusinessPeriod(String dayKey) {
    setState(() {
      _businessHoursControllers[dayKey]!.add({
        'open': TextEditingController(text: ''),
        'close': TextEditingController(text: ''),
      });
    });
  }

  void _removeBusinessPeriod(String dayKey, int index) {
    setState(() {
      final period = _businessHoursControllers[dayKey]!.removeAt(index);
      period['open']?.dispose();
      period['close']?.dispose();
    });
  }

  Map<String, Map<String, dynamic>> _buildBusinessHoursForSave() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final result = <String, Map<String, dynamic>>{};
    for (final day in days) {
      final periodList = _businessHoursControllers[day] ?? [];
      final periods = periodList.map((p) => {
        'open': p['open']?.text ?? '09:00',
        'close': p['close']?.text ?? '18:00',
      }).toList();
      result[day] = {
        'open': periods.isNotEmpty ? periods.first['open'] : '09:00',
        'close': periods.isNotEmpty ? periods.first['close'] : '18:00',
        'isOpen': _businessDaysOpen[day] ?? false,
        'periods': periods,
      };
    }
    return result;
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
    _counterSeatsController.dispose();
    _tableSeatsController.dispose();
    _tatamiSeatsController.dispose();
    _terraceSeatsController.dispose();
    _privateRoomSeatsController.dispose();
    _sofaSeatsController.dispose();
    _accessInfoController.dispose();
    _businessNameController.dispose();
    for (var periodList in _businessHoursControllers.values) {
      for (var controllers in periodList) {
        controllers['open']?.dispose();
        controllers['close']?.dispose();
      }
    }
    super.dispose();
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

  Future<void> _openLocationPicker() async {
    final selectedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (context) => const StoreLocationPickerView()),
    );
    if (selectedLocation == null) return;
    setState(() {
      _selectedLatitude = selectedLocation.latitude;
      _selectedLongitude = selectedLocation.longitude;
      _latitudeController.text = _selectedLatitude!.toStringAsFixed(6);
      _longitudeController.text = _selectedLongitude!.toStringAsFixed(6);
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
    int selectedMinute = (currentTime.minute / 5).round() * 5;

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
                          child: Text('${index.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 20, fontWeight: selectedHour == index ? FontWeight.bold : FontWeight.normal, color: selectedHour == index ? const Color(0xFFFF6B35) : Colors.black87)),
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
                            child: Text('${minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 20, fontWeight: selectedMinute == minute ? FontWeight.bold : FontWeight.normal, color: selectedMinute == minute ? const Color(0xFFFF6B35) : Colors.black87)),
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
                    controller.text = '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
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

  Future<void> _pickIconImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final Uint8List? cropped = await pickAndCropIconImage(
        context: context,
        picker: picker,
        buildCropView: (bytes) => StoreIconCropView(imageBytes: bytes),
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (!mounted) return;
      if (cropped != null) {
        setState(() {
          _webIconImageBytes = cropped;
          _selectedIconImage = null;
          _iconImageUrl = null;
        });
        await _uploadIconImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('画像選択エラー: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _removeIconImage() {
    setState(() {
      _webIconImageBytes = null;
      _selectedIconImage = null;
      _iconImageUrl = null;
    });
  }

  void _removeStoreImage() {
    setState(() {
      _webStoreImageBytes = null;
      _selectedStoreImage = null;
      _storeImageUrl = null;
    });
  }

  Future<void> _pickStoreImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 800, imageQuality: 80);
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webStoreImageBytes = bytes;
            _selectedStoreImage = null;
            _storeImageUrl = null;
          });
        } else {
          setState(() {
            _selectedStoreImage = File(image.path);
            _webStoreImageBytes = null;
            _storeImageUrl = null;
          });
        }
        await _uploadStoreImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('店舗イメージ画像選択エラー: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<String?> _uploadIconImage() async {
    if (_selectedIconImage == null && _webIconImageBytes == null) return null;
    try {
      final storageRef = FirebaseStorage.instance.ref().child('store_icons').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      String downloadUrl;
      if (_webIconImageBytes != null) {
        final snap = await storageRef.putData(_webIconImageBytes!);
        downloadUrl = await snap.ref.getDownloadURL();
      } else {
        final bytes = await _selectedIconImage!.readAsBytes();
        final snap = await storageRef.putData(bytes);
        downloadUrl = await snap.ref.getDownloadURL();
      }
      setState(() => _iconImageUrl = downloadUrl);
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('画像アップロードエラー: $e'), backgroundColor: Colors.red));
      }
      return null;
    }
  }

  Future<String?> _uploadStoreImage() async {
    if (_selectedStoreImage == null && _webStoreImageBytes == null) return null;
    try {
      final storageRef = FirebaseStorage.instance.ref().child('store_images').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      String downloadUrl;
      if (kIsWeb && _webStoreImageBytes != null) {
        final snap = await storageRef.putData(_webStoreImageBytes!);
        downloadUrl = await snap.ref.getDownloadURL();
      } else {
        final bytes = await _selectedStoreImage!.readAsBytes();
        final snap = await storageRef.putData(bytes);
        downloadUrl = await snap.ref.getDownloadURL();
      }
      setState(() => _storeImageUrl = downloadUrl);
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('店舗イメージ画像アップロードエラー: $e'), backgroundColor: Colors.red));
      }
      return null;
    }
  }

  /// 店舗を作成してリンクコードを表示するダイアログを出す
  void _handleCreate() async {
    final isValid = _formKey.currentState!.validate();
    setState(() => _hasFormError = !isValid);
    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
      String? iconImageUrl = _iconImageUrl;
      if (iconImageUrl == null && (_selectedIconImage != null || _webIconImageBytes != null)) {
        iconImageUrl = await _uploadIconImage();
      }

      String? storeImageUrl = _storeImageUrl;
      if (storeImageUrl == null && (_selectedStoreImage != null || _webStoreImageBytes != null)) {
        storeImageUrl = await _uploadStoreImage();
      }

      final addressDetail = _addressController.text.trim();
      final combinedAddress = '${_selectedPrefecture ?? ''}${_selectedCity ?? ''}$addressDetail';

      final service = ref.read(adminStoreServiceProvider);
      final linkCode = await service.createStore(
        name: _storeNameController.text.trim(),
        category: _selectedCategory!,
        subCategory: _selectedSubCategory,
        address: combinedAddress,
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
        description: _descriptionController.text.trim(),
        phone: _phoneController.text.trim(),
        businessType: _businessType,
        businessName: _businessNameController.text.trim(),
        businessHours: _buildBusinessHoursForSave(),
        isRegularHoliday: _isRegularHoliday,
        socialMedia: {
          'instagram': _instagramController.text.trim(),
          'x': _xController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'website': _websiteController.text.trim(),
        },
        iconImageUrl: iconImageUrl,
        storeImageUrl: storeImageUrl,
        facilityInfo: {
          'seatingCapacity': {
            'counter': int.tryParse(_counterSeatsController.text.trim()) ?? 0,
            'table': int.tryParse(_tableSeatsController.text.trim()) ?? 0,
            'tatami': int.tryParse(_tatamiSeatsController.text.trim()) ?? 0,
            'terrace': int.tryParse(_terraceSeatsController.text.trim()) ?? 0,
            'privateRoom': int.tryParse(_privateRoomSeatsController.text.trim()) ?? 0,
            'sofa': int.tryParse(_sofaSeatsController.text.trim()) ?? 0,
          },
          'parking': _parkingOption,
          'accessInfo': _accessInfoController.text.trim(),
          'takeout': _hasTakeout,
          'smokingPolicy': _smokingPolicy,
          'hasWifi': _hasWifi,
          'barrierFree': _isBarrierFree,
          'childFriendly': _isChildFriendly,
          'petFriendly': _isPetFriendly,
        },
        tags: _tags,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        await _showLinkCodeDialog(linkCode);
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('店舗作成に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showLinkCodeDialog(String linkCode) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('店舗を作成しました'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '下のリンクコードを店舗オーナーにお伝えください。\nアプリのアカウント作成時に使用します。',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B35), width: 2),
              ),
              child: Text(
                linkCode,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: linkCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('リンクコードをコピーしました'), duration: Duration(seconds: 2)),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('コピー'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B35)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる', style: TextStyle(color: Color(0xFFFF6B35))),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCitiesForPrefecture(String prefecture) async {
    setState(() => _isLoadingCities = true);
    _loadFallbackCities(prefecture);
  }

  void _loadFallbackCities(String prefecture) {
    List<String> cities;
    switch (prefecture) {
      case '東京都':
        cities = ['千代田区', '中央区', '港区', '新宿区', '文京区', '台東区', '墨田区', '江東区', '品川区', '目黒区', '大田区', '世田谷区', '渋谷区', '中野区', '杉並区', '豊島区', '北区', '荒川区', '板橋区', '練馬区', '足立区', '葛飾区', '江戸川区', '八王子市', '立川市', '武蔵野市', '三鷹市', '青梅市', '府中市', '昭島市', '調布市', '町田市', '小金井市', '小平市', '日野市', '東村山市', '国分寺市', '国立市', '福生市', '狛江市', '東大和市', '清瀬市', '東久留米市', '武蔵村山市', '多摩市', '稲城市', '羽村市', 'あきる野市', '西東京市'];
        break;
      case '大阪府':
        cities = ['大阪市', '堺市', '岸和田市', '豊中市', '池田市', '吹田市', '泉大津市', '高槻市', '貝塚市', '守口市', '枚方市', '茨木市', '八尾市', '泉佐野市', '富田林市', '寝屋川市', '河内長野市', '松原市', '大東市', '和泉市', '箕面市', '柏原市', '羽曳野市', '門真市', '摂津市', '高石市', '藤井寺市', '東大阪市', '泉南市', '四條畷市', '交野市', '大阪狭山市', '阪南市'];
        break;
      case '神奈川県':
        cities = ['横浜市', '川崎市', '相模原市', '横須賀市', '平塚市', '鎌倉市', '藤沢市', '小田原市', '茅ヶ崎市', '逗子市', '三浦市', '秦野市', '厚木市', '大和市', '伊勢原市', '海老名市', '座間市', '南足柄市', '綾瀬市'];
        break;
      case '愛知県':
        cities = ['名古屋市', '豊橋市', '岡崎市', '一宮市', '瀬戸市', '半田市', '春日井市', '豊川市', '津島市', '碧南市', '刈谷市', '豊田市', '安城市', '西尾市', '蒲郡市', '犬山市', '常滑市', '江南市', '小牧市', '稲沢市', '新城市', '東海市', '大府市', '知多市', '知立市', '尾張旭市', '高浜市', '岩倉市', '豊明市', '日進市', '田原市', '愛西市', '清須市', '北名古屋市', '弥富市', 'みよし市', 'あま市', '長久手市'];
        break;
      case '埼玉県':
        cities = ['さいたま市', '川越市', '熊谷市', '川口市', '行田市', '秩父市', '所沢市', '飯能市', '加須市', '本庄市', '東松山市', '春日部市', '狭山市', '羽生市', '鴻巣市', '深谷市', '上尾市', '草加市', '越谷市', '蕨市', '戸田市', '入間市', '朝霞市', '志木市', '和光市', '新座市', '桶川市', '久喜市', '北本市', '八潮市', '富士見市', '三郷市', '蓮田市', '坂戸市', '幸手市', '鶴ヶ島市', '日高市', '吉川市', 'ふじみ野市', '白岡市'];
        break;
      default:
        cities = ['市区町村を入力してください'];
    }
    setState(() {
      _cities = cities;
      _isLoadingCities = false;
    });
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('新規店舗を作成', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // 店舗名
                CustomTextField(
                  controller: _storeNameController,
                  labelText: '店舗名 *',
                  hintText: '例：ぐるまっぷ店舗',
                  validator: (value) {
                    if (value == null || value.isEmpty) return '店舗名を入力してください';
                    if (value.length > 50) return '店舗名は50文字以内で入力してください';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // 経営形態
                _buildBusinessTypeSection(),

                const SizedBox(height: 16),

                // 法人名/代表者名
                CustomTextField(
                  controller: _businessNameController,
                  labelText: _businessType == 'corporate' ? '法人名 *' : '代表者名 *',
                  hintText: _businessType == 'corporate' ? '例：株式会社ぐるまっぷ' : '例：山田 太郎',
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _businessType == 'corporate' ? '法人名を入力してください' : '代表者名を入力してください';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // アイコン画像
                _buildIconImageSection(),
                const SizedBox(height: 16),

                // 店舗イメージ画像
                _buildStoreImageSection(),
                const SizedBox(height: 16),

                // カテゴリ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('カテゴリ *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                      hint: const Text('選択してください'),
                      isExpanded: true,
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() {
                        _selectedCategory = v;
                        if (_selectedSubCategory == _selectedCategory) _selectedSubCategory = null;
                      }),
                      validator: (v) => (v == null || v.isEmpty) ? 'カテゴリを選択してください' : null,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedSubCategory,
                  decoration: const InputDecoration(labelText: 'サブカテゴリ（任意）', filled: true, fillColor: Colors.white, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                  hint: const Text('選択してください'),
                  isExpanded: true,
                  items: _subCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedSubCategory = v),
                ),

                const SizedBox(height: 16),

                // 住所
                const Text('住所', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPrefecture,
                  decoration: const InputDecoration(labelText: '都道府県 *', filled: true, fillColor: Colors.white, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                  items: _prefectures.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedPrefecture = v;
                      _selectedCity = null;
                      _cities = [];
                    });
                    if (v != null) _loadCitiesForPrefecture(v);
                  },
                  validator: (v) => (v == null || v.isEmpty) ? '都道府県を選択してください' : null,
                ),

                const SizedBox(height: 16),

                if (_selectedPrefecture != null)
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: InputDecoration(
                      labelText: '市区町村 *',
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      suffixIcon: _isLoadingCities ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                    ),
                    items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: _isLoadingCities ? null : (v) => setState(() => _selectedCity = v),
                    validator: (v) => (v == null || v.isEmpty) ? '市区町村を選択してください' : null,
                  ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _addressController,
                  labelText: '以下の住所 *',
                  hintText: '例：芝5-5-13',
                  validator: (v) => (v == null || v.isEmpty) ? '以下の住所を入力してください' : null,
                ),

                const SizedBox(height: 32),

                // 電話番号
                CustomTextField(
                  controller: _phoneController,
                  labelText: '電話番号（任意）',
                  hintText: '例：0312345678',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),

                const SizedBox(height: 16),

                // 店舗説明
                CustomTextField(
                  controller: _descriptionController,
                  labelText: '店舗説明（任意）',
                  hintText: '店舗の特徴や魅力を説明してください',
                  maxLines: 4,
                  maxLength: 150,
                ),

                const SizedBox(height: 20),

                // 位置情報
                _buildLocationSection(),
                FormField<void>(
                  validator: (_) => (_selectedLatitude == null || _selectedLongitude == null) ? '位置情報を選択してください' : null,
                  builder: (state) {
                    if (!state.hasError) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(state.errorText ?? '', style: const TextStyle(color: Colors.red, fontSize: 12)),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 営業時間
                _buildBusinessHoursSection(),
                const SizedBox(height: 20),

                // タグ
                _buildTagsSection(),
                const SizedBox(height: 20),

                // SNS
                _buildSocialMediaSection(),
                const SizedBox(height: 20),

                // 設備
                _buildFacilityInfoSection(),
                const SizedBox(height: 32),

                // 作成ボタン
                CustomButton(
                  text: _isLoading ? '作成中...' : '作成する',
                  onPressed: _isLoading ? () {} : _handleCreate,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                if (_hasFormError)
                  const Text('入力不備があります。内容をご確認ください。', textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontSize: 12)),

                const SizedBox(height: 32),
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
        const Text('位置情報', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: CustomTextField(controller: _latitudeController, labelText: '緯度 *', hintText: '例：35.6581', keyboardType: TextInputType.number, readOnly: true, validator: (v) => (v == null || v.isEmpty) ? '緯度を選択してください' : null)),
            const SizedBox(width: 16),
            Expanded(child: CustomTextField(controller: _longitudeController, labelText: '経度 *', hintText: '例：139.7017', keyboardType: TextInputType.number, readOnly: true, validator: (v) => (v == null || v.isEmpty) ? '経度を選択してください' : null)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: CustomButton(text: '地図を開く', onPressed: _openLocationPicker)),
      ],
    );
  }

  Widget _buildBusinessHoursSection() {
    final isEnabled = !_isRegularHoliday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('営業時間', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        CustomSwitchListTile(
          title: const Text('不定休'),
          value: _isRegularHoliday,
          onChanged: (v) => setState(() => _isRegularHoliday = v),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
          child: Column(
            children: [
              _buildBusinessDayRow('月曜日', 'monday', isEnabled: isEnabled),
              const Divider(),
              _buildBusinessDayRow('火曜日', 'tuesday', isEnabled: isEnabled),
              const Divider(),
              _buildBusinessDayRow('水曜日', 'wednesday', isEnabled: isEnabled),
              const Divider(),
              _buildBusinessDayRow('木曜日', 'thursday', isEnabled: isEnabled),
              const Divider(),
              _buildBusinessDayRow('金曜日', 'friday', isEnabled: isEnabled),
              const Divider(),
              _buildBusinessDayRow('土曜日', 'saturday', isEnabled: isEnabled),
              const Divider(),
              _buildBusinessDayRow('日曜日', 'sunday', isEnabled: isEnabled),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessDayRow(String dayName, String dayKey, {required bool isEnabled}) {
    final isOpen = _businessDaysOpen[dayKey] ?? true;
    final periods = _businessHoursControllers[dayKey] ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 80, child: Text(dayName, style: const TextStyle(fontSize: 14))),
              Switch(
                value: isOpen,
                onChanged: isEnabled ? (v) => setState(() => _businessDaysOpen[dayKey] = v) : null,
                activeColor: Colors.white,
                activeTrackColor: StoreUi.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE0E0E0),
                trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
              ),
            ],
          ),
          if (isOpen && isEnabled) ...[
            ...periods.asMap().entries.map((entry) {
              final periodIndex = entry.key;
              final period = entry.value;
              return Padding(
                padding: const EdgeInsets.only(left: 80, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: _buildTimePicker(controller: period['open']!, enabled: true, label: '開店時間')),
                    const SizedBox(width: 8),
                    const Text('〜'),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTimePicker(controller: period['close']!, enabled: true, label: '閉店時間')),
                    if (periods.length > 1)
                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32), onPressed: () => _removeBusinessPeriod(dayKey, periodIndex))
                    else
                      const SizedBox(width: 32),
                  ],
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.only(left: 80, top: 2),
              child: TextButton.icon(
                onPressed: () => _addBusinessPeriod(dayKey),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('時間帯を追加', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: StoreUi.primary, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePicker({required TextEditingController controller, required bool enabled, required String label}) {
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
            Expanded(child: Text(controller.text.isEmpty ? '時間を選択' : controller.text, style: TextStyle(fontSize: 14, color: enabled ? Colors.black87 : Colors.grey[600]))),
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
        const Text('タグ（任意）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(hintText: '例：カフェ、本屋、Wi-Fi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
        const Text('SNS・ウェブサイト', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        CustomTextField(controller: _websiteController, labelText: 'ウェブサイト', hintText: '例：https://example.com'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: CustomTextField(controller: _instagramController, labelText: 'Instagram', hintText: '例：https://instagram.com/username')),
            const SizedBox(width: 16),
            Expanded(child: CustomTextField(controller: _xController, labelText: 'X (Twitter)', hintText: '例：https://x.com/username')),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(controller: _facebookController, labelText: 'Facebook', hintText: '例：https://facebook.com/page'),
      ],
    );
  }

  Widget _buildFacilityInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('設備・サービス', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        const Text('席数・収容人数', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 12),
        _buildSeatingRow('カウンター席', _counterSeatsController),
        _buildSeatingRow('テーブル席', _tableSeatsController),
        _buildSeatingRow('座敷席', _tatamiSeatsController),
        _buildSeatingRow('テラス席', _terraceSeatsController),
        _buildSeatingRow('個室', _privateRoomSeatsController),
        _buildSeatingRow('ソファー席', _sofaSeatsController),
        const SizedBox(height: 8),
        const Text('駐車場', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _parkingOption,
          decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'none', child: Text('なし')),
            DropdownMenuItem(value: 'available', child: Text('あり')),
            DropdownMenuItem(value: 'nearby_coin_parking', child: Text('近隣にコインパーキングあり')),
          ],
          onChanged: (v) { if (v != null) setState(() => _parkingOption = v); },
        ),
        const SizedBox(height: 16),
        CustomTextField(controller: _accessInfoController, labelText: '最寄り駅・アクセス', hintText: '例：渋谷駅から徒歩5分'),
        const SizedBox(height: 16),
        CustomSwitchListTile(title: const Text('テイクアウト対応'), value: _hasTakeout, onChanged: (v) => setState(() => _hasTakeout = v)),
        const Text('禁煙・喫煙', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _smokingPolicy,
          decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'no_smoking', child: Text('全席禁煙')),
            DropdownMenuItem(value: 'separated', child: Text('分煙')),
            DropdownMenuItem(value: 'smoking_allowed', child: Text('喫煙可')),
          ],
          onChanged: (v) { if (v != null) setState(() => _smokingPolicy = v); },
        ),
        const SizedBox(height: 16),
        CustomSwitchListTile(title: const Text('Wi-Fi'), value: _hasWifi, onChanged: (v) => setState(() => _hasWifi = v)),
        const Divider(),
        const SizedBox(height: 8),
        const Text('その他の対応', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        CustomSwitchListTile(title: const Text('バリアフリー対応'), value: _isBarrierFree, onChanged: (v) => setState(() => _isBarrierFree = v)),
        CustomSwitchListTile(title: const Text('子連れ対応'), value: _isChildFriendly, onChanged: (v) => setState(() => _isChildFriendly = v)),
        CustomSwitchListTile(title: const Text('ペット同伴可'), value: _isPetFriendly, onChanged: (v) => setState(() => _isPetFriendly = v)),
      ],
    );
  }

  Widget _buildSeatingRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87))),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: '0', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
            ),
          ),
          const SizedBox(width: 8),
          const Text('席', style: TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildIconImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('店舗アイコン画像', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Center(
          child: IconImagePickerField(
            size: 120,
            onTap: _pickIconImage,
            onRemove: _removeIconImage,
            showRemove: (_webIconImageBytes != null) || (_selectedIconImage != null) || (_iconImageUrl?.isNotEmpty ?? false),
            backgroundColor: Colors.grey[100]!,
            borderColor: Colors.grey[300]!,
            child: _buildIconImage(),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('店舗イメージ画像', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        ImagePickerField(
          aspectRatio: 2 / 1,
          onTap: _pickStoreImage,
          child: _buildStoreImage(),
          showRemove: (_webStoreImageBytes != null) || (_selectedStoreImage != null) || (_storeImageUrl?.isNotEmpty ?? false),
          onRemove: _removeStoreImage,
          borderColor: Colors.grey[300]!,
          backgroundColor: Colors.grey[100]!,
        ),
      ],
    );
  }

  Widget _buildIconImage() {
    if (_iconImageUrl != null && _iconImageUrl!.isNotEmpty) {
      return Image.network(_iconImageUrl!, width: 120, height: 120, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildSelectedIconImage());
    } else if (_selectedIconImage != null || _webIconImageBytes != null) {
      return _buildSelectedIconImage();
    } else {
      return _buildDefaultStoreIconPreview(120);
    }
  }

  Widget _buildSelectedIconImage() {
    if (_webIconImageBytes != null) {
      return Image.memory(_webIconImageBytes!, width: 120, height: 120, fit: BoxFit.cover);
    } else if (_selectedIconImage != null) {
      return FutureBuilder<Uint8List>(
        future: _selectedIconImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) return Image.memory(snapshot.data!, width: 120, height: 120, fit: BoxFit.cover);
          return Container(width: 120, height: 120, color: Colors.grey[300]);
        },
      );
    }
    return _buildDefaultStoreIconPreview(120);
  }

  Widget _buildDefaultStoreIconPreview(double size) {
    final category = _selectedCategory ?? 'その他';
    final color = _getCategoryColor(category);
    return Container(
      width: size, height: size,
      color: color.withOpacity(0.1),
      alignment: Alignment.center,
      child: Icon(_getCategoryIcon(category), color: color, size: size * 0.5),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'レストラン': return Colors.red;
      case 'カフェ・喫茶店': return Colors.brown;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'レストラン': return Icons.restaurant;
      case 'カフェ・喫茶店': return Icons.local_cafe;
      default: return Icons.store;
    }
  }

  Widget _buildStoreImage() {
    if (_storeImageUrl != null && _storeImageUrl!.isNotEmpty) {
      return Image.network(_storeImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildStoreImagePlaceholder());
    } else if (_selectedStoreImage != null || _webStoreImageBytes != null) {
      if (_webStoreImageBytes != null) {
        return Image.memory(_webStoreImageBytes!, fit: BoxFit.cover);
      } else {
        return FutureBuilder<Uint8List>(
          future: _selectedStoreImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) return Image.memory(snapshot.data!, fit: BoxFit.cover);
            return _buildStoreImagePlaceholder();
          },
        );
      }
    }
    return _buildStoreImagePlaceholder();
  }

  Widget _buildStoreImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: const ImagePickerPlaceholder(aspectRatio: 2 / 1),
    );
  }

  Widget _buildBusinessTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('経営形態 *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('個人事業'),
                value: 'individual',
                groupValue: _businessType,
                activeColor: const Color(0xFFFF6B35),
                onChanged: (v) => setState(() { _businessType = v!; _businessNameController.clear(); }),
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text('法人'),
                value: 'corporate',
                groupValue: _businessType,
                activeColor: const Color(0xFFFF6B35),
                onChanged: (v) => setState(() { _businessType = v!; _businessNameController.clear(); }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
