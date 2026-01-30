import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'point_request_confirmation_view.dart';

class StoreUserDetailView extends StatefulWidget {
  final String userId;
  final String storeId;
  final List<String> selectedCouponIds;

  const StoreUserDetailView({
    Key? key,
    required this.userId,
    required this.storeId,
    this.selectedCouponIds = const [],
  }) : super(key: key);

  @override
  State<StoreUserDetailView> createState() => _StoreUserDetailViewState();
}

class _StoreUserDetailViewState extends State<StoreUserDetailView> {
  late Future<_UserSummary> _summaryFuture;
  bool _isStampProcessing = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<_UserSummary> _loadSummary() async {
    final firestore = FirebaseFirestore.instance;
    final userDoc = await firestore.collection('users').doc(widget.userId).get();
    final balanceDoc = await firestore.collection('user_point_balances').doc(widget.userId).get();
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

    return _UserSummary(
      userData: userDoc.data(),
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
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      final callable = functions.httpsCallable('punchStamp');
      final payload = {
        'userId': widget.userId,
        'storeId': widget.storeId,
        if (widget.selectedCouponIds.isNotEmpty)
          'selectedCouponIds': widget.selectedCouponIds,
      };
      await callable.call(payload);
      if (!mounted) return;
      final requestId = '${widget.storeId}_${widget.userId}';
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PointRequestConfirmationView(requestId: requestId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('スタンプ押印に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStampProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ユーザー詳細'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
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
      body: FutureBuilder<_UserSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('ユーザー情報が取得できませんでした'));
          }

          final data = snapshot.data!;
          final userName = _resolveDisplayName(data.userData);
          final profileUrl = _resolveProfileImageUrl(data.userData);

          final availablePoints = data.balanceData != null
              ? _parseInt(data.balanceData?['availablePoints'])
              : _parseInt(data.userData?['points']) + _parseInt(data.userData?['specialPoints']);

          final stamps = _parseInt(data.userStoreData?['stamps']);
          final totalVisits = _parseInt(data.storeUserData?['totalVisits']);
          final firstVisitAt = _parseDate(data.storeUserData?['firstVisitAt']);
          final lastVisitAt = _parseDate(data.storeUserData?['lastVisitAt']);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeader(userName, profileUrl),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('来店回数', '${totalVisits}回')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('スタンプ', '${stamps}個')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('ポイント', '${availablePoints}pt')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildVisitInfo(firstVisitAt, lastVisitAt),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isStampProcessing ? null : _punchStamp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isStampProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'スタンプを押印する',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
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
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
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
                      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(userName),
                    )
                  : _buildFallbackAvatar(userName),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildFallbackAvatar(String userName) {
    return Center(
      child: Text(
        userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '客',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitInfo(DateTime? firstVisitAt, DateTime? lastVisitAt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '来店履歴',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
