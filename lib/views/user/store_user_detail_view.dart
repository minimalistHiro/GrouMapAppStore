import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../theme/store_ui.dart';
import '../../widgets/app_loading_overlay.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/stats_card.dart';
import 'point_request_confirmation_view.dart';

class StoreUserDetailView extends StatefulWidget {
  final String userId;
  final String storeId;
  final List<String> selectedCouponIds;
  final List<String> selectedSpecialCouponIds;
  final Map<String, dynamic>? scannedUserProfile;

  const StoreUserDetailView({
    super.key,
    required this.userId,
    required this.storeId,
    this.selectedCouponIds = const [],
    this.selectedSpecialCouponIds = const [],
    this.scannedUserProfile,
  });

  @override
  State<StoreUserDetailView> createState() => _StoreUserDetailViewState();
}

class _StoreUserDetailViewState extends State<StoreUserDetailView> {
  late Future<_UserSummary> _summaryFuture;
  bool _isStampProcessing = false;
  bool _alreadyStampedToday = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<_UserSummary> _loadSummary() async {
    final firestore = FirebaseFirestore.instance;
    final userDoc =
        await firestore.collection('users').doc(widget.userId).get();
    final balanceDoc = await firestore
        .collection('user_point_balances')
        .doc(widget.userId)
        .get();
    final userStoreDoc = await firestore
        .collection('users')
        .doc(widget.userId)
        .collection('stores')
        .doc(widget.storeId)
        .get();
    final storeUserDoc = await firestore
        .collection('store_users')
        .doc(widget.storeId)
        .collection('users')
        .doc(widget.userId)
        .get();

    final mergedUserData = <String, dynamic>{
      ...?widget.scannedUserProfile,
      ...?(userDoc.data()),
    };

    return _UserSummary(
      userData: mergedUserData.isEmpty ? null : mergedUserData,
      balanceData: balanceDoc.data(),
      userStoreData: userStoreDoc.data(),
      storeUserData: storeUserDoc.data(),
    );
  }

  String _resolveDisplayName(Map<String, dynamic>? userData) {
    if (userData == null) return 'お客様';
    final displayName = userData['displayName'];
    if (displayName is String && displayName.isNotEmpty) return displayName;
    final name = userData['name'];
    if (name is String && name.isNotEmpty) return name;
    final email = userData['email'];
    if (email is String && email.isNotEmpty) return email;
    return 'お客様';
  }

  String? _resolveProfileImageUrl(Map<String, dynamic>? userData) {
    if (userData == null) return null;
    final value = userData['profileImageUrl'];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '未記録';
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }

