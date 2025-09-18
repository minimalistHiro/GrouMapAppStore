import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_view.dart';

class ApprovalPendingView extends ConsumerStatefulWidget {
  const ApprovalPendingView({Key? key}) : super(key: key);

  @override
  ConsumerState<ApprovalPendingView> createState() => _ApprovalPendingViewState();
}

class _ApprovalPendingViewState extends ConsumerState<ApprovalPendingView> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    // フレーム後に承認状況をチェック（UIの構築を待つ）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkApprovalStatus();
    });
  }

  Future<void> _checkApprovalStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isChecking = false;
        });
        return;
      }

      // 店舗IDを取得
      final userStoreIdAsync = ref.read(userStoreIdProvider);
      final storeId = userStoreIdAsync.when(
        data: (data) => data,
        loading: () => null,
        error: (error, stackTrace) => null,
      );

      if (storeId == null) {
        setState(() {
          _isChecking = false;
        });
        return;
      }

      // 店舗の承認状況を確認
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      if (storeDoc.exists) {
        final storeData = storeDoc.data()!;
        final isApproved = storeData['isApproved'] ?? false;

        if (isApproved) {
          // 承認済みの場合は即座にホーム画面に遷移（UI更新をスキップ）
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainNavigationView()),
              (route) => false,
            );
          }
          return;
        }
      }

      // 未承認または店舗情報が見つからない場合は承認待ち画面を表示
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ロゴ
                Image.asset(
                  'assets/images/groumap_store_icon.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.store, size: 120, color: Color(0xFFFF6B35)),
                ),
                
                const SizedBox(height: 32),
                
                // タイトル
                const Text(
                  'GrouMap Store',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // 承認待ちメッセージ
                if (_isChecking)
                  const Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '承認状況を確認中...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '承認がされるまでしばらくお待ちください',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'アカウントが承認され次第、\n店舗管理機能をご利用いただけます',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _checkApprovalStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('承認状況を再確認'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
