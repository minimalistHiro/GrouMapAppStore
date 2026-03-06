import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_navigation_view.dart';

class StoreLinkView extends ConsumerStatefulWidget {
  /// true = サインアップ直後のフロー（キャンセル不可）
  /// false = 設定画面等からの任意遷移
  final bool isFromSignUp;

  const StoreLinkView({Key? key, this.isFromSignUp = false}) : super(key: key);

  @override
  ConsumerState<StoreLinkView> createState() => _StoreLinkViewState();
}

class _StoreLinkViewState extends ConsumerState<StoreLinkView> {
  final _linkCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _linkCodeController.dispose();
    super.dispose();
  }

  Future<void> _linkStore() async {
    final code = _linkCodeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'リンクコードを入力してください');
      return;
    }

    if (code.length != 6) {
      setState(() => _errorMessage = 'リンクコードは6文字です');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('ログインが必要です');

      // リンクコードで stores を検索
      final querySnap = await FirebaseFirestore.instance
          .collection('stores')
          .where('linkCode', isEqualTo: code)
          .where('isApproved', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnap.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'このリンクコードは無効です。運営にご確認ください。';
        });
        return;
      }

      final storeDoc = querySnap.docs.first;
      final storeId = storeDoc.id;

      // 紐づけ処理
      final batch = FirebaseFirestore.instance.batch();

      // stores.linkedUids に uid を追加
      batch.update(
        FirebaseFirestore.instance.collection('stores').doc(storeId),
        {
          'linkedUids': FieldValue.arrayUnion([uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // users.linkedStoreId を設定
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(uid),
        {
          'linkedStoreId': storeId,
          'createdStores': FieldValue.arrayUnion([storeId]),
          'currentStoreId': storeId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${storeDoc.data()['name'] ?? '店舗'} と紐づけました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationView()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '紐づけに失敗しました。もう一度お試しください。';
      });
    }
  }

  void _skipLink() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: widget.isFromSignUp
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('店舗との紐づけ', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // アイコン
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.link, color: Color(0xFFFF6B35), size: 44),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                '店舗との紐づけ',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                '運営から受け取ったリンクコードを入力してください。\n店舗の来店データやスタンプ情報を確認できるようになります。',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // リンクコード入力
              TextField(
                controller: _linkCodeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Color(0xFFFF6B35),
                ),
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.grey[300],
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z]')),
                ],
                onChanged: (v) {
                  // 小文字を大文字に変換
                  if (v != v.toUpperCase()) {
                    _linkCodeController.value = TextEditingValue(
                      text: v.toUpperCase(),
                      selection: TextSelection.collapsed(offset: v.length),
                    );
                  }
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
              ],

              const SizedBox(height: 32),

              // 紐づけボタン
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _linkStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('紐づける', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 16),

              // 後で紐づけるボタン
              TextButton(
                onPressed: _isLoading ? null : _skipLink,
                child: const Text(
                  '後で紐づける',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),

              const SizedBox(height: 16),

              // 説明
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'リンクコードは運営担当者からお受け取りください。\n「後で紐づける」を選択した場合、設定画面から後でコードを入力できます。',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