  Future<void> _punchStamp() async {
    if (_isStampProcessing) return;
    setState(() {
      _isStampProcessing = true;
    });
    try {
      debugPrint(
        'Stamp: user=${widget.userId}, store=${widget.storeId}, coupons=${widget.selectedCouponIds.length}',
      );
      final functions =
          FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      final callable = functions.httpsCallable('punchStamp');
      final payload = {
        'userId': widget.userId,
        'storeId': widget.storeId,
        if (widget.selectedCouponIds.isNotEmpty)
          'selectedCouponIds': widget.selectedCouponIds,
        if (widget.selectedSpecialCouponIds.isNotEmpty)
          'selectedUserCouponIds': widget.selectedSpecialCouponIds,
      };
      await callable.call(payload);

      if (!mounted) return;
      final requestId = '${widget.storeId}_${widget.userId}';
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PointRequestConfirmationView(requestId: requestId),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'punchStamp error: code=${e.code}, message=${e.message}, details=${e.details}',
      );
      if (!mounted) return;
      if (e.code == 'already-exists') {
        setState(() {
          _alreadyStampedToday = true;
          _summaryFuture = _loadSummary();
        });
        await _showAlreadyStampedDialog();
      } else {
        await _showStampErrorDialog();
      }
    } catch (e) {
      debugPrint('punchStamp unexpected error: $e');
      if (!mounted) return;
      await _showStampErrorDialog();
    } finally {
      if (mounted) {
        setState(() {
          _isStampProcessing = false;
        });
      }
    }
  }

  Future<void> _showAlreadyStampedDialog() {
    return showGameDialog(
      context: context,
      title: '本日は押印済みです',
      message: 'この店舗では、本日分のスタンプがすでに記録されています。',
      icon: Icons.check_circle_outline,
      actions: [
        GameDialogAction(
          label: 'OK',
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _showStampErrorDialog() {
    return showGameDialog(
      context: context,
      title: '押印できませんでした',
      message: '通信状況を確認して、もう一度お試しください。',
      icon: Icons.error_outline,
      headerColor: StoreUi.error,
      actions: [
        GameDialogAction(
          label: '閉じる',
          isPrimary: true,
          color: StoreUi.error,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoreUi.surface,
      appBar: CommonHeader(
        title: 'ユーザー詳細',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _summaryFuture = _loadSummary();
              });
            },
          ),
        ],
      ),
      body: DismissKeyboard(
        child: Stack(
          children: [
            FutureBuilder<_UserSummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CustomLoadingIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('ユーザー情報が取得できませんでした'));
                }

                final data = snapshot.data!;
                final userName = _resolveDisplayName(data.userData);
                final profileUrl = _resolveProfileImageUrl(data.userData);
                final availablePoints = data.balanceData != null
                    ? _parseInt(data.balanceData?['availablePoints'])
                    : _parseInt(data.userData?['points']) +
                        _parseInt(data.userData?['specialPoints']);
                final stamps = _parseInt(data.userStoreData?['stamps']);
                final totalVisits =
                    _parseInt(data.storeUserData?['totalVisits']);
                final firstVisitAt =
                    _parseDate(data.storeUserData?['firstVisitAt']);
                final lastVisitAt =
                    _parseDate(data.storeUserData?['lastVisitAt']);

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildHeader(userName, profileUrl),
                      const SizedBox(height: 16),
                      StatsCard(
                        title: '来店情報',
                        items: [
                          StatItem(
                            label: '来店回数',
                            value: '$totalVisits回',
                            icon: Icons.storefront_outlined,
                            color: StoreUi.primary,
                          ),
                          StatItem(
                            label: 'スタンプ',
                            value: '$stamps個',
                            icon: Icons.stars_outlined,
                            color: Colors.amber.shade700,
                          ),
                          StatItem(
                            label: 'ポイント',
                            value: '${availablePoints}pt',
                            icon: Icons.toll_outlined,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildVisitInfo(firstVisitAt, lastVisitAt),
                      const Spacer(),
                      CustomButton(
                        text: _alreadyStampedToday ? '本日は押印済み' : 'スタンプを押印する',
                        onPressed: _isStampProcessing || _alreadyStampedToday
                            ? null
                            : _punchStamp,
                        height: 52,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_isStampProcessing) const AppLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, String? profileUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: StoreUi.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: profileUrl != null
                  ? Image.network(
                      profileUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackAvatar(),
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
                  userName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'ユーザーID: ${widget.userId}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return const Center(
      child: Icon(Icons.person, color: StoreUi.primary, size: 34),
    );
  }

  Widget _buildVisitInfo(DateTime? firstVisitAt, DateTime? lastVisitAt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '来店履歴',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('初回来店: ${_formatDate(firstVisitAt)}'),
          const SizedBox(height: 4),
          Text('最終来店: ${_formatDate(lastVisitAt)}'),
        ],
      ),
    );
  }
}

class _UserSummary {
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? balanceData;
  final Map<String, dynamic>? userStoreData;
  final Map<String, dynamic>? storeUserData;

  _UserSummary({
    required this.userData,
    required this.balanceData,
    required this.userStoreData,
    required this.storeUserData,
  });
}
