import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// バッジ作成状態管理
class BadgeCreateState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String? imageUrl;
  final File? selectedImage;
  final Uint8List? webImageBytes;

  const BadgeCreateState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.imageUrl,
    this.selectedImage,
    this.webImageBytes,
  });

  BadgeCreateState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? imageUrl,
    File? selectedImage,
    Uint8List? webImageBytes,
  }) {
    return BadgeCreateState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      imageUrl: imageUrl ?? this.imageUrl,
      selectedImage: selectedImage ?? this.selectedImage,
      webImageBytes: webImageBytes ?? this.webImageBytes,
    );
  }
}

// バッジ作成フォーム状態
class BadgeFormData {
  final String name;
  final String description;
  final String rarity;
  final String category;
  final bool isActive;
  final int order;
  final int requiredValue;
  final String conditionMode; // 'typed' or 'jsonlogic'
  final String conditionType; // for typed mode
  final Map<String, dynamic> conditionParams; // for typed mode
  final String jsonLogicCondition; // for jsonlogic mode

  const BadgeFormData({
    this.name = '',
    this.description = '',
    this.rarity = 'bronze',
    this.category = 'basic',
    this.isActive = true,
    this.order = 0,
    this.requiredValue = 0,
    this.conditionMode = 'typed',
    this.conditionType = '',
    this.conditionParams = const {},
    this.jsonLogicCondition = '',
  });

  BadgeFormData copyWith({
    String? name,
    String? description,
    String? rarity,
    String? category,
    bool? isActive,
    int? order,
    int? requiredValue,
    String? conditionMode,
    String? conditionType,
    Map<String, dynamic>? conditionParams,
    String? jsonLogicCondition,
  }) {
    return BadgeFormData(
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      requiredValue: requiredValue ?? this.requiredValue,
      conditionMode: conditionMode ?? this.conditionMode,
      conditionType: conditionType ?? this.conditionType,
      conditionParams: conditionParams ?? this.conditionParams,
      jsonLogicCondition: jsonLogicCondition ?? this.jsonLogicCondition,
    );
  }

  // バリデーション
  bool get isValid {
    if (name.trim().isEmpty || description.trim().isEmpty) return false;
    
    if (conditionMode == 'typed') {
      return conditionType.isNotEmpty;
    } else if (conditionMode == 'jsonlogic') {
      return jsonLogicCondition.trim().isNotEmpty && _isValidJson(jsonLogicCondition);
    }
    
    return false;
  }

