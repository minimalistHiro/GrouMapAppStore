import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/icon_image_picker_field.dart';
import '../../widgets/image_picker_field.dart';
import '../../widgets/common_header.dart';
import '../auth/store_location_picker_view.dart';
import 'store_icon_crop_view.dart';
import '../../utils/icon_image_flow.dart';

class StoreProfileEditView extends ConsumerStatefulWidget {
  const StoreProfileEditView({Key? key}) : super(key: key);

  @override
  ConsumerState<StoreProfileEditView> createState() => _StoreProfileEditViewState();
}

class _StoreProfileEditViewState extends ConsumerState<StoreProfileEditView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  
  String? _selectedStoreId;
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedPrefecture;
  String? _selectedCity;
  List<String> _cities = [];
  bool _isLoadingCities = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isRegularHoliday = false;
  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _hasFormError = false;
  
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

  // 経営情報
  final _businessNameController = TextEditingController();
  String _businessType = 'individual';

  // 設備・サービス情報
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
    'カフェ・喫茶店',
    'レストラン',
    '居酒屋',
    '和食',
    '日本料理',
    '海鮮',
    '寿司',
    'そば',
    'うどん',
    'うなぎ',
    '焼き鳥',
    'とんかつ',
    '串揚げ',
    '天ぷら',
    'お好み焼き',
    'もんじゃ焼き',
    'しゃぶしゃぶ',
    '鍋',
    '焼肉',
    'ホルモン',
    'ラーメン',
    '中華料理',
    '餃子',
    '韓国料理',
    'タイ料理',
    'カレー',
    '洋食',
    'フレンチ',
    'スペイン料理',
    'ビストロ',
    'パスタ',
    'ピザ',
    'ステーキ',
    'ハンバーグ',
    'ハンバーガー',
    'ビュッフェ',
    '食堂',
    'パン・サンドイッチ',
    'スイーツ',
    'ケーキ',
    'タピオカ',
    'バー・お酒',
    'スナック',
    '料理旅館',
    '沖縄料理',
    'その他',
  ];

  final List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
    '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
    '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
    '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
  ];

  List<String> get _subCategories {
    if (_selectedCategory == null) {
      return _categories;
    }
    return _categories.where((category) => category != _selectedCategory).toList();
  }

  Color _getDefaultStoreColor(String category) {
    switch (category) {
      case 'レストラン':
        return Colors.red;
      case 'カフェ':
        return Colors.brown;
      case 'ショップ':
        return Colors.blue;
      case '美容院':
        return Colors.pink;
      case '薬局':
        return Colors.green;
      case 'コンビニ':
        return Colors.orange;
      case 'スーパー':
        return Colors.lightGreen;
      case '書店':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getDefaultStoreIcon(String category) {
    switch (category) {
      case 'レストラン':
        return Icons.restaurant;
      case 'カフェ':
        return Icons.local_cafe;
      case 'ショップ':
        return Icons.shopping_bag;
      case '美容院':
        return Icons.content_cut;
      case '薬局':
        return Icons.local_pharmacy;
      case 'コンビニ':
        return Icons.store;
      case 'スーパー':
        return Icons.shopping_cart;
      case '書店':
        return Icons.menu_book;
      default:
        return Icons.store;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _instagramController.dispose();
    _xController.dispose();
    _facebookController.dispose();
    _websiteController.dispose();
    _tagController.dispose();
    _businessNameController.dispose();
    _counterSeatsController.dispose();
    _tableSeatsController.dispose();
    _tatamiSeatsController.dispose();
    _terraceSeatsController.dispose();
    _privateRoomSeatsController.dispose();
    _sofaSeatsController.dispose();
    _accessInfoController.dispose();
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
        _businessType = storeData['businessType'] as String? ?? 'individual';
        _businessNameController.text = storeData['businessName'] as String? ?? '';
        final rawPhone = storeData['phone'] ?? '';
        _phoneController.text = rawPhone.toString().replaceAll(RegExp(r'\\D'), '');
        _descriptionController.text = storeData['description'] ?? '';
        _parseAddressToFields(storeData['address'] ?? '');
        if (mounted) {
          setState(() {
            _selectedCategory = storeData['category'];
            final rawSubCategory = storeData['subCategory'];
            final normalizedSubCategory =
                (rawSubCategory == null || (rawSubCategory is String && rawSubCategory.trim().isEmpty))
                    ? null
                    : rawSubCategory;
            _selectedSubCategory =
                normalizedSubCategory == storeData['category'] ? null : normalizedSubCategory;
            _isRegularHoliday = storeData['isRegularHoliday'] ?? false;
          });
        } else {
          _selectedCategory = storeData['category'];
          final rawSubCategory = storeData['subCategory'];
          final normalizedSubCategory =
              (rawSubCategory == null || (rawSubCategory is String && rawSubCategory.trim().isEmpty))
                  ? null
                  : rawSubCategory;
          _selectedSubCategory =
              normalizedSubCategory == storeData['category'] ? null : normalizedSubCategory;
          _isRegularHoliday = storeData['isRegularHoliday'] ?? false;
        }
        
        // 位置情報
        if (storeData['location'] != null) {
          final location = storeData['location'];
          if (location['latitude'] != null && location['longitude'] != null) {
            _selectedLatitude = location['latitude'].toDouble();
            _selectedLongitude = location['longitude'].toDouble();
            _updateLocationControllers();
          }
        }
        
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
        
        // 設備・サービス情報
        if (storeData['facilityInfo'] != null) {
          final facilityInfo = Map<String, dynamic>.from(storeData['facilityInfo']);
          final seating = facilityInfo['seatingCapacity'];
          if (seating is Map) {
            _counterSeatsController.text = (seating['counter'] ?? 0) > 0 ? seating['counter'].toString() : '';
            _tableSeatsController.text = (seating['table'] ?? 0) > 0 ? seating['table'].toString() : '';
            _tatamiSeatsController.text = (seating['tatami'] ?? 0) > 0 ? seating['tatami'].toString() : '';
            _terraceSeatsController.text = (seating['terrace'] ?? 0) > 0 ? seating['terrace'].toString() : '';
            _privateRoomSeatsController.text = (seating['privateRoom'] ?? 0) > 0 ? seating['privateRoom'].toString() : '';
            _sofaSeatsController.text = (seating['sofa'] ?? 0) > 0 ? seating['sofa'].toString() : '';
          }
          _parkingOption = facilityInfo['parking'] ?? 'none';
          _accessInfoController.text = facilityInfo['accessInfo'] ?? '';
          _hasTakeout = facilityInfo['takeout'] ?? false;
          _smokingPolicy = facilityInfo['smokingPolicy'] ?? 'no_smoking';
          _hasWifi = facilityInfo['hasWifi'] ?? false;
          _isBarrierFree = facilityInfo['barrierFree'] ?? false;
          _isChildFriendly = facilityInfo['childFriendly'] ?? false;
          _isPetFriendly = facilityInfo['petFriendly'] ?? false;
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
      final Uint8List? cropped = await pickAndCropIconImage(
        context: context,
        picker: _picker,
        buildCropView: (bytes) => StoreIconCropView(imageBytes: bytes),
      );
      if (!mounted) return;
      if (cropped != null) {
        setState(() {
          _selectedIconImage = cropped;
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
      _formKey.currentState?.validate();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _formKey.currentState?.validate();
  }

  void _updateLocationControllers() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      _latitudeController.text = _selectedLatitude!.toStringAsFixed(6);
      _longitudeController.text = _selectedLongitude!.toStringAsFixed(6);
      return;
    }

    _latitudeController.text = '';
    _longitudeController.text = '';
  }

  Future<void> _openLocationPicker() async {
    final selectedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => const StoreLocationPickerView(),
      ),
    );

    if (selectedLocation == null) {
      return;
    }

    setState(() {
      _selectedLatitude = selectedLocation.latitude;
      _selectedLongitude = selectedLocation.longitude;
      _updateLocationControllers();
    });
  }

  Future<void> _loadCitiesForPrefecture(String prefecture) async {
    setState(() {
      _isLoadingCities = true;
    });

    // 常にフォールバックデータを使用（APIキーが設定されていないため）
    _loadFallbackCities(prefecture);
  }

  void _loadFallbackCities(String prefecture) {
    // フォールバック用の市区町村データ
    List<String> cities = [];

    switch (prefecture) {
      case '東京都':
        cities = ['千代田区', '中央区', '港区', '新宿区', '文京区', '台東区', '墨田区', '江東区', '品川区', '目黒区', '大田区', '世田谷区', '渋谷区', '中野区', '杉並区', '豊島区', '北区', '荒川区', '板橋区', '練馬区', '足立区', '葛飾区', '江戸川区', '八王子市', '立川市', '武蔵野市', '三鷹市', '青梅市', '府中市', '昭島市', '調布市', '町田市', '小金井市', '小平市', '日野市', '東村山市', '国分寺市', '国立市', '福生市', '狛江市', '東大和市', '清瀬市', '東久留米市', '武蔵村山市', '多摩市', '稲城市', '羽村市', 'あきる野市', '西東京市'];
        break;
      case '大阪府':
        cities = ['大阪市', '堺市', '岸和田市', '豊中市', '池田市', '吹田市', '泉大津市', '高槻市', '貝塚市', '守口市', '枚方市', '茨木市', '八尾市', '泉佐野市', '富田林市', '寝屋川市', '河内長野市', '松原市', '大東市', '和泉市', '箕面市', '柏原市', '羽曳野市', '門真市', '摂津市', '高石市', '藤井寺市', '東大阪市', '泉南市', '四條畷市', '交野市', '大阪狭山市', '阪南市', '島本町', '豊能町', '能勢町', '忠岡町', '熊取町', '田尻町', '岬町', '太子町', '河南町', '千早赤阪村'];
        break;
      case '神奈川県':
        cities = ['横浜市', '川崎市', '相模原市', '横須賀市', '平塚市', '鎌倉市', '藤沢市', '小田原市', '茅ヶ崎市', '逗子市', '三浦市', '秦野市', '厚木市', '大和市', '伊勢原市', '海老名市', '座間市', '南足柄市', '綾瀬市', '葉山町', '寒川町', '大磯町', '二宮町', '中井町', '大井町', '松田町', '山北町', '開成町', '箱根町', '真鶴町', '湯河原町', '愛川町', '清川村'];
        break;
      case '愛知県':
        cities = ['名古屋市', '豊橋市', '岡崎市', '一宮市', '瀬戸市', '半田市', '春日井市', '豊川市', '津島市', '碧南市', '刈谷市', '豊田市', '安城市', '西尾市', '蒲郡市', '犬山市', '常滑市', '江南市', '小牧市', '稲沢市', '新城市', '東海市', '大府市', '知多市', '知立市', '尾張旭市', '高浜市', '岩倉市', '豊明市', '日進市', '田原市', '愛西市', '清須市', '北名古屋市', '弥富市', 'みよし市', 'あま市', '長久手市', '東郷町', '豊山町', '大口町', '扶桑町', '大治町', '蟹江町', '飛島村', '阿久比町', '東浦町', '南知多町', '美浜町', '武豊町', '幸田町', '設楽町', '東栄町', '豊根村'];
        break;
      case '埼玉県':
        cities = ['さいたま市', '川越市', '熊谷市', '川口市', '行田市', '秩父市', '所沢市', '飯能市', '加須市', '本庄市', '東松山市', '春日部市', '狭山市', '羽生市', '鴻巣市', '深谷市', '上尾市', '草加市', '越谷市', '蕨市', '戸田市', '入間市', '朝霞市', '志木市', '和光市', '新座市', '桶川市', '久喜市', '北本市', '八潮市', '富士見市', '三郷市', '蓮田市', '坂戸市', '幸手市', '鶴ヶ島市', '日高市', '吉川市', 'ふじみ野市', '白岡市', '伊奈町', '三芳町', '毛呂山町', '越生町', '滑川町', '嵐山町', '小川町', '川島町', '吉見町', '鳩山町', 'ときがわ町', '横瀬町', '皆野町', '長瀞町', '小鹿野町', '東秩父村', '美里町', '神川町', '上里町', '寄居町', '宮代町', '杉戸町', '松伏町'];
        break;
      case '北海道':
        cities = ['札幌市', '函館市', '小樽市', '旭川市', '室蘭市', '釧路市', '帯広市', '北見市', '夕張市', '岩見沢市', '留萌市', '苫小牧市', '稚内市', '美唄市', '芦別市', '江別市', '赤平市', '三笠市', '千歳市', '滝川市', '砂川市', '歌志内市', '深川市', '富良野市', '登別市', '恵庭市', '伊達市', '北広島市', '石狩市', '北斗市', '当別町', '新篠津村', '松前町', '福島町', '知内町', '木古内町', '七飯町', '鹿部町', '森町', '八雲町', '長万部町', '江差町', '上ノ国町', '厚沢部町', '乙部町', '奥尻町', '今金町', 'せたな町', '島牧村', '寿都町', '黒松内町', '蘭越町', 'ニセコ町', '真狩村', '留寿都村', '喜茂別町', '京極町', '倶知安町', '共和町', '岩内町', '泊村', '神恵内村', '積丹町', '古平町', '仁木町', '余市町', '赤井川村', '南幌町', '奈井江町', '上砂川町', '由仁町', '長沼町', '栗山町', '月形町', '浦臼町', '新十津川町', '妹背牛町', '秩父別町', '雨竜町', '北竜町', '沼田町', '幌加内町', '鷹栖町', '東神楽町', '当麻町', '比布町', '愛別町', '上川町', '東川町', '美瑛町', '上富良野町', '中富良野町', '南富良野町', '占冠村', '和寒町', '剣淵町', '下川町', '美深町', '音威子府村', '中川町', '幌加内町', '増毛町', '小平町', '苫前町', '羽幌町', '初山別村', '遠別町', '天塩町', '猿払村', '浜頓別町', '中頓別町', '枝幸町', '豊富町', '礼文町', '利尻町', '利尻富士町', '幌延町', '美幌町', '津別町', '斜里町', '清里町', '小清水町', '訓子府町', '置戸町', '佐呂間町', '遠軽町', '湧別町', '滝上町', '興部町', '西興部村', '雄武町', '大空町', '豊浦町', '壮瞥町', '白老町', '厚真町', '洞爺湖町', '安平町', 'むかわ町', '日高町', '平取町', '新冠町', '浦河町', '様似町', 'えりも町', '新ひだか町', '音更町', '士幌町', '上士幌町', '鹿追町', '新得町', '清水町', '芽室町', '中札内村', '更別村', '大樹町', '広尾町', '幕別町', '池田町', '豊頃町', '本別町', '足寄町', '陸別町', '浦幌町', '釧路町', '厚岸町', '浜中町', '標茶町', '弟子屈町', '鶴居村', '白糠町', '別海町', '中標津町', '標津町', '羅臼町'];
        break;
      case '青森県':
        cities = ['青森市', '弘前市', '八戸市', '黒石市', '五所川原市', '十和田市', 'つがる市', '平川市', '三沢市', 'むつ市', 'つがる市', '平川市', '今別町', '蓬田村', '外ヶ浜町', '板柳町', '鶴田町', '中泊町', '西目屋村', '藤崎町', '大鰐町', '田舎館村', '鰺ヶ沢町', '深浦町', '能代市', '三種町', '八峰町', '五城目町', '八郎潟町', '井川町', '大潟村', '小坂町', '上小阿仁村', '藤里町', '三戸町', '五戸町', '田子町', '南部町', '階上町', '新郷村', 'おいらせ町', '六戸町', '東北町', '六ヶ所村', '横浜町', '東通村', '風間浦村', '佐井村'];
        break;
      case '岩手県':
        cities = ['盛岡市', '宮古市', '大船渡市', '花巻市', '北上市', '久慈市', '遠野市', '一関市', '陸前高田市', '奥州市', '滝沢市', '雫石町', '葛巻町', '岩手町', '紫波町', '矢巾町', '西和賀町', '金ケ崎町', '平泉町', '住田町', '大槌町', '山田町', '岩泉町', '田野畑村', '普代村', '軽米町', '野田村', '九戸村', '洋野町', '一戸町', '二戸市'];
        break;
      case '宮城県':
        cities = ['仙台市', '石巻市', '塩竈市', '気仙沼市', '白石市', '名取市', '角田市', '多賀城市', '岩沼市', '登米市', '栗原市', '東松島市', '大崎市', '富谷市', '蔵王町', '七ヶ宿町', '大河原町', '村田町', '柴田町', '川崎町', '丸森町', '亘理町', '山元町', '松島町', '七ヶ浜町', '利府町', '大和町', '大郷町', '大衡村', '色麻町', '加美町', '涌谷町', '美里町', '南三陸町', '女川町'];
        break;
      case '秋田県':
        cities = ['秋田市', '能代市', '横手市', '大館市', '男鹿市', '湯沢市', '鹿角市', '由利本荘市', '潟上市', '大仙市', '北秋田市', 'にかほ市', '仙北市', '小坂町', '上小阿仁村', '藤里町', '三種町', '八峰町', '五城目町', '八郎潟町', '井川町', '大潟村', '美郷町', '羽後町', '東成瀬村'];
        break;
      case '山形県':
        cities = ['山形市', '米沢市', '鶴岡市', '酒田市', '新庄市', '寒河江市', '上山市', '村山市', '長井市', '天童市', '東根市', '尾花沢市', '南陽市', '山辺町', '中山町', '河北町', '西川町', '朝日町', '大江町', '大石田町', '金山町', '最上町', '舟形町', '真室川町', '大蔵村', '鮭川村', '戸沢村', '高畠町', '川西町', '小国町', '白鷹町', '飯豊町', '三川町', '庄内町', '遊佐町'];
        break;
      case '福島県':
        cities = ['福島市', '会津若松市', 'いわき市', '白河市', '須賀川市', '喜多方市', '相馬市', '二本松市', '郡山市', 'いわき市', '田村市', '南相馬市', '伊達市', '本宮市', '三春町', '小野町', '広野町', '楢葉町', '富岡町', '川内村', '大熊町', '双葉町', '浪江町', '葛尾村', '新地町', '飯舘村', '桑折町', '国見町', '川俣町', '大玉村', '鏡石町', '天栄村', '下郷町', '檜枝岐村', '只見町', '南会津町', '西会津町', '磐梯町', '猪苗代町', '会津坂下町', '湯川村', '柳津町', '三島町', '金山町', '昭和村', '会津美里町', '矢祭町', '塙町', '鮫川村', '石川町', '玉川村', '平田村', '浅川町', '古殿町', '棚倉町', '矢吹町', '泉崎村', '中島村', '矢祭町', '塙町', '鮫川村'];
        break;
      case '茨城県':
        cities = ['水戸市', '日立市', '土浦市', '古河市', '石岡市', '結城市', '龍ケ崎市', '下妻市', '常総市', '常陸太田市', '高萩市', '北茨城市', '笠間市', '取手市', '牛久市', 'つくば市', 'ひたちなか市', '鹿嶋市', '潮来市', '守谷市', '常陸大宮市', '那珂市', '筑西市', '坂東市', '稲敷市', 'かすみがうら市', '桜川市', '神栖市', '行方市', '鉾田市', 'つくばみらい市', '小美玉市', '茨城町', '大洗町', '城里町', '東海村', '大子町', '美浦村', '阿見町', '河内町', '八千代町', '五霞町', '境町', '利根町'];
        break;
      case '栃木県':
        cities = ['宇都宮市', '足利市', '栃木市', '佐野市', '鹿沼市', '日光市', '小山市', '真岡市', '大田原市', '矢板市', '那須塩原市', 'さくら市', '那須烏山市', '下野市', '上三川町', '益子町', '茂木町', '市貝町', '芳賀町', '壬生町', '野木町', '塩谷町', '高根沢町', '那須町', '那珂川町'];
        break;
      case '群馬県':
        cities = ['前橋市', '高崎市', '桐生市', '伊勢崎市', '太田市', '沼田市', '館林市', '渋川市', '藤岡市', '富岡市', '安中市', 'みどり市', '榛東村', '吉岡町', '上野村', '神流町', '下仁田町', '南牧村', '甘楽町', '中之条町', '長野原町', '嬬恋村', '草津町', '高山村', '東吾妻町', '片品村', '川場村', '昭和村', 'みなかみ町', '玉村町'];
        break;
      case '千葉県':
        cities = ['千葉市', '銚子市', '市川市', '船橋市', '館山市', '木更津市', '松戸市', '野田市', '茂原市', '成田市', '佐倉市', '東金市', '旭市', '習志野市', '柏市', '勝浦市', '市原市', '流山市', '八千代市', '我孫子市', '鴨川市', '鎌ケ谷市', '君津市', '富津市', '浦安市', '四街道市', '袖ケ浦市', '八街市', '印西市', '白井市', '富里市', '南房総市', '匝瑳市', '香取市', '山武市', 'いすみ市', '大網白里市', '酒々井町', '栄町', '神崎町', '多古町', '東庄町', '九十九里町', '芝山町', '横芝光町', '一宮町', '睦沢町', '長生村', '白子町', '長柄町', '長南町', '大多喜町', '御宿町', '鋸南町'];
        break;
      case '新潟県':
        cities = ['新潟市', '長岡市', '三条市', '柏崎市', '新発田市', '小千谷市', '加茂市', '十日町市', '見附市', '村上市', '燕市', '糸魚川市', '妙高市', '五泉市', '上越市', '阿賀野市', '佐渡市', '魚沼市', '南魚沼市', '胎内市', '聖籠町', '弥彦村', '田上町', '阿賀町', '出雲崎町', '湯沢町', '津南町', '刈羽村', '関川村', '粟島浦村'];
        break;
      case '富山県':
        cities = ['富山市', '高岡市', '魚津市', '氷見市', '滑川市', '黒部市', '砺波市', '小矢部市', '南砺市', '射水市', '舟橋村', '上市町', '立山町', '入善町', '朝日町'];
        break;
      case '石川県':
        cities = ['金沢市', '七尾市', '小松市', '輪島市', '珠洲市', '加賀市', '羽咋市', 'かほく市', '白山市', '能美市', '野々市市', '津幡町', '内灘町', '志賀町', '宝達志水町', '中能登町', '穴水町', '能登町'];
        break;
      case '福井県':
        cities = ['福井市', '敦賀市', '小浜市', '大野市', '勝山市', '鯖江市', 'あわら市', '越前市', '坂井市', '永平寺町', '池田町', '南越前町', '越前町', '美浜町', '高浜町', 'おおい町', '若狭町'];
        break;
      case '山梨県':
        cities = ['甲府市', '富士吉田市', '都留市', '山梨市', '大月市', '韮崎市', '南アルプス市', '北杜市', '甲斐市', '笛吹市', '上野原市', '甲州市', '中央市', '市川三郷町', '早川町', '身延町', '南部町', '富士川町', '昭和町', '道志村', '西桂町', '忍野村', '山中湖村', '鳴沢村', '富士河口湖町', '小菅村', '丹波山村'];
        break;
      case '長野県':
        cities = ['長野市', '松本市', '上田市', '岡谷市', '飯田市', '諏訪市', '須坂市', '小諸市', '伊那市', '中野市', '大町市', '飯山市', '茅野市', '塩尻市', '佐久市', '千曲市', '東御市', '安曇野市', '小海町', '川上村', '南牧村', '南相木村', '北相木村', '佐久穂町', '軽井沢町', '御代田町', '立科町', '青木村', '長和町', '下諏訪町', '富士見町', '原村', '辰野町', '箕輪町', '飯島町', '南箕輪村', '中川村', '宮田村', '松川町', '高森町', '阿南町', '阿智村', '平谷村', '根羽村', '下條村', '売木村', '天龍村', '泰阜村', '喬木村', '豊丘村', '大鹿村', '上松町', '南木曽町', '木祖村', '王滝村', '大桑村', '木曽町', '麻績村', '生坂村', '山形村', '朝日村', '筑北村', '池田町', '松川村', '白馬村', '小谷村', '坂城町', '小布施町', '高山村', '山ノ内町', '木島平村', '野沢温泉村', '信濃町', '小川村', '飯綱町', '栄村'];
        break;
      case '岐阜県':
        cities = ['岐阜市', '大垣市', '高山市', '多治見市', '関市', '中津川市', '美濃市', '瑞浪市', '羽島市', '各務原市', '可児市', '山県市', '瑞穂市', '飛騨市', '本巣市', '郡上市', '下呂市', '海津市', '岐南町', '笠松町', '養老町', '垂井町', '関ケ原町', '神戸町', '輪之内町', '安八町', '揖斐川町', '大野町', '池田町', '北方町', '坂祝町', '富加町', '川辺町', '七宗町', '八百津町', '白川町', '東白川村', '御嵩町', '白川村', '東白川村'];
        break;
      case '静岡県':
        cities = ['静岡市', '浜松市', '沼津市', '熱海市', '三島市', '富士宮市', '伊東市', '島田市', '富士市', '磐田市', '焼津市', '掛川市', '藤枝市', '御殿場市', '袋井市', '下田市', '裾野市', '湖西市', '伊豆市', '御前崎市', '菊川市', '伊豆の国市', '牧之原市', '東伊豆町', '河津町', '南伊豆町', '松崎町', '西伊豆町', '函南町', '清水町', '長泉町', '小山町', '吉田町', '川根本町', '森町'];
        break;
      case '三重県':
        cities = ['津市', '四日市市', '伊勢市', '松阪市', '桑名市', '鈴鹿市', '名張市', '尾鷲市', '亀山市', '伊賀市', '志摩市', 'いなべ市', '桑名市', '木曽岬町', '東員町', '菰野町', '朝日町', '川越町', '多気町', '明和町', '大台町', '玉城町', '度会町', '大紀町', '南伊勢町', '紀北町', '御浜町', '紀宝町'];
        break;
      case '滋賀県':
        cities = ['大津市', '彦根市', '長浜市', '近江八幡市', '草津市', '守山市', '栗東市', '甲賀市', '野洲市', '湖南市', '高島市', '東近江市', '米原市', '日野町', '竜王町', '愛荘町', '豊郷町', '甲良町', '多賀町'];
        break;
      case '京都府':
        cities = ['京都市', '福知山市', '舞鶴市', '綾部市', '宇治市', '宮津市', '亀岡市', '城陽市', '向日市', '長岡京市', '八幡市', '京田辺市', '京丹後市', '南丹市', '木津川市', '大山崎町', '久御山町', '井手町', '宇治田原町', '笠置町', '和束町', '精華町', '南山城村', '京丹波町', '伊根町', '与謝野町'];
        break;
      case '兵庫県':
        cities = ['神戸市', '姫路市', '尼崎市', '明石市', '西宮市', '洲本市', '芦屋市', '伊丹市', '相生市', '豊岡市', '加古川市', '赤穂市', '西脇市', '宝塚市', '三木市', '高砂市', '川西市', '小野市', '三田市', '加西市', '丹波篠山市', '養父市', '丹波市', '南あわじ市', '朝来市', '淡路市', '宍粟市', '加東市', 'たつの市', '猪名川町', '多可町', '稲美町', '播磨町', '市川町', '福崎町', '神河町', '太子町', '上郡町', '佐用町', '香美町', '新温泉町'];
        break;
      case '奈良県':
        cities = ['奈良市', '大和高田市', '大和郡山市', '天理市', '橿原市', '桜井市', '五條市', '御所市', '生駒市', '香芝市', '葛城市', '宇陀市', '山添村', '平群町', '三郷町', '斑鳩町', '安堵町', '川西町', '三宅町', '田原本町', '曽爾村', '御杖村', '高取町', '明日香村', '上牧町', '王寺町', '広陵町', '河合町', '吉野町', '大淀町', '下市町', '黒滝村', '天川村', '野迫川村', '十津川村', '下北山村', '上北山村', '川上村', '東吉野村'];
        break;
      case '和歌山県':
        cities = ['和歌山市', '海南市', '橋本市', '有田市', '御坊市', '田辺市', '新宮市', '紀の川市', '岩出市', '紀美野町', 'かつらぎ町', '九度山町', '高野町', '湯浅町', '広川町', '有田川町', '美浜町', '日高町', '由良町', '印南町', 'みなべ町', '日高川町', '白浜町', '上富田町', 'すさみ町', '那智勝浦町', '太地町', '古座川町', '北山村', '串本町'];
        break;
      case '鳥取県':
        cities = ['鳥取市', '米子市', '倉吉市', '境港市', '岩美町', '若桜町', '智頭町', '八頭町', '三朝町', '湯梨浜町', '琴浦町', '北栄町', '日吉津村', '大山町', '南部町', '伯耆町', '日南町', '日野町', '江府町'];
        break;
      case '島根県':
        cities = ['松江市', '浜田市', '出雲市', '益田市', '大田市', '安来市', '江津市', '雲南市', '奥出雲町', '飯南町', '川本町', '美郷町', '邑南町', '津和野町', '吉賀町', '海士町', '西ノ島町', '知夫村', '隠岐の島町'];
        break;
      case '岡山県':
        cities = ['岡山市', '倉敷市', '津山市', '玉野市', '笠岡市', '井原市', '総社市', '高梁市', '新見市', '備前市', '瀬戸内市', '赤磐市', '真庭市', '美作市', '浅口市', '和気町', '早島町', '里庄町', '矢掛町', '新庄村', '鏡野町', '勝央町', '奈義町', '西粟倉村', '久米南町', '美咲町', '吉備中央町'];
        break;
      case '広島県':
        cities = ['広島市', '呉市', '竹原市', '三原市', '尾道市', '福山市', '府中市', '三次市', '庄原市', '大竹市', '東広島市', '廿日市市', '安芸高田市', '江田島市', '府中町', '海田町', '熊野町', '坂町', '安芸太田町', '北広島町', '大崎上島町', '世羅町', '神石高原町'];
        break;
      case '山口県':
        cities = ['下関市', '宇部市', '山口市', '萩市', '防府市', '下松市', '岩国市', '光市', '長門市', '柳井市', '美祢市', '周南市', '山陽小野田市', '周防大島町', '和木町', '上関町', '田布施町', '平生町', '阿武町'];
        break;
      case '徳島県':
        cities = ['徳島市', '鳴門市', '小松島市', '阿南市', '吉野川市', '阿波市', '美馬市', '三好市', '勝浦町', '上勝町', '佐那河内村', '石井町', '神山町', '那賀町', '牟岐町', '美波町', '海陽町', 'つるぎ町', '東みよし町'];
        break;
      case '香川県':
        cities = ['高松市', '丸亀市', '坂出市', '善通寺市', '観音寺市', 'さぬき市', '東かがわ市', '三豊市', '土庄町', '小豆島町', '三木町', '直島町', '宇多津町', '綾川町', '琴平町', '多度津町', 'まんのう町'];
        break;
      case '愛媛県':
        cities = ['松山市', '今治市', '宇和島市', '八幡浜市', '新居浜市', '西条市', '大洲市', '伊予市', '四国中央市', '西予市', '東温市', '上島町', '久万高原町', '松前町', '砥部町', '内子町', '伊方町', '松野町', '鬼北町', '愛南町'];
        break;
      case '高知県':
        cities = ['高知市', '室戸市', '安芸市', '南国市', '土佐市', '須崎市', '宿毛市', '土佐清水市', '香南市', '香美市', '東洋町', '奈半利町', '田野町', '安田町', '北川村', '馬路村', '芸西村', '本山町', '大豊町', '土佐町', '大川村', 'いの町', '仁淀川町', '中土佐町', '佐川町', '越知町', '梼原町', '日高村', '津野町', '四万十町', '大月町', '三原村', '黒潮町'];
        break;
      case '福岡県':
        cities = ['北九州市', '福岡市', '大牟田市', '久留米市', '直方市', '飯塚市', '田川市', '柳川市', '八女市', '筑後市', '大野城市', '春日市', '宗像市', '太宰府市', '古賀市', '福津市', 'うきは市', '宮若市', '嘉麻市', '朝倉市', 'みやま市', '那珂川市', '宇美町', '篠栗町', '志免町', '須恵町', '新宮町', '久山町', '粕屋町', '芦屋町', '水巻町', '岡垣町', '遠賀町', '小竹町', '鞍手町', '桂川町', '筑前町', '東峰村', '大刀洗町', '大木町', '広川町', '香春町', '添田町', '糸田町', '川崎町', '大任町', '赤村', '福智町', '苅田町', 'みやこ町', '吉富町', '上毛町', '築上町'];
        break;
      case '佐賀県':
        cities = ['佐賀市', '唐津市', '鳥栖市', '多久市', '伊万里市', '武雄市', '鹿島市', '小城市', '嬉野市', '神埼市', '吉野ヶ里町', '上峰町', 'みやき町', '玄海町', '有田町', '大町町', '江北町', '白石町', '太良町'];
        break;
      case '長崎県':
        cities = ['長崎市', '佐世保市', '島原市', '諫早市', '大村市', '平戸市', '松浦市', '対馬市', '壱岐市', '五島市', '西海市', '雲仙市', '南島原市', '長与町', '時津町', '東彼杵町', '川棚町', '波佐見町', '小値賀町', '佐々町', '新上五島町'];
        break;
      case '熊本県':
        cities = ['熊本市', '八代市', '人吉市', '荒尾市', '水俣市', '玉名市', '山鹿市', '菊池市', '宇土市', '上天草市', '宇城市', '阿蘇市', '天草市', '合志市', '美里町', '玉東町', '南関町', '長洲町', '和水町', '大津町', '菊陽町', '南小国町', '小国町', '産山村', '高森町', '西原村', '南阿蘇村', '御船町', '嘉島町', '益城町', '甲佐町', '山都町', '氷川町', '芦北町', '津奈木町', '錦町', '多良木町', '湯前町', '水上村', '相良村', '五木村', '山江村', '球磨村', 'あさぎり町', '苓北町', '天草市'];
        break;
      case '大分県':
        cities = ['大分市', '別府市', '中津市', '日田市', '佐伯市', '臼杵市', '津久見市', '竹田市', '豊後高田市', '杵築市', '宇佐市', '豊後大野市', '由布市', '国東市', '姫島村', '日出町', '九重町', '玖珠町'];
        break;
      case '宮崎県':
        cities = ['宮崎市', '都城市', '延岡市', '日南市', '小林市', '日向市', '串間市', '西都市', 'えびの市', '三股町', '高原町', '国富町', '綾町', '高鍋町', '新富町', '西米良村', '木城町', '川南町', '都農町', '門川町', '諸塚村', '椎葉村', '美郷町', '日之影町', '五ヶ瀬町'];
        break;
      case '鹿児島県':
        cities = ['鹿児島市', '鹿屋市', '枕崎市', '阿久根市', '出水市', '指宿市', '西之表市', '垂水市', '薩摩川内市', '日置市', '曽於市', '霧島市', 'いちき串木野市', '南さつま市', '志布志市', '奄美市', '南九州市', '伊佐市', '姶良市', '三島村', '十島村', 'さつま町', '長島町', '湧水町', '大崎町', '東串良町', '錦江町', '南大隅町', '肝付町', '中種子町', '南種子町', '屋久島町', '大和村', '宇検村', '瀬戸内町', '龍郷町', '喜界町', '徳之島町', '天城町', '伊仙町', '和泊町', '知名町', '与論町'];
        break;
      case '沖縄県':
        cities = ['那覇市', '宜野湾市', '石垣市', '浦添市', '名護市', '糸満市', '沖縄市', '豊見城市', 'うるま市', '宮古島市', '南城市', '国頭村', '大宜味村', '東村', '今帰仁村', '本部町', '恩納村', '宜野座村', '金武町', '伊江村', '読谷村', '嘉手納町', '北谷町', '北中城村', '中城村', '西原町', '与那原町', '南風原町', '渡嘉敷村', '座間味村', '粟国村', '渡名喜村', '南大東村', '北大東村', '伊平屋村', '伊是名村', '久米島町', '八重瀬町', '多良間村', '竹富町', '与那国町'];
        break;
      default:
        cities = ['その他市町村1', 'その他市町村2', 'その他市町村3'];
    }

    setState(() {
      _cities = cities;
      _isLoadingCities = false;
    });
  }

  void _parseAddressToFields(String address) {
    String remaining = address;
    String? matchedPrefecture;
    for (final prefecture in _prefectures) {
      if (remaining.startsWith(prefecture)) {
        matchedPrefecture = prefecture;
        remaining = remaining.substring(prefecture.length);
        break;
      }
    }

    if (matchedPrefecture != null) {
      _selectedPrefecture = matchedPrefecture;
      _loadFallbackCities(matchedPrefecture);
      String? matchedCity;
      for (final city in _cities) {
        if (remaining.startsWith(city)) {
          matchedCity = city;
          remaining = remaining.substring(city.length);
          break;
        }
      }
      _selectedCity = matchedCity;
    }

    _addressController.text = remaining.trim();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveStoreData() async {
    final isValid = _formKey.currentState!.validate();
    final hasLocation = _selectedLatitude != null && _selectedLongitude != null;
    if (mounted) {
      setState(() {
        _hasFormError = !(isValid && hasLocation);
      });
    } else {
      _hasFormError = !(isValid && hasLocation);
    }
    if (!isValid || !hasLocation) return;

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

      final combinedAddress =
          '${_selectedPrefecture ?? ''}${_selectedCity ?? ''}${_addressController.text.trim()}';

      // Firestoreに保存
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(_selectedStoreId)
          .update({
        'name': _nameController.text.trim(),
        'businessType': _businessType,
        'businessName': _businessNameController.text.trim(),
        'category': _selectedCategory,
        'subCategory': _selectedSubCategory,
        'address': combinedAddress,
        'phone': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isRegularHoliday': _isRegularHoliday,
        'businessHours': _businessHours,
        'socialMedia': {
          'instagram': _instagramController.text.trim(),
          'x': _xController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'website': _websiteController.text.trim(),
        },
        'tags': _tags,
        'location': {
          'latitude': _selectedLatitude ?? 0.0,
          'longitude': _selectedLongitude ?? 0.0,
        },
        'iconImageUrl': iconImageUrl,
        'storeImageUrl': storeImageUrl,
        'facilityInfo': {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CommonHeader(title: '店舗プロフィール編集'),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const CommonHeader(title: '店舗プロフィール編集'),
      body: DismissKeyboard(
        child: SingleChildScrollView(
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
                  CustomTextField(
                    controller: _nameController,
                    labelText: '店舗名 *',
                    hintText: '例：カフェ・ド・パリ',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '店舗名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildBusinessTypeSection(),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _businessNameController,
                    labelText: _businessType == 'corporate' ? '法人名 *' : '代表者名 *',
                    hintText: _businessType == 'corporate'
                        ? '例：株式会社ぐるまっぷ'
                        : '例：山田 太郎',
                    maxLength: 100,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _businessType == 'corporate'
                            ? '法人名を入力してください'
                            : '代表者名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'カテゴリ *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    hint: const Text('選択してください'),
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
                      setState(() {
                        _selectedCategory = newValue;
                        if (_selectedSubCategory == _selectedCategory) {
                          _selectedSubCategory = null;
                        }
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
                  DropdownButtonFormField<String>(
                    value: _selectedSubCategory,
                    decoration: const InputDecoration(
                      labelText: 'サブカテゴリ（任意）',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    hint: const Text('選択してください'),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    items: _subCategories.map((String category) => 
                      DropdownMenuItem<String>(
                        value: category, 
                        child: Text(category),
                      ),
                    ).toList(),
                    onChanged: (String? newValue) {
                      setState(() => _selectedSubCategory = newValue);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '住所',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPrefecture,
                    decoration: const InputDecoration(
                      labelText: '都道府県 *',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: _prefectures.map((String prefecture) {
                      return DropdownMenuItem<String>(
                        value: prefecture,
                        child: Text(prefecture),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPrefecture = newValue;
                        _selectedCity = null;
                        _cities = [];
                      });
                      if (newValue != null) {
                        _loadCitiesForPrefecture(newValue);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '都道府県を選択してください';
                      }
                      return null;
                    },
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
                        suffixIcon: _isLoadingCities
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      items: _cities.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: _isLoadingCities ? null : (String? newValue) {
                        setState(() {
                          _selectedCity = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '市区町村を選択してください';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _addressController,
                    labelText: '以下の住所 *',
                    hintText: '例：渋谷1-1-1',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '以下の住所を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    labelText: '電話番号 *',
                    hintText: '例：0312345678',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '電話番号を入力してください';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(value)) {
                      return 'ハイフンなしの数字のみで入力してください';
                    }
                    return null;
                  },
                ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _descriptionController,
                    labelText: '店舗説明 *',
                    hintText: '店舗の特徴や魅力を入力してください',
                    maxLines: 4,
                    maxLength: 150,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '店舗説明を入力してください';
                      }
                      if (value.length > 150) {
                        return '店舗説明は150文字以内で入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLocationSection(),
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

              // 座席数セクション
              _buildSeatingSection(),

              const SizedBox(height: 24),

              // 設備・サービスセクション
              _buildFacilityInfoSection(),

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
              const SizedBox(height: 16),
              if (_hasFormError)
                const Text(
                  '入力不備があります。内容をご確認ください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              if (_hasFormError) const SizedBox(height: 16),
              ],
            ),
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

  Widget _buildImageSection() {
    return _buildSection(
      title: '店舗画像',
      children: [
        // アイコン画像
        _buildStoreIconField(),
        
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
                labelText: '緯度 *',
                hintText: '例：35.6581',
                keyboardType: TextInputType.number,
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '緯度を選択してください';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _longitudeController,
                labelText: '経度 *',
                hintText: '例：139.7017',
                keyboardType: TextInputType.number,
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '経度を選択してください';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: '地図を開く',
            onPressed: _openLocationPicker,
          ),
        ),
      ],
    );
  }

  Widget _buildStoreIconField() {
    const double iconPreviewSize = 96;
    final bool hasImage = _selectedIconImage != null || (_currentIconImageUrl?.isNotEmpty ?? false);
    Widget child;
    if (_selectedIconImage != null) {
      child = Image.memory(
        _selectedIconImage!,
        width: iconPreviewSize,
        height: iconPreviewSize,
        fit: BoxFit.cover,
      );
    } else if (_currentIconImageUrl != null && _currentIconImageUrl!.isNotEmpty) {
      child = Image.network(
        _currentIconImageUrl!,
        width: iconPreviewSize,
        height: iconPreviewSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultStoreIconPreview(iconPreviewSize);
        },
      );
    } else {
      child = _buildDefaultStoreIconPreview(iconPreviewSize);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '店舗アイコン',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        IconImagePickerField(
          size: iconPreviewSize,
          child: child,
          onTap: _pickIconImage,
          onRemove: _removeIconImage,
          showRemove: hasImage,
          backgroundColor: Colors.grey[100]!,
          borderColor: Colors.grey[300]!,
        ),
      ],
    );
  }

  Widget _buildDefaultStoreIconPreview(double size) {
    final category = _selectedCategory ?? 'その他';
    final baseColor = _getDefaultStoreColor(category);
    return Container(
      width: size,
      height: size,
      color: baseColor.withOpacity(0.1),
      alignment: Alignment.center,
      child: Icon(
        _getDefaultStoreIcon(category),
        color: baseColor,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildImageField({
    required String label,
    String? currentImageUrl,
    Uint8List? selectedImage,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    bool useDefaultIcon = false,
  }) {
    const double iconPreviewSize = 96;
    Widget buildCircularFallbackIcon() {
      final category = _selectedCategory ?? 'その他';
      final baseColor = _getDefaultStoreColor(category);
      return Container(
        color: baseColor.withOpacity(0.1),
        alignment: Alignment.center,
        child: Icon(
          _getDefaultStoreIcon(category),
          color: baseColor,
          size: 40,
        ),
      );
    }
    Widget buildCircularImage(Widget image) {
      return Center(
        child: Container(
          width: iconPreviewSize,
          height: iconPreviewSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipOval(child: image),
        ),
      );
    }
    Widget buildCircularPreview(Widget image) {
      return Center(
        child: SizedBox(
          width: iconPreviewSize,
          height: iconPreviewSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              buildCircularImage(image),
              Positioned(
                top: -2,
                right: -2,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            height: useDefaultIcon ? 120 : null,
            decoration: BoxDecoration(
              color: useDefaultIcon ? Colors.transparent : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: useDefaultIcon ? null : Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: useDefaultIcon
                  ? _buildImageContent(
                      useDefaultIcon: useDefaultIcon,
                      selectedImage: selectedImage,
                      currentImageUrl: currentImageUrl,
                      onPick: onPick,
                      onRemove: onRemove,
                      buildCircularPreview: buildCircularPreview,
                      buildCircularFallbackIcon: buildCircularFallbackIcon,
                      iconPreviewSize: iconPreviewSize,
                    )
                  : AspectRatio(
                      aspectRatio: 2 / 1,
                      child: _buildImageContent(
                        useDefaultIcon: useDefaultIcon,
                        selectedImage: selectedImage,
                        currentImageUrl: currentImageUrl,
                        onPick: onPick,
                        onRemove: onRemove,
                        buildCircularPreview: buildCircularPreview,
                        buildCircularFallbackIcon: buildCircularFallbackIcon,
                        iconPreviewSize: iconPreviewSize,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent({
    required bool useDefaultIcon,
    required Uint8List? selectedImage,
    required String? currentImageUrl,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    required Widget Function(Widget image) buildCircularPreview,
    required Widget Function() buildCircularFallbackIcon,
    required double iconPreviewSize,
  }) {
    if (selectedImage != null) {
      return Stack(
        children: [
          useDefaultIcon
              ? buildCircularPreview(
                  Image.memory(
                    selectedImage,
                    width: iconPreviewSize,
                    height: iconPreviewSize,
                    fit: BoxFit.cover,
                  ),
                )
              : Image.memory(
                  selectedImage,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
          if (!useDefaultIcon)
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
                    Icons.remove,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    if (currentImageUrl != null) {
      return Stack(
        children: [
          useDefaultIcon
              ? buildCircularPreview(
                  Image.network(
                    currentImageUrl,
                    width: iconPreviewSize,
                    height: iconPreviewSize,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return buildCircularFallbackIcon();
                    },
                  ),
                )
              : Image.network(
                  currentImageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder(
                      onPick,
                      useDefaultIcon: useDefaultIcon,
                      iconPreviewSize: iconPreviewSize,
                    );
                  },
                ),
          if (!useDefaultIcon)
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
                    Icons.remove,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return _buildImagePlaceholder(onPick, useDefaultIcon: useDefaultIcon, iconPreviewSize: iconPreviewSize);
  }

  Widget _buildImagePlaceholder(
    VoidCallback onPick, {
    required bool useDefaultIcon,
    required double iconPreviewSize,
  }) {
    if (useDefaultIcon) {
      final category = _selectedCategory ?? 'その他';
      final baseColor = _getDefaultStoreColor(category);
      return SizedBox(
        width: double.infinity,
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconPreviewSize,
              height: iconPreviewSize,
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: baseColor.withOpacity(0.3)),
              ),
              child: Icon(
                _getDefaultStoreIcon(category),
                color: baseColor,
                size: iconPreviewSize * 0.5,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const ImagePickerPlaceholder(
        aspectRatio: 2 / 1,
      ),
    );
  }

  Widget _buildBusinessHoursSection() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayNames = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];
    final isEnabled = !_isRegularHoliday;

    return _buildSection(
      title: '営業時間',
      children: [
        Row(
          children: [
            Checkbox(
              value: _isRegularHoliday,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _isRegularHoliday = value;
                });
              },
              activeColor: const Color(0xFFFF6B35),
            ),
            const Text(
              '不定休',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
                  onChanged: isEnabled ? (value) {
                    setState(() {
                      _businessHours[day]!['isOpen'] = value ?? false;
                    });
                  } : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: dayData['open'],
                          enabled: isEnabled && dayData['isOpen'],
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
                          enabled: isEnabled && dayData['isOpen'],
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
                labelText: 'X',
                hintText: '例：https://x.com/username',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _facebookController,
          labelText: 'Facebook',
          hintText: '例：https://facebook.com/username',
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return FormField<void>(
      validator: (_) {
        if (_tags.isEmpty) {
          return 'タグを1つ以上追加してください';
        }
        return null;
      },
      builder: (state) {
        return _buildSection(
          title: 'タグ *',
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: '例：カフェ、本屋、Wi-Fi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onFieldSubmitted: (_) => _addTag(),
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
            if (state.hasError) ...[
              const SizedBox(height: 8),
              Text(
                state.errorText ?? '',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
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
      },
    );
  }

  Widget _buildSeatingRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('席', style: TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSeatingSection() {
    return _buildSection(
      title: '座席数',
      children: [
        _buildSeatingRow('カウンター席', _counterSeatsController),
        _buildSeatingRow('テーブル席', _tableSeatsController),
        _buildSeatingRow('座敷席', _tatamiSeatsController),
        _buildSeatingRow('テラス席', _terraceSeatsController),
        _buildSeatingRow('個室', _privateRoomSeatsController),
        _buildSeatingRow('ソファー席', _sofaSeatsController),
      ],
    );
  }

  Widget _buildFacilityInfoSection() {
    return _buildSection(
      title: '設備・サービス',
      children: [
        // 駐車場
        const Text(
          '駐車場',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _parkingOption,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'none', child: Text('なし')),
            DropdownMenuItem(value: 'available', child: Text('あり')),
            DropdownMenuItem(value: 'nearby_coin_parking', child: Text('近隣にコインパーキングあり')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _parkingOption = value);
            }
          },
        ),
        const SizedBox(height: 16),

        // 最寄り駅・アクセス情報
        CustomTextField(
          controller: _accessInfoController,
          labelText: '最寄り駅・アクセス',
          hintText: '例：渋谷駅から徒歩5分',
        ),
        const SizedBox(height: 16),

        // テイクアウト対応
        SwitchListTile(
          title: const Text('テイクアウト対応'),
          value: _hasTakeout,
          activeColor: const Color(0xFFFF6B35),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() => _hasTakeout = value);
          },
        ),

        // 禁煙・喫煙情報
        const Text(
          '禁煙・喫煙',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _smokingPolicy,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'no_smoking', child: Text('全席禁煙')),
            DropdownMenuItem(value: 'separated', child: Text('分煙')),
            DropdownMenuItem(value: 'smoking_allowed', child: Text('喫煙可')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _smokingPolicy = value);
            }
          },
        ),
        const SizedBox(height: 16),

        // Wi-Fi
        SwitchListTile(
          title: const Text('Wi-Fi'),
          value: _hasWifi,
          activeColor: const Color(0xFFFF6B35),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() => _hasWifi = value);
          },
        ),

        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'その他の対応',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // バリアフリー対応
        SwitchListTile(
          title: const Text('バリアフリー対応'),
          value: _isBarrierFree,
          activeColor: const Color(0xFFFF6B35),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() => _isBarrierFree = value);
          },
        ),

        // 子連れ対応
        SwitchListTile(
          title: const Text('子連れ対応'),
          value: _isChildFriendly,
          activeColor: const Color(0xFFFF6B35),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() => _isChildFriendly = value);
          },
        ),

        // ペット同伴可
        SwitchListTile(
          title: const Text('ペット同伴可'),
          value: _isPetFriendly,
          activeColor: const Color(0xFFFF6B35),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() => _isPetFriendly = value);
          },
        ),
      ],
    );
  }

  Widget _buildBusinessTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '経営形態 *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('個人事業'),
                value: 'individual',
                groupValue: _businessType,
                activeColor: const Color(0xFFFF6B35),
                onChanged: (value) {
                  setState(() {
                    _businessType = value!;
                    _businessNameController.clear();
                  });
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text('法人'),
                value: 'corporate',
                groupValue: _businessType,
                activeColor: const Color(0xFFFF6B35),
                onChanged: (value) {
                  setState(() {
                    _businessType = value!;
                    _businessNameController.clear();
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
