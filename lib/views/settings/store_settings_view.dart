import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/qr_verification_provider.dart';
import '../../models/qr_verification_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class StoreSettingsView extends ConsumerStatefulWidget {
  const StoreSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<StoreSettingsView> createState() => _StoreSettingsViewState();
}

class _StoreSettingsViewState extends ConsumerState<StoreSettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _storeIdController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isSavingQr = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _storeIdController.dispose();
    _storeNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadCurrentSettings() {
    final currentSettings = ref.read(storeSettingsProvider);
    if (currentSettings != null) {
      _storeIdController.text = currentSettings.storeId;
      _storeNameController.text = currentSettings.storeName;
      _descriptionController.text = currentSettings.description ?? '';
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final settings = StoreSettings(
        storeId: _storeIdController.text.trim(),
        storeName: _storeNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      final storeSettingsNotifier = ref.read(storeSettingsProvider.notifier);
      storeSettingsNotifier.setStoreSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('店舗設定を保存しました'),
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveStoreQrCode() async {
    final storeId = _storeIdController.text.trim();
    if (storeId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('店舗IDを入力してください'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSavingQr = true;
    });

    try {
      final painter = QrPainter(
        data: storeId,
        version: QrVersions.auto,
        gapless: true,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      final byteData = await painter.toImageData(
        1024,
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        throw Exception('QRコードの生成に失敗しました');
      }
      final pngBytes = byteData.buffer.asUint8List();
      final safeStoreId = storeId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(pngBytes),
        quality: 100,
        name: 'store_qr_$safeStoreId',
      );
      final isSuccess = result['isSuccess'] == true || result['isSuccess'] == 1;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSuccess
                  ? 'QRコードを保存しました'
                  : 'QRコードの保存に失敗しました',
            ),
            backgroundColor: isSuccess ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QRコードの保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingQr = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗設定'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 説明カード
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '店舗設定について',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'QRコード検証時に使用される店舗IDを設定してください。\nこの設定は必須です。',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 店舗ID入力
              CustomTextField(
                controller: _storeIdController,
                labelText: '店舗ID *',
                hintText: '例: store_001',
                prefixIcon: const Icon(Icons.store),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '店舗IDを入力してください';
                  }
                  if (value.trim().length < 3) {
                    return '店舗IDは3文字以上で入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              
              // QRコード保存ボタン
              CustomButton(
                text: 'QRコードを保存する',
                onPressed: _isSavingQr ? null : _saveStoreQrCode,
                backgroundColor: const Color(0xFFFF6B35),
                isLoading: _isSavingQr,
              ),
              
              const SizedBox(height: 16),
              
              // 店舗名入力
              CustomTextField(
                controller: _storeNameController,
                labelText: '店舗名 *',
                hintText: '例: サンプル店舗',
                prefixIcon: const Icon(Icons.business),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '店舗名を入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // 説明入力
              CustomTextField(
                controller: _descriptionController,
                labelText: '説明（任意）',
                hintText: '店舗の説明を入力してください',
                prefixIcon: const Icon(Icons.description),
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // 保存ボタン
              CustomButton(
                text: '設定を保存',
                onPressed: _isLoading ? null : () {
                  _saveSettings();
                },
                backgroundColor: const Color(0xFFFF6B35),
                isLoading: _isLoading,
              ),
              
              const SizedBox(height: 16),
              
              // 現在の設定表示
              Consumer(
                builder: (context, ref, child) {
                  final currentSettings = ref.watch(storeSettingsProvider);
                  if (currentSettings == null) {
                    return const SizedBox.shrink();
                  }
                  
                  return Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '現在の設定',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('店舗ID: ${currentSettings.storeId}'),
                          Text('店舗名: ${currentSettings.storeName}'),
                          if (currentSettings.description != null)
                            Text('説明: ${currentSettings.description}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