  bool _isValidJson(String jsonString) {
    try {
      json.decode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Firestore用の条件オブジェクトを生成
  Map<String, dynamic> get conditionData {
    if (conditionMode == 'typed') {
      return {
        'mode': 'typed',
        'rule': {
          'type': conditionType,
          'params': conditionParams,
        }
      };
    } else {
      return {
        'mode': 'jsonlogic',
        'rule': json.decode(jsonLogicCondition),
      };
    }
  }
}

// バッジ作成プロバイダー
final badgeCreateProvider = StateNotifierProvider<BadgeCreateNotifier, BadgeCreateState>((ref) {
  return BadgeCreateNotifier();
});

// バッジフォームプロバイダー
final badgeFormProvider = StateNotifierProvider<BadgeFormNotifier, BadgeFormData>((ref) {
  return BadgeFormNotifier();
});

// バッジ作成Notifier
class BadgeCreateNotifier extends StateNotifier<BadgeCreateState> {
  BadgeCreateNotifier() : super(const BadgeCreateState());

  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 画像選択
  Future<void> pickImage() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          // Webプラットフォーム用の処理
          final bytes = await image.readAsBytes();
          const maxSize = 5 * 1024 * 1024; // 5MB
          
          if (bytes.length > maxSize) {
            state = state.copyWith(
              isLoading: false,
              error: '画像ファイルが大きすぎます。5MB以下のファイルを選択してください。',
            );
            return;
          }
          
          state = state.copyWith(
            webImageBytes: bytes,
            selectedImage: null,
            isLoading: false,
            error: null,
          );
        } else {
          // モバイルプラットフォーム用の処理
          final file = File(image.path);
          final fileSize = await file.length();
          const maxSize = 5 * 1024 * 1024; // 5MB
          
          if (fileSize > maxSize) {
            state = state.copyWith(
              isLoading: false,
              error: '画像ファイルが大きすぎます。5MB以下のファイルを選択してください。',
            );
            return;
          }
          
          state = state.copyWith(
            selectedImage: file,
            webImageBytes: null,
            isLoading: false,
            error: null,
          );
        }
      } else {
        // ユーザーがキャンセルした場合
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      String errorMessage = '画像の選択に失敗しました';
      
      if (e.toString().contains('Permission denied')) {
        errorMessage = '画像へのアクセス権限がありません。設定で権限を許可してください。';
      } else if (e.toString().contains('No such file')) {
        errorMessage = '選択された画像ファイルが見つかりません。';
      } else if (e.toString().contains('Invalid image')) {
        errorMessage = '無効な画像ファイルです。別の画像を選択してください。';
      } else if (e.toString().contains('Not supported')) {
        errorMessage = 'このブラウザでは画像選択がサポートされていません。Chrome、Firefox、Safariをお試しください。';
      } else {
        errorMessage = '画像の選択に失敗しました: $e';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  // 画像アップロード
  Future<String?> uploadImage(String badgeId) async {
    if (state.selectedImage == null && state.webImageBytes == null) return null;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final ref = _storage.ref().child('badges/$badgeId/image.png');
      
      if (kIsWeb && state.webImageBytes != null) {
        // Webプラットフォーム用の処理
        final uploadTask = ref.putData(state.webImageBytes!);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        state = state.copyWith(
          imageUrl: downloadUrl,
          isLoading: false,
        );

        return downloadUrl;
      } else if (state.selectedImage != null) {
        // モバイルプラットフォーム用の処理
        final uploadTask = ref.putFile(state.selectedImage!);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        state = state.copyWith(
          imageUrl: downloadUrl,
          isLoading: false,
        );

        return downloadUrl;
      } else {
        throw Exception('画像が選択されていません');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '画像のアップロードに失敗しました: $e',
      );
      return null;
    }
  }

  // バッジ保存
  Future<bool> saveBadge(BadgeFormData formData, String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // バッジIDを生成
      final badgeId = _firestore.collection('badges').doc().id;

      // 画像をアップロード（選択されている場合）
      String? imageUrl;
      if (state.selectedImage != null || state.webImageBytes != null) {
        imageUrl = await uploadImage(badgeId);
        if (imageUrl == null) {
          state = state.copyWith(
            isLoading: false,
            error: '画像のアップロードに失敗しました',
          );
          return false;
        }
      }

      // 条件データをFirestore用に変換
      Map<String, dynamic> conditionData;
      if (formData.conditionMode == 'jsonlogic') {
        // JSON Logicモードの場合、JSON文字列をパースしてオブジェクトに変換
        try {
          conditionData = json.decode(formData.jsonLogicCondition);
        } catch (e) {
          state = state.copyWith(
            isLoading: false,
            error: 'JSON Logicの形式が正しくありません: $e',
          );
          return false;
        }
      } else {
        // 基本モードの場合、既存のconditionDataを使用
        conditionData = formData.conditionData;
      }

      // バッジデータを保存
      await _firestore.collection('badges').doc(badgeId).set({
        'name': formData.name.trim(),
        'description': formData.description.trim(),
        'rarity': formData.rarity,
        'category': formData.category,
        'isActive': formData.isActive,
        'order': formData.order,
        'requiredValue': formData.requiredValue,
        'imageUrl': imageUrl,
        'condition': conditionData,
        'conditionVersion': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': userId,
      });

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        error: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'バッジの保存に失敗しました: $e',
      );
      return false;
    }
  }

  // 状態リセット
  void reset() {
    state = const BadgeCreateState();
  }

  // エラークリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// バッジフォームNotifier
class BadgeFormNotifier extends StateNotifier<BadgeFormData> {
  BadgeFormNotifier() : super(const BadgeFormData());

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateRarity(String rarity) {
    state = state.copyWith(rarity: rarity);
  }

  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }

  void updateIsActive(bool isActive) {
    state = state.copyWith(isActive: isActive);
  }

  void updateOrder(int order) {
    state = state.copyWith(order: order);
  }

  void updateRequiredValue(int requiredValue) {
    state = state.copyWith(requiredValue: requiredValue);
  }

  void updateConditionMode(String mode) {
    state = state.copyWith(conditionMode: mode);
  }

  void updateConditionType(String type) {
    state = state.copyWith(conditionType: type);
  }

  void updateConditionParams(Map<String, dynamic> params) {
    state = state.copyWith(conditionParams: params);
  }

  void updateJsonLogicCondition(String condition) {
    state = state.copyWith(jsonLogicCondition: condition);
  }

  void reset() {
    state = const BadgeFormData();
  }
}

// バッジ一覧プロバイダー
final badgesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  try {
    return FirebaseFirestore.instance
        .collection('badges')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();
    }).handleError((error) {
      debugPrint('Error fetching badges: $error');
      return [];
    });
  } catch (e) {
    debugPrint('Error creating badges stream: $e');
    return Stream.value([]);
  }
});

