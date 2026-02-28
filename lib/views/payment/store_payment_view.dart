import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/point_request_provider.dart';
import '../../models/point_request_model.dart';
import '../../widgets/custom_button.dart';
import '../user/point_request_confirmation_view.dart';
import '../main_navigation_view.dart';

class StorePaymentView extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final int usedPoints;
  final List<String> selectedCouponIds;
  final List<String> selectedSpecialCouponIds;

  const StorePaymentView({
    Key? key,
    required this.userId,
    required this.userName,
    this.usedPoints = 0,
    this.selectedCouponIds = const [],
    this.selectedSpecialCouponIds = const [],
  }) : super(key: key);

  @override
  ConsumerState<StorePaymentView> createState() => _StorePaymentViewState();
}

class _StorePaymentViewState extends ConsumerState<StorePaymentView> {
  String _amount = '0';
  bool _isProcessing = false;
  String _actualUserName = 'お客様';
  bool _isLoadingUserInfo = true;
  String? _profileImageUrl;
  String _storeName = '店舗名';
  bool _isLoadingStoreInfo = true;
  String? _currentRequestId;

  @override
  void initState() {
    super.initState();
    print('StorePaymentView: 初期化完了 - userId: ${widget.userId}, userName: ${_isLoadingUserInfo ? '読み込み中...' : _actualUserName}');
    _loadUserInfo();
    _loadStoreInfo();
  }

