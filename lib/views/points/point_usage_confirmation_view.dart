import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../payment/store_payment_view.dart';
import 'point_usage_input_view.dart';

class PointUsageConfirmationView extends ConsumerStatefulWidget {
  final String userId;

  const PointUsageConfirmationView({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<PointUsageConfirmationView> createState() => _PointUsageConfirmationViewState();
}

class _PointUsageConfirmationViewState extends ConsumerState<PointUsageConfirmationView> {
  String _actualUserName = 'お客様';
  String? _profileImageUrl;
  bool _isLoadingUserInfo = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
        final displayName = _resolveDisplayName(userData);
        final profileImageUrl = _resolveProfileImageUrl(userData);
        setState(() {
          _actualUserName = displayName;
          _profileImageUrl = profileImageUrl;
          _isLoadingUserInfo = false;
        });
      } else {
        setState(() {
          _actualUserName = 'お客様';
          _isLoadingUserInfo = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actualUserName = 'お客様';
        _isLoadingUserInfo = false;
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

  void _navigateToPointUsage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PointUsageInputView(userId: widget.userId),
      ),
    );
  }

  void _skipPointUsage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StorePaymentView(
          userId: widget.userId,
          userName: _actualUserName,
          usedPoints: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ポイント利用確認'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCustomerCard(),
            const SizedBox(height: 24),
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
              child: Column(
                children: const [
                  Icon(Icons.help_outline, size: 48, color: Color(0xFFFF6B35)),
                  SizedBox(height: 12),
                  Text(
                    'ポイント利用はしますか？',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _navigateToPointUsage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  '利用する',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _skipPointUsage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B35),
                  side: const BorderSide(color: Color(0xFFFF6B35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  '利用しない',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(28),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: _isLoadingUserInfo
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : _profileImageUrl != null
                      ? Image.network(
                          _profileImageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackAvatar();
                          },
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    return Center(
      child: Text(
        _actualUserName.isNotEmpty ? _actualUserName.substring(0, 1).toUpperCase() : '客',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