// レア度の選択肢
const List<Map<String, dynamic>> rarityOptions = [
  {'value': 'bronze', 'label': 'ブロンズ', 'color': Color(0xFFCD7F32)},
  {'value': 'silver', 'label': 'シルバー', 'color': Color(0xFFC0C0C0)},
  {'value': 'gold', 'label': 'ゴールド', 'color': Color(0xFFFFD700)},
  {'value': 'platinum', 'label': 'プラチナ', 'color': Color(0xFFE5E4E2)},
];

// カテゴリの選択肢
const List<Map<String, dynamic>> categoryOptions = [
  {'value': 'basic', 'label': '基礎'},
  {'value': 'level_up', 'label': 'レベルアップ'},
  {'value': 'referral', 'label': '紹介'},
  {'value': 'genre', 'label': 'ジャンル別'},
  {'value': 'badge_collection', 'label': 'バッジコレクション'},
  {'value': 'payment_amount', 'label': '支払い額'},
  {'value': 'day_of_week', 'label': '曜日利用'},
  {'value': 'city_usage', 'label': '市利用'},
  {'value': 'regular_store_count', 'label': '常連店舗数'},
  {'value': 'usage_count', 'label': '利用回数'},
];

// 条件タイプの選択肢
const List<Map<String, dynamic>> conditionTypeOptions = [
  {'value': 'points_total', 'label': '累計ポイント', 'params': ['threshold']},
  {'value': 'points_in_period', 'label': '期間内ポイント', 'params': ['threshold', 'period', 'tz']},
  {'value': 'first_checkin', 'label': '初回チェックイン', 'params': []},
  {'value': 'checkins_count', 'label': 'チェックイン回数', 'params': ['threshold', 'period']},
  {'value': 'consecutive_days', 'label': '連続日数', 'params': ['threshold']},
  {'value': 'visit_frequency', 'label': '訪問頻度', 'params': ['threshold', 'period']},
  {'value': 'user_level', 'label': 'レベル', 'params': ['threshold']},
  {'value': 'badge_count', 'label': 'バッジの数', 'params': ['threshold']},
  {'value': 'payment_amount', 'label': '会計金額', 'params': ['threshold', 'period']},
  {'value': 'day_of_week_count', 'label': '曜日ごとの回数', 'params': ['threshold', 'day_of_week', 'period']},
  {'value': 'usage_count', 'label': '利用回数', 'params': ['threshold', 'period']},
  {'value': 'cities_count', 'label': '異なる市での利用', 'params': ['threshold']},
  {'value': 'time_range_usage', 'label': '時間帯利用', 'params': ['threshold', 'start_hour', 'end_hour']},
  {'value': 'monthly_usage', 'label': '月利用', 'params': ['threshold', 'tz']},
  {'value': 'genre_usage', 'label': 'ジャンル別来店回数', 'params': ['threshold', 'genre', 'period', 'tz']},
  {'value': 'same_city_usage', 'label': '同じ市での利用', 'params': ['threshold', 'period', 'tz']},
  {'value': 'same_store_usage', 'label': '同じ店の利用回数', 'params': ['threshold', 'period', 'tz']},
  {'value': 'store_creation_within_months', 'label': '店の作成日から○ヶ月以内に来店', 'params': ['threshold', 'months']},
  {'value': 'regular_store_count', 'label': '常連店舗（スタンプカード10個）数', 'params': ['threshold']},
];

// 期間の選択肢
const List<Map<String, dynamic>> periodOptions = [
  {'value': 'day', 'label': '日'},
  {'value': 'week', 'label': '週'},
  {'value': 'month', 'label': '月'},
  {'value': 'year', 'label': '年'},
  {'value': 'unlimited', 'label': '無期限'},
];

// 曜日の選択肢
const List<Map<String, dynamic>> dayOfWeekOptions = [
  {'value': 'monday', 'label': '月曜日'},
  {'value': 'tuesday', 'label': '火曜日'},
  {'value': 'wednesday', 'label': '水曜日'},
  {'value': 'thursday', 'label': '木曜日'},
  {'value': 'friday', 'label': '金曜日'},
  {'value': 'saturday', 'label': '土曜日'},
  {'value': 'sunday', 'label': '日曜日'},
];

// ジャンル（カテゴリ）の選択肢
const List<Map<String, dynamic>> genreOptions = [
  {'value': 'カフェ', 'label': 'カフェ'},
  {'value': 'レストラン', 'label': 'レストラン'},
  {'value': '居酒屋', 'label': '居酒屋'},
  {'value': 'ファストフード', 'label': 'ファストフード'},
  {'value': 'スイーツ', 'label': 'スイーツ'},
  {'value': 'ラーメン', 'label': 'ラーメン'},
  {'value': '寿司', 'label': '寿司'},
  {'value': '焼肉', 'label': '焼肉'},
  {'value': 'パン', 'label': 'パン'},
  {'value': 'バー', 'label': 'バー'},
  {'value': 'その他', 'label': 'その他'},
];
