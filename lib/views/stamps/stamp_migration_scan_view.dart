import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/qr_verification_provider.dart';
import '../../widgets/common_header.dart';
import 'stamp_migration_confirm_view.dart';

class StampMigrationScanView extends ConsumerStatefulWidget {
  const StampMigrationScanView({super.key});

  @override
  ConsumerState<StampMigrationScanView> createState() =>
      _StampMigrationScanViewState();
}

class _StampMigrationScanViewState
    extends ConsumerState<StampMigrationScanView> {
  MobileScannerController? _scannerController;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: '物理スタンプカード移行'),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController!,
            onDetect: (capture) {
              if (!_isScanning) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;
                if (code != null) {
                  setState(() {
                    _isScanning = false;
                  });
                  _processQRCode(code);
                }
              }
            },
          ),
          Container(
            decoration:
                BoxDecoration(color: Colors.black.withOpacity(0.5)),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFFFF6B35), width: 3),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                    ),
                    child: const Center(
                      child: Text(
                        'お客様のQRコードを\nスキャン',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '物理スタンプカードを保有しているお客様の\nQRコードをスキャンしてください',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processQRCode(String qrCode) async {
    final uid = _extractUidFromQR(qrCode);
    if (uid == null) {
      if (!mounted) return;
      _showError('QRコードが無効です。お客様のアプリのQRコードをスキャンしてください。');
      setState(() {
        _isScanning = true;
      });
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      ),
    );

    try {
      final storeId = await _resolveStoreId();

      if (!mounted) {
        return;
      }

      if (storeId == null) {
        Navigator.of(context).pop();
        _showError('店舗IDが取得できません。再ログインしてください。');
        setState(() {
          _isScanning = true;
        });
        return;
      }

      final migrationDocId = '${storeId}_$uid';
      final migrationSnap = await FirebaseFirestore.instance
          .collection('stamp_migrations')
          .doc(migrationDocId)
          .get();

      if (!mounted) return;

      if (migrationSnap.exists) {
        Navigator.of(context).pop();
        _showAlreadyMigratedDialog(migrationSnap.data()!);
        setState(() {
          _isScanning = true;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        Navigator.of(context).pop();
        _showError('ユーザーが見つかりません。');
        setState(() {
          _isScanning = true;
        });
        return;
      }

      final userProfile = userDoc.data() ?? {};

      final storeStampDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('stores')
          .doc(storeId)
          .get();

      final currentStamps =
          (storeStampDoc.data()?['stamps'] as int?) ?? 0;

      if (!mounted) return;
      Navigator.of(context).pop();

      // ignore: use_build_context_synchronously
      final migrationCompleted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => StampMigrationConfirmView(
            userId: uid,
            storeId: storeId,
            userProfile: userProfile,
            currentStamps: currentStamps,
          ),
        ),
      );

      if (migrationCompleted == true) {
        if (mounted) Navigator.of(context).pop();
      } else {
        if (mounted) {
          setState(() {
            _isScanning = true;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      try {
        Navigator.of(context).pop();
      } catch (_) {}
      _showError('エラーが発生しました: $e');
      setState(() {
        _isScanning = true;
      });
    }
  }

  String? _extractUidFromQR(String token) {
    try {
      final decodedBytes = base64Decode(token);
      final jsonString = utf8.decode(decodedBytes);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final sub = jsonData['sub'] as String?;
      final exp = jsonData['exp'] as int?;

      if (sub == null || exp == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (now > exp) return null;

      return sub;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveStoreId() async {
    final storeSettings = ref.read(storeSettingsProvider);
    if (storeSettings != null && storeSettings.storeId.isNotEmpty) {
      return storeSettings.storeId;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      final data = doc.data();
      if (data == null) return null;

      final currentStoreId = data['currentStoreId'] as String?;
      if (currentStoreId != null && currentStoreId.isNotEmpty) {
        return currentStoreId;
      }
      final createdStores = data['createdStores'] as List<dynamic>?;
      if (createdStores != null && createdStores.isNotEmpty) {
        return createdStores.first as String;
      }
    } catch (_) {}
    return null;
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showAlreadyMigratedDialog(Map<String, dynamic> migrationData) {
    if (!mounted) return;
    final stampsAfter = migrationData['stampsAfter'] as int? ?? 0;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('移行済みです'),
        content: Text(
          'このユーザーはこの店舗への移行が既に完了しています。\n（移行後スタンプ: $stampsAfter 個）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