  /// ユーザー情報を読み込み
  Future<void> _loadUserInfo() async {
    try {
      print('ユーザー情報取得開始: userId=${widget.userId}');
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data()!;
        print('ユーザーデータ取得: $userData');
        
        // 安全にデータを取得
        String displayName = 'お客様'; // デフォルト値
        
        // displayNameを安全に取得
        if (userData.containsKey('displayName') && userData['displayName'] is String) {
          displayName = userData['displayName'] as String;
        } else if (userData.containsKey('email') && userData['email'] is String) {
          displayName = userData['email'] as String;
        } else if (userData.containsKey('name') && userData['name'] is String) {
          displayName = userData['name'] as String;
        }
        
        // 空文字列の場合はデフォルト値を使用
        if (displayName.isEmpty) {
          displayName = 'お客様';
        }
        
        // プロフィール画像URLを取得
        String? profileImageUrl;
        if (userData.containsKey('profileImageUrl') && userData['profileImageUrl'] is String) {
          profileImageUrl = userData['profileImageUrl'] as String;
        }
        
        setState(() {
          _actualUserName = displayName;
          _profileImageUrl = profileImageUrl;
          _isLoadingUserInfo = false;
        });

        print('ユーザー情報を取得しました: $displayName');
      } else {
        print('ユーザードキュメントが存在しません');
        setState(() {
          _actualUserName = 'お客様';
          _isLoadingUserInfo = false;
        });
      }
    } catch (e) {
      print('ユーザー情報取得エラー: $e');
      print('エラーの詳細: ${e.toString()}');
      
      if (mounted) {
        setState(() {
          _actualUserName = 'お客様';
          _isLoadingUserInfo = false;
        });
      }
    }
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _consumeSelectedCoupons({required String storeId}) async {
    if (widget.selectedCouponIds.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    await firestore.runTransaction((txn) async {
      for (final couponId in widget.selectedCouponIds) {
        final couponRef = firestore
            .collection('coupons')
            .doc(storeId)
            .collection('coupons')
            .doc(couponId);
        final publicCouponRef =
            firestore.collection('public_coupons').doc(couponId);
        final usedByRef = couponRef
            .collection('usedBy')
            .doc(widget.userId);
        final userUsedRef = firestore
            .collection('users')
            .doc(widget.userId)
            .collection('used_coupons')
            .doc(couponId);

        final couponSnap = await txn.get(couponRef);
        if (!couponSnap.exists) {
          throw Exception('クーポンが見つかりません: $couponId');
        }
        final data = couponSnap.data() ?? {};
        final isActive = data['isActive'] as bool? ?? true;
        final validUntil = (data['validUntil'] as Timestamp?)?.toDate();
        final usageLimit = _parseInt(data['usageLimit']);
        final usedCount = _parseInt(data['usedCount']);

        if (!isActive) {
          throw Exception('クーポンが無効です: $couponId');
        }
        if (validUntil == null || !validUntil.isAfter(now)) {
          throw Exception('クーポンの有効期限が切れています: $couponId');
        }
        if (usedCount >= usageLimit) {
          throw Exception('クーポンの上限に達しています: $couponId');
        }

        final usedBySnap = await txn.get(usedByRef);
        if (usedBySnap.exists) {
          throw Exception('このクーポンは既に使用済みです: $couponId');
        }

        txn.set(usedByRef, {
          'userId': widget.userId,
          'usedAt': FieldValue.serverTimestamp(),
          'couponId': couponId,
          'storeId': storeId,
        });
        txn.set(userUsedRef, {
          'userId': widget.userId,
          'usedAt': FieldValue.serverTimestamp(),
          'couponId': couponId,
          'storeId': storeId,
        });
        final nextUsedCount = usedCount + 1;
        final shouldDeactivate = usageLimit > 0 && nextUsedCount == usageLimit;
        txn.update(couponRef, {
          'usedCount': nextUsedCount,
          if (shouldDeactivate) 'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final publicSnap = await txn.get(publicCouponRef);
        if (publicSnap.exists) {
          txn.update(publicCouponRef, {
            'usedCount': nextUsedCount,
            if (shouldDeactivate) 'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<void> _consumeSpecialCoupons() async {
    if (widget.selectedSpecialCouponIds.isEmpty) return;
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    for (final userCouponId in widget.selectedSpecialCouponIds) {
      final ref = firestore.collection('user_coupons').doc(userCouponId);
      batch.update(ref, {
        'isUsed': true,
        'usedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// 店舗情報を読み込み
  Future<void> _loadStoreInfo() async {
    try {
      print('店舗情報取得開始');
      
      // 現在の店舗ユーザーを取得
      final authState = ref.read(authStateProvider);
      final storeUser = authState.value;
      
      if (storeUser == null) {
        print('店舗ユーザーが認証されていません');
        setState(() {
          _storeName = '未認証店舗';
          _isLoadingStoreInfo = false;
        });
        return;
      }

      print('店舗ユーザーID: ${storeUser.uid}');
      
      // まずusersコレクションから店舗情報を取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(storeUser.uid)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data()!;
        print('ユーザーデータから店舗情報を取得: $userData');
        
        // ユーザーデータから店舗名を取得
        String storeName = '店舗名';
        if (userData.containsKey('displayName') && userData['displayName'] is String) {
          storeName = userData['displayName'] as String;
        } else if (userData.containsKey('email') && userData['email'] is String) {
          final email = userData['email'] as String;
          storeName = '${email.split('@')[0]}店';
        }
        
        setState(() {
          _storeName = storeName;
          _isLoadingStoreInfo = false;
        });
        
        print('ユーザーデータから店舗情報を取得しました: $storeName');
        return;
      }
      
      // どちらにも見つからない場合
      print('店舗ドキュメントが存在しません');
      setState(() {
        _storeName = '店舗名未設定';
        _isLoadingStoreInfo = false;
      });
    } catch (e) {
      print('店舗情報取得エラー: $e');
      print('エラーの詳細: ${e.toString()}');
      
      if (mounted) {
        setState(() {
          _storeName = 'エラー';
          _isLoadingStoreInfo = false;
        });
      }
    }
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_amount == '0') {
        _amount = number;
      } else {
        _amount += number;
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      _amount = '0';
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  void _onPointAwardPressed() {
    final amount = int.tryParse(_amount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('有効な金額を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showPointAwardConfirmation(amount);
  }

  void _showPointAwardConfirmation(int amount) {
    const pointsToAward = 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, size: 64, color: Color(0xFFFF6B35)),
            const SizedBox(height: 16),
            Text('${_isLoadingUserInfo ? '読み込み中...' : _actualUserName}さん'),
            const SizedBox(height: 8),
            Text('${amount.toString()}円分のポイント付与をリクエストしますか？'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    '付与予定ポイント: ${pointsToAward}pt',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '送信後すぐにポイントを付与します',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createPointRequest(amount, pointsToAward);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('リクエスト送信'),
          ),
        ],
      ),
    );
  }

  void _createPointRequest(int amount, int pointsToAward) async {
    print('=== _createPointRequest 開始 ===');
    print('引数: amount=$amount, pointsToAward=$pointsToAward');
    print('利用ポイント: ${widget.usedPoints}');
    
    setState(() {
      _isProcessing = true;
    });

    try {
      print('ステップ1: 認証状態の確認');
      // 現在の店舗ユーザーを取得
      final authState = ref.read(authStateProvider);
      print('認証状態: $authState');
      
      final storeUser = authState.value;
      print('店舗ユーザー: $storeUser');
      
      if (storeUser == null) {
        throw Exception('店舗の認証情報が取得できませんでした');
      }

      print('ステップ2: 店舗ユーザーのドキュメント取得');
      // 店舗ユーザーのcurrentStoreIdを取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(storeUser.uid)
          .get();

      print('ユーザードキュメント存在: ${userDoc.exists}');
      print('ユーザードキュメントID: ${userDoc.id}');

      if (!userDoc.exists) {
        throw Exception('店舗ユーザーの情報が取得できませんでした');
      }

      final userData = userDoc.data()!;
      print('ユーザーデータ: $userData');
      
      final currentStoreId = userData['currentStoreId'] as String?;
      print('currentStoreId: $currentStoreId');
      
      if (currentStoreId == null || currentStoreId.isEmpty) {
        throw Exception('現在選択中の店舗がありません');
      }

      print('ステップ3: 店舗名の取得');
      // 店舗名を取得
      String storeName = '店舗名';
      try {
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(currentStoreId)
            .get();
        
        print('店舗ドキュメント存在: ${storeDoc.exists}');
        print('店舗ドキュメントID: ${storeDoc.id}');
        
        if (storeDoc.exists) {
          final storeData = storeDoc.data()!;
          print('店舗データ: $storeData');
          
          if (storeData.containsKey('name') && storeData['name'] is String) {
            storeName = storeData['name'] as String;
            print('店舗名取得成功: $storeName');
          } else {
            print('店舗名フィールドが見つからないか、文字列ではない');
          }
        } else {
          print('店舗ドキュメントが存在しません');
        }
      } catch (e) {
        print('店舗名取得エラー: $e');
        print('店舗名取得エラーの詳細: ${e.toString()}');
        // エラーの場合はデフォルト値を使用
      }

      print('ステップ4: リクエスト作成パラメータ');
      print('userId: ${widget.userId}');
      print('storeId: $currentStoreId');
      print('storeName: $storeName');
      print('amount: $amount');
      print('pointsToAward: $pointsToAward');

      print('ステップ4.5: クーポン使用処理');
      await _consumeSelectedCoupons(storeId: currentStoreId);
      await _consumeSpecialCoupons();

      print('ステップ5: ポイント付与リクエストの作成');
      // ポイント付与リクエストを作成
      final requestNotifier = ref.read(pointRequestProvider.notifier);
      print('リクエストNotifier取得完了');
      
      final requestId = await requestNotifier.createPointRequest(
        userId: widget.userId,
        storeId: currentStoreId,
        storeName: storeName,
        amount: amount,
        pointsToAward: pointsToAward,
        userPoints: pointsToAward, // ユーザーに付与されるポイント
        description: '店舗からのポイント付与リクエスト',
        usedPoints: widget.usedPoints,
        selectedCouponIds: widget.selectedCouponIds,
      );

      print('リクエスト作成結果: $requestId');

      if (requestId != null) {
        print('リクエスト作成成功');
        setState(() {
          _currentRequestId = requestId; // 新しいID形式: "storeId_userId"
        });
        
        final approved = await _approveRequestAfterRateCalculated(
          requestId: requestId,
          storeId: currentStoreId,
          userId: widget.userId,
          requestNotifier: requestNotifier,
        );
        if (approved) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PointRequestConfirmationView(requestId: requestId),
              ),
            );
          }
        } else {
          throw Exception('ポイント付与の承認に失敗しました');
        }
      } else {
        print('リクエスト作成失敗: requestIdがnull');
        throw Exception('ポイント付与リクエストの作成に失敗しました');
      }
    } catch (e, stackTrace) {
      print('=== エラー発生 ===');
      print('エラータイプ: ${e.runtimeType}');
      print('エラーメッセージ: $e');
      print('エラーの詳細: ${e.toString()}');
      print('スタックトレース: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ポイント付与リクエストの作成に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      print('=== _createPointRequest 終了 ===');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool> _approveRequestAfterRateCalculated({
    required String requestId,
    required String storeId,
    required String userId,
    required PointRequestNotifier requestNotifier,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('point_requests')
        .doc(storeId)
        .collection(userId)
        .doc('award_request');

    final start = DateTime.now();
    const timeout = Duration(seconds: 10);
    while (DateTime.now().difference(start) < timeout) {
      final snap = await docRef.get();
      if (!snap.exists) break;
      final data = snap.data() as Map<String, dynamic>;
      if (data['rateCalculatedAt'] != null) {
        final convertedData = Map<String, dynamic>.from(data);
        _convertTimestampFields(convertedData, ['createdAt', 'respondedAt', 'rateCalculatedAt']);
        final request = PointRequest.fromJson({
          'id': requestId,
          'userId': userId,
          'storeId': storeId,
          ...convertedData,
        });
        return requestNotifier.acceptPointRequestAsStore(request);
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    throw Exception('ポイント計算が完了していません。少し待ってから再試行してください。');
  }

  void _convertTimestampFields(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) {
        data[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        data[key] = value.toIso8601String();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('支払い金額入力'),
            if (_isLoadingStoreInfo)
              const Text(
                '店舗情報読み込み中...',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              )
            else
              Text(
                _storeName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // お会計入力の案内
          _buildPaymentPrompt(),
          
          // 金額表示セクション
          _buildAmountDisplay(),
          
          // 電卓セクション
          Expanded(
            child: _buildCalculator(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '今回の${_isLoadingUserInfo ? 'お客様' : _actualUserName}様のお会計金額を入力してください。',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            '支払い金額',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_amount}円',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCalculator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 数字ボタン行1
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('1'),
                _buildNumberButton('2'),
                _buildNumberButton('3'),
              ],
            ),
          ),
          // 数字ボタン行2
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('4'),
                _buildNumberButton('5'),
                _buildNumberButton('6'),
              ],
            ),
          ),
          // 数字ボタン行3
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('7'),
                _buildNumberButton('8'),
                _buildNumberButton('9'),
              ],
            ),
          ),
          // 数字ボタン行4
          Expanded(
            child: Row(
              children: [
                _buildActionButton('C', _onClearPressed, Colors.red),
                _buildNumberButton('0'),
                _buildActionButton('⌫', _onBackspacePressed, Colors.orange),
              ],
            ),
          ),
          // 確定ボタン
          const SizedBox(height: 16),
          CustomButton(
            text: '確定',
            onPressed: _isProcessing ? null : _onPointAwardPressed,
            isLoading: _isProcessing,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => _onNumberPressed(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
