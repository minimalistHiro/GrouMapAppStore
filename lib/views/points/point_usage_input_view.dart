import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/qr_verification_provider.dart';
import '../../widgets/custom_button.dart';
import '../coupons/coupon_select_for_checkout_view.dart';

class PointUsageInputView extends ConsumerStatefulWidget {
  final String userId;

  const PointUsageInputView({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<PointUsageInputView> createState() => _PointUsageInputViewState();
}

class _PointUsageInputViewState extends ConsumerState<PointUsageInputView> {
  String _amount = '0';
  String _actualUserName = 'お客様';
  String? _profileImageUrl;
  bool _isLoadingUserInfo = true;
  bool _isLoadingPoints = true;
  bool _isProcessing = false;
  int _availablePoints = 0;
  String _storeName = '店舗名';
  bool _isLoadingStoreInfo = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadUserPoints();
    _loadStoreInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        setState(() {
          _actualUserName = _resolveDisplayName(userData);
          _profileImageUrl = _resolveProfileImageUrl(userData);
          _isLoadingUserInfo = false;
        });
      } else {
        setState(() {
          _actualUserName = 'お客様';
          _isLoadingUserInfo = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _actualUserName = 'お客様';
        _isLoadingUserInfo = false;
      });
    }
  }

  Future<void> _loadUserPoints() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      int availablePoints = 0;
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        final points = _parseInt(data['points']);
        final specialPoints = _parseInt(data['specialPoints']);
        availablePoints = points + specialPoints;
      } else {
        final balanceDoc = await FirebaseFirestore.instance
            .collection('user_point_balances')
            .doc(widget.userId)
            .get();
        if (balanceDoc.exists) {
          final data = balanceDoc.data() ?? {};
          availablePoints = _parseInt(data['availablePoints']);
        }
      }

      if (!mounted) return;
      setState(() {
        _availablePoints = availablePoints;
        _isLoadingPoints = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availablePoints = 0;
        _isLoadingPoints = false;
      });
    }
  }

  Future<void> _loadStoreInfo() async {
    try {
      final authState = ref.read(authStateProvider);
      final storeUser = authState.value;
      if (storeUser == null) {
        setState(() {
          _storeName = '未認証店舗';
          _isLoadingStoreInfo = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(storeUser.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        String storeName = '店舗名';
        if (userData['displayName'] is String) {
          storeName = userData['displayName'] as String;
        } else if (userData['email'] is String) {
          final email = userData['email'] as String;
          storeName = '${email.split('@')[0]}店';
        }

        setState(() {
          _storeName = storeName;
          _isLoadingStoreInfo = false;
        });
        return;
      }

      setState(() {
        _storeName = '店舗名未設定';
        _isLoadingStoreInfo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _storeName = 'エラー';
        _isLoadingStoreInfo = false;
      });
    }
  }

  String _resolveDisplayName(Map<String, dynamic> userData) {
    if (userData['displayName'] is String && (userData['displayName'] as String).isNotEmpty) {
      return userData['displayName'] as String;
    }
    if (userData['email'] is String) {
      return userData['email'] as String;
    }
    if (userData['name'] is String) {
      return userData['name'] as String;
    }
    return 'お客様';
  }

  String? _resolveProfileImageUrl(Map<String, dynamic> userData) {
    final value = userData['profileImageUrl'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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

  Future<void> _onNextPressed() async {
    final pointsToUse = int.tryParse(_amount) ?? 0;
    if (pointsToUse <= 0) {
      _showSnackBar('利用ポイントを入力してください', Colors.red);
      return;
    }
    if (!_isLoadingPoints && pointsToUse > _availablePoints) {
      _showSnackBar('保有ポイントが不足しています', Colors.red);
      return;
    }
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final storeId = await _resolveStoreId();
      if (storeId == null || storeId.isEmpty) {
        throw Exception('店舗IDが取得できません');
      }

      await _usePoints(
        storeId: storeId,
        pointsToUse: pointsToUse,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CouponSelectForCheckoutView(
            userId: widget.userId,
            userName: _actualUserName,
            usedPoints: pointsToUse,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('ポイント利用に失敗しました: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<String?> _resolveStoreId() async {
    final storeSettings = ref.read(storeSettingsProvider);
    if (storeSettings != null && storeSettings.storeId.isNotEmpty) {
      return storeSettings.storeId;
    }

    final authState = ref.read(authStateProvider);
    final storeUser = authState.value;
    if (storeUser == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(storeUser.uid)
        .get();
    if (!userDoc.exists) return null;
    final data = userDoc.data() ?? {};
    final currentStoreId = data['currentStoreId'];
    if (currentStoreId is String && currentStoreId.isNotEmpty) {
      return currentStoreId;
    }
    return null;
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
        'storeName': _storeName,
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
        'storeName': _storeName,
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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ポイント利用'),
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
      ),
      body: Column(
        children: [
          _buildCustomerInfo(),
          _buildAmountDisplay(),
          Expanded(child: _buildCalculator()),
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
                          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
                        )
                      : _buildFallbackAvatar(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingUserInfo ? '読み込み中...' : _actualUserName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '保有ポイント: ${_isLoadingPoints ? '読み込み中...' : '$_availablePoints pt'}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Center(
      child: Text(
        _actualUserName.isNotEmpty ? _actualUserName.substring(0, 1).toUpperCase() : '客',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
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
            '利用ポイント',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_amount}pt',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '保有ポイント: ${_isLoadingPoints ? '--' : _availablePoints}pt',
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
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('1'),
                _buildNumberButton('2'),
                _buildNumberButton('3'),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('4'),
                _buildNumberButton('5'),
                _buildNumberButton('6'),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('7'),
                _buildNumberButton('8'),
                _buildNumberButton('9'),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildActionButton('C', _onClearPressed, Colors.red),
                _buildNumberButton('0'),
                _buildActionButton('⌫', _onBackspacePressed, Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: '確定',
            onPressed: _isProcessing ? null : _onNextPressed,
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
