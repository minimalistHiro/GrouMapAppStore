import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../payment/store_payment_view.dart';
import 'point_usage_input_view.dart';

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
  bool _isUpdating = false;
  bool _didNavigate = false;

  @override
  Widget build(BuildContext context) {
    final requestRef = FirebaseFirestore.instance
        .collection('point_requests')
        .doc(widget.storeId)
        .collection(widget.userId)
        .doc('usage_request');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('お客様の承認待ち'),
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
          final isExpired = status == 'usage_expired' || _isExpired(data);

          if (status == 'usage_pending_user_approval' && isExpired && !_isUpdating) {
            _isUpdating = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _markExpired();
            });
          }

          if (!_didNavigate && status == 'usage_approved') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToPayment(usedPoints);
            });
          }

          if (!_didNavigate && (status == 'usage_rejected' || status == 'usage_cancelled')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToPayment(0);
            });
          }

          return _buildWaitingContent(status, isExpired);
        },
      ),
    );
  }

  Widget _buildWaitingContent(String status, bool isExpired) {
    final isWaiting = status == 'usage_pending_user_approval' && !isExpired;
    final isApproved = status == 'usage_approved';
    final isRejected = status == 'usage_rejected' || status == 'usage_cancelled';
    final canCancel = isWaiting;
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
              'お客様の承認を待っています',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          if (!isWaiting && !isApproved)
            SizedBox(
              width: double.infinity,
              child: Text(
                isExpired
                    ? '承認の有効期限が切れました。再送してください。'
                    : isRejected
                        ? '承認が拒否されました。ポイント利用なしで会計に進みます。'
                        : '処理状態を確認してください。',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 16),
          if (!isWaiting && (isExpired || isRejected))
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _navigateToInput,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('再送する'),
              ),
            ),
          if (isApproved)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '承認されました。会計画面に移動します。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold),
              ),
            ),
          if (canCancel) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _cancelAndProceed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B35),
                  side: const BorderSide(color: Color(0xFFFF6B35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('利用しないで会計へ'),
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
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

  Future<void> _cancelAndProceed() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final requestRef = firestore
          .collection('point_requests')
          .doc(widget.storeId)
          .collection(widget.userId)
          .doc('usage_request');
      int? approvedPoints;
      await firestore.runTransaction((txn) async {
        final snapshot = await txn.get(requestRef);
        final data = snapshot.data() ?? {};
        final status = (data['status'] ?? '').toString();
        if (status == 'usage_approved') {
          approvedPoints = _parseInt(data['usedPoints']);
          return;
        }
        if (status != 'usage_pending_user_approval') {
          return;
        }
        txn.update(requestRef, {
          'status': 'usage_cancelled',
          'usageCancelledAt': FieldValue.serverTimestamp(),
        });
      });
      if (approvedPoints != null) {
        _navigateToPayment(approvedPoints!);
        return;
      }
    } catch (_) {}

    _navigateToPayment(0);
  }

  Future<void> _markExpired() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final requestRef = firestore
          .collection('point_requests')
          .doc(widget.storeId)
          .collection(widget.userId)
          .doc('usage_request');
      await firestore.runTransaction((txn) async {
        final snapshot = await txn.get(requestRef);
        final data = snapshot.data() ?? {};
        final status = (data['status'] ?? '').toString();
        if (status != 'usage_pending_user_approval') {
          return;
        }
        txn.update(requestRef, {
          'status': 'usage_expired',
          'usageExpiredAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  bool _isExpired(Map<String, dynamic> data) {
    final expiresAt = data['expiresAt'];
    DateTime? expiresAtTime;
    if (expiresAt is Timestamp) {
      expiresAtTime = expiresAt.toDate();
    }
    if (expiresAtTime != null) {
      return DateTime.now().isAfter(expiresAtTime);
    }
    final updatedAt = data['updatedAt'];
    if (updatedAt is Timestamp) {
      return DateTime.now().difference(updatedAt.toDate()).inMinutes >= 5;
    }
    return false;
  }

  void _navigateToInput() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PointUsageInputView(userId: widget.userId),
      ),
    );
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
