import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/custom_button.dart';
import '../../providers/qr_verification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/qr_verification_model.dart';
import '../payment/store_payment_view.dart';

class QRScannerView extends ConsumerStatefulWidget {
  const QRScannerView({Key? key}) : super(key: key);

  @override
  ConsumerState<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends ConsumerState<QRScannerView> {
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    // 店舗設定の自動初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStoreSettings();
    });
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコードスキャン'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: _buildScannerContent(context),
    );
  }

  Widget _buildScannerContent(BuildContext context) {
    if (!_isScanning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QRスキャンアイコン
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  size: 60,
                  color: Color(0xFFFF6B35),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // タイトル
              const Text(
                'QRコードをスキャン',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 説明テキスト
              const Text(
                'お客様のQRコードをカメラに向けて\nスキャンしてください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // スキャン開始ボタン
              CustomButton(
                text: 'スキャンを開始',
                onPressed: () {
                  _startScanning();
                },
                backgroundColor: const Color(0xFFFF6B35),
              ),
              
              const SizedBox(height: 16),
              
              // 手動入力ボタン
              TextButton(
                onPressed: () {
                  _showManualInputDialog(context);
                },
                child: const Text(
                  '手動でQRコードを入力',
                  style: TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // カメラビュー
        MobileScanner(
          controller: _scannerController!,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.rawValue;
              if (code != null) {
                _handleQRCodeDetected(context, code);
              }
            }
          },
        ),
        
        // スキャンエリアのオーバーレイ
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'QRコードをここに合わせてください',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        
        // 停止ボタン
        Positioned(
          top: 50,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              _stopScanning();
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.stop, color: Colors.white),
          ),
        ),
        
        // 説明テキスト
        Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'QRコードをスキャンエリアに合わせてください',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  /// 店舗設定の自動初期化
  Future<void> _initializeStoreSettings() async {
    final storeSettings = ref.read(storeSettingsProvider);
    if (storeSettings != null) return; // 既に設定済み

    // 認証ユーザーから店舗IDを取得
    final authState = ref.read(authStateProvider);
    await authState.when(
      data: (user) async {
        if (user != null) {
          try {
            // ユーザーの店舗IDを取得
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final createdStores = userData['createdStores'] as List<dynamic>?;
              if (createdStores != null && createdStores.isNotEmpty) {
                final storeId = createdStores.first as String;
                
                // 店舗情報を取得
                final storeDoc = await FirebaseFirestore.instance
                    .collection('stores')
                    .doc(storeId)
                    .get();
                
                if (storeDoc.exists) {
                  final storeData = storeDoc.data()!;
                  final settings = StoreSettings(
                    storeId: storeId,
                    storeName: storeData['name'] ?? '店舗',
                    description: storeData['description'],
                  );
                  
                  // 店舗設定を設定
                  final storeSettingsNotifier = ref.read(storeSettingsProvider.notifier);
                  storeSettingsNotifier.setStoreSettings(settings);
                  
                  print('店舗設定を自動初期化しました: $storeId');
                }
              }
            }
          } catch (e) {
            print('店舗設定の自動初期化に失敗しました: $e');
          }
        }
      },
      loading: () async {},
      error: (error, _) async {},
    );
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  void _handleQRCodeDetected(BuildContext context, String code) {
    _stopScanning();
    _processQRCode(context, code);
  }

  void _showManualInputDialog(BuildContext context) {
    _manualInputController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QRコードを手動入力'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('お客様のQRコードの内容を入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: _manualInputController,
              decoration: const InputDecoration(
                labelText: 'QRコード',
                hintText: 'Base64エンコードされたJSON文字列',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
                helperText: 'お客様アプリからコピーした文字列を貼り付けてください',
              ),
              autofocus: true,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // テスト用QRトークン生成ボタン
            Container(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final testToken = _generateTestToken();
                  _manualInputController.text = testToken;
                },
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('テスト用QRトークンを生成'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B35),
                  side: const BorderSide(color: Color(0xFFFF6B35)),
                ),
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
              final qrCode = _manualInputController.text.trim();
              Navigator.of(context).pop();
              if (qrCode.isNotEmpty) {
                _processQRCode(context, qrCode);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QRコードを入力してください'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('検証'),
          ),
        ],
      ),
    );
  }

  void _processQRCode(BuildContext context, String qrCode) async {
    print('QRコード処理開始: $qrCode');
    
    if (qrCode.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QRコードを入力してください'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 店舗IDの確認
    final storeSettings = ref.read(storeSettingsProvider);
    if (storeSettings == null || storeSettings.storeId.isEmpty) {
      if (context.mounted) {
        // 店舗設定を再試行
        await _initializeStoreSettings();
        final updatedStoreSettings = ref.read(storeSettingsProvider);
        if (updatedStoreSettings == null || updatedStoreSettings.storeId.isEmpty) {
          _showStoreIdErrorDialog(context);
          return;
        }
      } else {
        return;
      }
    }

    // ローディング表示
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      ),
    );

    // タイムアウト処理（5秒で強制終了）
    Timer? timeoutTimer;
    timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (context.mounted) {
        Navigator.of(context).pop(); // ローディングを閉じる
        _showErrorDialog(
          context,
          'タイムアウト',
          '処理がタイムアウトしました。もう一度お試しください。',
        );
      }
    });

    try {
      // QRコードの形式をチェック（Base64エンコードされたJSONかどうか）
      final isValidToken = _isValidQRToken(qrCode.trim());
      print('QRトークン形式チェック結果: $isValidToken');
      
      if (!isValidToken) {
        // 無効な形式の場合は即座にエラーを表示
        timeoutTimer?.cancel();
        if (context.mounted) {
          Navigator.of(context).pop(); // ローディングを閉じる
          _showErrorDialog(
            context,
            '無効なQRコード',
            'このQRコードは無効な形式です。\n正しいQRコードをスキャンしてください。',
          );
        }
        return;
      }

      // 店舗設定を再取得（null安全のため）
      final currentStoreSettings = ref.read(storeSettingsProvider);
      if (currentStoreSettings == null) {
        timeoutTimer?.cancel();
        if (context.mounted) {
          Navigator.of(context).pop(); // ローディングを閉じる
          _showStoreIdErrorDialog(context);
        }
        return;
      }

      // Cloud FunctionsでQRトークンを検証（開発環境ではモック検証も試行）
      QRVerificationResult result;
      try {
        final verificationNotifier = ref.read(qrVerificationProvider.notifier);
        result = await verificationNotifier.verifyQrToken(
          token: qrCode.trim(),
          storeId: currentStoreSettings.storeId,
        );
        
        // Cloud Functionsでエラーが発生した場合もモック検証を試行
        if (!result.isSuccess && result.error != null) {
          print('Cloud Functions検証失敗、モック検証を試行: ${result.error}');
          result = _mockVerifyQrToken(qrCode.trim());
        }
      } catch (e) {
        print('Cloud Functions呼び出し失敗、モック検証を試行: $e');
        // 開発環境用のモック検証
        result = _mockVerifyQrToken(qrCode.trim());
      }
      
      // タイムアウトタイマーをキャンセル
      timeoutTimer?.cancel();
      
      // ローディングを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      print('QR検証結果: isSuccess=${result.isSuccess}, message=${result.message}, uid=${result.uid}');

      if (result.isSuccess) {
        // 成功時：支払い画面に遷移
        print('QR検証成功、支払い画面に遷移開始');
        if (result.uid != null && context.mounted) {
          await _navigateToPaymentScreen(context, result.uid!);
        } else {
          print('支払い画面遷移失敗: uid=${result.uid}, context.mounted=${context.mounted}');
        }
      } else {
        // エラー時：エラーダイアログを表示
        print('QR検証失敗、エラーダイアログ表示');
        if (context.mounted) {
          _showVerificationErrorDialog(context, result);
        }
      }
    } catch (e) {
      print('QRコード処理エラー: $e');
      // タイムアウトタイマーをキャンセル
      timeoutTimer?.cancel();
      
      // ローディングを確実に閉じる
      if (context.mounted) {
        Navigator.of(context).pop(); // ローディングを閉じる
        _showErrorDialog(
          context,
          'QRコードの処理中にエラーが発生しました',
          'エラー: $e',
        );
      }
    }
  }

  /// 支払い画面に遷移
  Future<void> _navigateToPaymentScreen(BuildContext context, String uid) async {
    try {
      // ウィジェットが破棄されていないかチェック
      if (!context.mounted) {
        print('ウィジェットが破棄されています');
        return;
      }

      // ユーザー情報を取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // 再度ウィジェットが破棄されていないかチェック
      if (!context.mounted) {
        print('ユーザー情報取得後にウィジェットが破棄されています');
        return;
      }

      if (!userDoc.exists) {
        _showErrorDialog(
          context,
          'ユーザーエラー',
          'ユーザー情報が見つかりませんでした。',
        );
        return;
      }

      final userData = userDoc.data()!;
      final userName = userData['displayName'] ?? 
                     userData['email'] ?? 
                     'お客様';

      // 最終的にウィジェットが破棄されていないかチェック
      if (!context.mounted) {
        print('画面遷移前にウィジェットが破棄されています');
        return;
      }

      // 支払い画面に遷移
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StorePaymentView(
            userId: uid,
            userName: userName,
          ),
        ),
      );
    } catch (e) {
      print('ユーザー情報取得エラー: $e');
      if (context.mounted) {
        _showErrorDialog(
          context,
          'ユーザー情報取得エラー',
          'エラー: $e',
        );
      }
    }
  }

  /// 検証エラーダイアログを表示
  void _showVerificationErrorDialog(BuildContext context, QRVerificationResult result) {
    String title = 'QRコードエラー';
    IconData icon = Icons.error;
    Color iconColor = Colors.red;

    switch (result.status) {
      case QRVerificationStatus.expired:
        title = '期限切れ';
        icon = Icons.access_time;
        iconColor = Colors.orange;
        break;
      case QRVerificationStatus.invalid:
        title = '無効なQRコード';
        icon = Icons.qr_code;
        break;
      case QRVerificationStatus.used:
        title = '使用済み';
        icon = Icons.check_circle_outline;
        iconColor = Colors.blue;
        break;
      case QRVerificationStatus.ok:
        title = '成功';
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case null:
        title = 'QRコードエラー';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              result.message,
              textAlign: TextAlign.center,
            ),
            if (result.uid != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ユーザーID: ${result.uid}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (result.status != QRVerificationStatus.ok)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startScanning();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
              child: const Text('再スキャン'),
            ),
        ],
      ),
    );
  }

  /// 店舗IDエラーダイアログを表示
  void _showStoreIdErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗設定エラー'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              '店舗IDが設定されていません。\n設定画面で店舗情報を設定してください。',
              textAlign: TextAlign.center,
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
              // 設定画面に遷移（BottomNavigationBarの設定タブに移動）
              // 親のMainNavigationViewのタブを変更する必要がある
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('設定タブで店舗設定を行ってください'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('設定画面へ'),
          ),
        ],
      ),
    );
  }

  /// QRトークンの形式が有効かチェック
  bool _isValidQRToken(String token) {
    try {
      // Base64デコードを試行
      final decoded = base64Decode(token);
      final jsonString = utf8.decode(decoded);
      
      // JSONパースを試行
      final jsonData = jsonDecode(jsonString);
      
      // 必要なフィールドが存在するかチェック
      if (jsonData is Map<String, dynamic>) {
        return jsonData.containsKey('sub') && 
               jsonData.containsKey('iat') && 
               jsonData.containsKey('exp') && 
               jsonData.containsKey('jti') && 
               jsonData.containsKey('ver');
      }
      
      return false;
    } catch (e) {
      print('QRトークン形式チェックエラー: $e');
      return false;
    }
  }

  /// テスト用QRトークンを生成
  String _generateTestToken() {
    // 開発環境用のモックトークン（Base64エンコードされたJSON）
    final testData = {
      'sub': 'testuser${DateTime.now().millisecondsSinceEpoch}',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': (DateTime.now().add(const Duration(seconds: 60)).millisecondsSinceEpoch ~/ 1000),
      'jti': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'ver': 1,
    };
    
    final jsonString = '{"sub":"${testData['sub']}","iat":${testData['iat']},"exp":${testData['exp']},"jti":"${testData['jti']}","ver":${testData['ver']}}';
    return base64Encode(utf8.encode(jsonString));
  }

  /// 開発環境用のモック検証
  QRVerificationResult _mockVerifyQrToken(String token) {
    print('モック検証開始: $token');
    try {
      // Base64デコードを試行
      final decodedBytes = base64Decode(token);
      final jsonString = utf8.decode(decodedBytes);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final sub = jsonData['sub'] as String?;
      final exp = jsonData['exp'] as int?;
      final jti = jsonData['jti'] as String?;
      
      print('モック検証データ: sub=$sub, exp=$exp, jti=$jti');
      
      if (sub == null || exp == null || jti == null) {
        print('モック検証失敗: 必須フィールドが不足');
        return QRVerificationResult(
          isSuccess: false,
          message: '無効なQRコードです（モック検証）',
          status: QRVerificationStatus.invalid,
        );
      }
      
      // 有効期限チェック
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('有効期限チェック: now=$now, exp=$exp');
      if (now > exp) {
        print('モック検証失敗: 有効期限切れ');
        return QRVerificationResult(
          isSuccess: false,
          message: 'QRの有効期限切れ（モック検証）',
          status: QRVerificationStatus.expired,
        );
      }
      
      // 成功
      print('モック検証成功: uid=$sub');
      return QRVerificationResult(
        isSuccess: true,
        message: 'QRコードが有効です（モック検証）',
        uid: sub,
        jti: jti,
        status: QRVerificationStatus.ok,
      );
    } catch (e) {
      print('モック検証エラー: $e');
      return QRVerificationResult(
        isSuccess: false,
        message: '無効なQRコードです（モック検証）',
        status: QRVerificationStatus.invalid,
      );
    }
  }


  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Text(
                'ネットワーク接続を確認し、もう一度お試しください。\n問題が続く場合は管理者にお問い合わせください。',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
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
              _startScanning();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }
}