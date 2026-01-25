import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../payment/store_payment_view.dart';

class PointUsageRequestWaitingView extends ConsumerStatefulWidget {
  final String userId;
  final String storeId;
  final String storeName;

  const PointUsageRequestWaitingView({
    Key? key,
    required this.userId,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  ConsumerState<PointUsageRequestWaitingView> createState() => _PointUsageRequestWaitingViewState();
}

class _PointUsageRequestWaitingViewState extends ConsumerState<PointUsageRequestWaitingView> {
  bool _isProcessing = false;
  bool _didNavigate = false;

  @override
  Widget build(BuildContext context) {
    final requestRef = FirebaseFirestore.instance
        .collection('point_requests')
        .doc(widget.storeId)
        .collection(widget.userId)
        .doc('request');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ポイント入力待ち'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: requestRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('リクエストが見つかりません'));
          }

          final data = snapshot.data!.data() ?? const <String, dynamic>{};
          final status = (data['status'] ?? '').toString();
          final usedPoints = _parseInt(data['usedPoints']);

          if (!_didNavigate && !_isProcessing && status == 'usage_input_done') {
            _isProcessing = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _applyUsageAndNavigate(usedPoints);
            });
          }

          if (!_didNavigate && status == 'usage_input_cancelled') {
            _didNavigate = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToPayment(0);
            });
          }

          return _buildWaitingContent();
        },
      ),
    );
  }

  Widget _buildWaitingContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: const Text(
              'お客様がポイント利用額を入力中です',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Future<void> _applyUsageAndNavigate(int usedPoints) async {
    if (_didNavigate) return;
    if (usedPoints <= 0) {
      _navigateToPayment(0);
      return;
    }

    try {
      await _usePoints(
        storeId: widget.storeId,
        pointsToUse: usedPoints,
      );

      await FirebaseFirestore.instance
          .collection('point_requests')
          .doc(widget.storeId)
          .collection(widget.userId)
          .doc('request')
          .update({
        'status': 'usage_processed',
        'usageProcessedAt': FieldValue.serverTimestamp(),
      });

      _navigateToPayment(usedPoints);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ポイント利用の反映に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToPayment(int usedPoints) {
    if (_didNavigate) return;
    _didNavigate = true;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StorePaymentView(
          userId: widget.userId,
          userName: '',
          usedPoints: usedPoints,
        ),
      ),
    );
  }

  Future<void> _skipPointUsage() async {
    try {
      await FirebaseFirestore.instance
          .collection('point_requests')
          .doc(widget.storeId)
          .collection(widget.userId)
          .doc('request')
          .update({
        'status': 'usage_input_cancelled',
        'usageCancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    _navigateToPayment(0);
  }

  Future<void> _usePoints({
    required String storeId,
    required int pointsToUse,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final transactionId = firestore.collection('point_transactions').doc().id;
    final balanceRef = firestore.collection('user_point_balances').doc(widget.userId);
    final userRef = firestore.collection('users').doc(widget.userId);
    final transactionRef = firestore
        .collection('point_transactions')
        .doc(storeId)
        .collection(widget.userId)
        .doc(transactionId);
    final storeTransactionRef = firestore
        .collection('stores')
        .doc(storeId)
        .collection('transactions')
        .doc(transactionId);
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final storeStatsRef = firestore
        .collection('store_stats')
        .doc(storeId)
        .collection('daily')
        .doc(todayStr);

    await firestore.runTransaction((txn) async {
      final userSnap = await txn.get(userRef);
      if (!userSnap.exists) {
        throw Exception('ユーザー情報が見つかりません');
      }
      final balanceSnap = await txn.get(balanceRef);

      final userData = userSnap.data() ?? {};
      final currentPoints = _parseInt(userData['points']);
      final currentSpecialPoints = _parseInt(userData['specialPoints']);
      final availablePoints = currentPoints + currentSpecialPoints;

      int usedPoints = 0;
      int totalPoints = availablePoints;
      if (balanceSnap.exists) {
        final data = balanceSnap.data() ?? {};
        usedPoints = _parseInt(data['usedPoints']);
        totalPoints = _parseInt(data['totalPoints']);
        if (totalPoints == 0) {
          totalPoints = availablePoints;
        }
      }

      if (availablePoints < pointsToUse) {
        throw Exception('ポイントが不足しています');
      }

      final useSpecial = currentSpecialPoints >= pointsToUse
          ? pointsToUse
          : currentSpecialPoints;
      final useNormal = pointsToUse - useSpecial;

      txn.set(
        balanceRef,
        {
          'userId': widget.userId,
          'totalPoints': totalPoints,
          'availablePoints': availablePoints - pointsToUse,
          'usedPoints': usedPoints + pointsToUse,
          'lastUpdated': now,
          'lastUpdatedByStoreId': storeId,
        },
        SetOptions(merge: true),
      );

      final Map<String, dynamic> userUpdates = {
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedByStoreId': storeId,
      };
      if (useSpecial > 0) {
        userUpdates['specialPoints'] = FieldValue.increment(-useSpecial);
      }
      if (useNormal > 0) {
        userUpdates['points'] = FieldValue.increment(-useNormal);
      }
      txn.update(userRef, userUpdates);

      txn.set(transactionRef, {
        'transactionId': transactionId,
        'userId': widget.userId,
        'storeId': storeId,
        'storeName': widget.storeName,
        'amount': -pointsToUse,
        'paymentAmount': null,
        'status': 'completed',
        'paymentMethod': 'points',
        'createdAt': now,
        'updatedAt': now,
        'description': 'ポイント支払い',
        'usedSpecialPoints': useSpecial,
        'usedNormalPoints': useNormal,
        'totalUsedPoints': pointsToUse,
      });

      txn.set(storeTransactionRef, {
        'transactionId': transactionId,
        'storeId': storeId,
        'storeName': widget.storeName,
        'userId': widget.userId,
        'type': 'use',
        'amountYen': null,
        'points': pointsToUse,
        'paymentMethod': 'points',
        'status': 'completed',
        'source': 'point_usage',
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtClient': now,
        'usedSpecialPoints': useSpecial,
        'usedNormalPoints': useNormal,
        'totalUsedPoints': pointsToUse,
      });

      txn.set(
        storeStatsRef,
        {
          'date': todayStr,
          'pointsUsed': FieldValue.increment(pointsToUse),
          'totalTransactions': FieldValue.increment(1),
          'visitorCount': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
