import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/point_request_provider.dart';
import '../../models/point_request_model.dart';

class StorePaymentView extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  
  const StorePaymentView({
    Key? key,
    required this.userId,
    required this.userName,
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
  double _pointReturnRate = 1.0; // デフォルト1.0%（100円で1ポイント）

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
        
        // ポイント還元率を取得（お客様の設定値）
        double pointReturnRate = 1.0;
        if (userData.containsKey('pointReturnRate')) {
          if (userData['pointReturnRate'] is num) {
            pointReturnRate = (userData['pointReturnRate'] as num).toDouble();
          }
        }
        
        setState(() {
          _actualUserName = displayName;
          _profileImageUrl = profileImageUrl;
          _pointReturnRate = pointReturnRate;
          _isLoadingUserInfo = false;
        });
        
        print('ユーザー情報を取得しました: $displayName, 還元率: $pointReturnRate%');
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
    final pointsToAward = (amount * _pointReturnRate / 100).floor();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ポイント付与確認'),
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
                    'お客様の確認が必要です',
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
      );

      print('リクエスト作成結果: $requestId');

      if (requestId != null) {
        print('リクエスト作成成功');
        setState(() {
          _currentRequestId = requestId; // 新しいID形式: "storeId_userId"
        });
        
        if (mounted) {
          print('ダイアログ表示');
          _showRequestSentDialog(amount, pointsToAward);
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


  void _showRequestSentDialog(int amount, int pointsToAward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('リクエスト送信完了'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.send, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text('${_isLoadingUserInfo ? '読み込み中...' : _actualUserName}さん'),
            const SizedBox(height: 8),
            Text(
              'ポイント付与リクエストを送信しました',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '付与予定ポイント: ${pointsToAward}pt',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                'お客様の確認をお待ちしています\n確認後、ポイントが付与されます',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // ホーム画面に戻る（MainNavigationViewのホームタブ）
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/main',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('完了'),
          ),
        ],
      ),
    );
  }

  void _showRequestAcceptedDialog(PointRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ポイント付与完了'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('${_isLoadingUserInfo ? '読み込み中...' : _actualUserName}さん'),
            const SizedBox(height: 8),
            Text(
              'ポイント付与が完了しました！',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '付与ポイント: ${request.userPoints}pt',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                'お客様のポイントが正常に更新されました\nリクエストID: ${request.id}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // ホーム画面に戻る（MainNavigationViewのホームタブ）
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/main',
                (route) => false,
              );
            },
            child: const Text('完了'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 再度スキャン
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('もう一度スキャン'),
          ),
        ],
      ),
    );
  }

  void _showRequestRejectedDialog(PointRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ポイント付与拒否'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('${_isLoadingUserInfo ? '読み込み中...' : _actualUserName}さん'),
            const SizedBox(height: 8),
            Text(
              'ポイント付与が拒否されました',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            if (request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                '理由: ${request.rejectionReason}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Text(
                'お客様がポイント付与を拒否しました\nリクエストはキャンセルされました',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // ホーム画面に戻る（MainNavigationViewのホームタブ）
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/main',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('完了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // リクエストの状態を監視
    if (_currentRequestId != null) {
      ref.listen<AsyncValue<PointRequest?>>(
        pointRequestStatusProvider(_currentRequestId!),
        (previous, next) {
          next.when(
            data: (request) {
              if (request != null) {
                if (request.status == PointRequestStatus.accepted.value) {
                  _showRequestAcceptedDialog(request);
                } else if (request.status == PointRequestStatus.rejected.value) {
                  _showRequestRejectedDialog(request);
                }
              }
            },
            loading: () {},
            error: (error, _) {
              print('リクエスト状態監視エラー: $error');
            },
          );
        },
      );
    }

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
          // お客様情報セクション
          _buildCustomerInfo(),
          
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

  Widget _buildCustomerInfo() {
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
      child: Row(
        children: [
          // お客様アイコン
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(30),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: _isLoadingUserInfo
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? Image.network(
                          _profileImageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                _actualUserName.isNotEmpty 
                                    ? _actualUserName.substring(0, 1).toUpperCase()
                                    : '客',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            _actualUserName.isNotEmpty 
                                ? _actualUserName.substring(0, 1).toUpperCase()
                                : '客',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 16),
          // お客様情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingUserInfo ? '読み込み中...' : _actualUserName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ユーザーID: ${widget.userId}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '支払い待ち',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          Text(
            '付与予定ポイント: ${((int.tryParse(_amount) ?? 0) * _pointReturnRate / 100).floor()}pt',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
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
          // ポイント付与確認ボタン
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _onPointAwardPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'ポイント付与確認',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
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
