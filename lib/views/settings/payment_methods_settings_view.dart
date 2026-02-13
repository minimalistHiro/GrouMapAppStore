import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/payment_methods_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_dialog.dart';

class PaymentMethodsSettingsView extends ConsumerStatefulWidget {
  const PaymentMethodsSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentMethodsSettingsView> createState() =>
      _PaymentMethodsSettingsViewState();
}

class _PaymentMethodsSettingsViewState
    extends ConsumerState<PaymentMethodsSettingsView> {
  String? _storeId;
  bool _isLoading = false;
  bool _isSaving = false;

  // カテゴリキー → { 項目キー → bool }
  Map<String, Map<String, bool>> _paymentMethods = {};

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
    _loadStoreData();
  }

  void _initializeDefaults() {
    for (final category in paymentMethodCategories) {
      _paymentMethods[category.key] = {};
      for (final item in category.items) {
        _paymentMethods[category.key]![item.key] = false;
      }
    }
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('ログイン情報が見つかりません。再ログインしてください。');
        return;
      }

      final userStoreIdAsync = ref.read(userStoreIdProvider);
      final storeId = userStoreIdAsync.when(
        data: (data) => data,
        loading: () => null,
        error: (error, stackTrace) => null,
      );

      if (storeId == null) {
        _showError('店舗情報が見つかりません。');
        return;
      }

      _storeId = storeId;
      await _loadPaymentMethods();
    } catch (e) {
      _showError('データの読み込みに失敗しました。', details: e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPaymentMethods() async {
    if (_storeId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('stores')
        .doc(_storeId)
        .get();

    if (!doc.exists) return;

    final data = doc.data();
    if (data == null) return;

    final saved = data['paymentMethods'];
    if (saved == null || saved is! Map) return;

    for (final category in paymentMethodCategories) {
      final categoryData = saved[category.key];
      if (categoryData == null || categoryData is! Map) continue;

      for (final item in category.items) {
        if (categoryData[item.key] == true) {
          _paymentMethods[category.key]?[item.key] = true;
        }
      }
    }
  }

  Future<void> _save() async {
    if (_storeId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(_storeId)
          .update({
        'paymentMethods': _paymentMethods,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('決済方法を保存しました'),
            backgroundColor: Color(0xFFFF6B35),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('保存に失敗しました。', details: e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message, {String? details}) {
    if (!mounted) return;
    ErrorDialog.show(
      context,
      title: 'エラー',
      message: message,
      details: details,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CommonHeader(title: '店舗決済方法設定'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CommonHeader(title: '店舗決済方法設定'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: paymentMethodCategories
            .map((category) => _buildCategorySection(category))
            .toList(),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: CustomButton(
            text: '保存する',
            onPressed: _isSaving ? null : _save,
            isLoading: _isSaving,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(PaymentMethodCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(category.icon, color: const Color(0xFFFF6B35), size: 20),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
            children: category.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isEnabled =
                  _paymentMethods[category.key]?[item.key] ?? false;
              return Column(
                children: [
                  SwitchListTile(
                    title: Text(item.displayName),
                    value: isEnabled,
                    activeColor: const Color(0xFFFF6B35),
                    onChanged: (value) {
                      setState(() {
                        _paymentMethods[category.key]?[item.key] = value;
                      });
                    },
                  ),
                  if (index < category.items.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
