import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/custom_button.dart';
import '../coupons/coupon_select_for_checkout_view.dart';
import 'point_usage_input_view.dart';

class PointUsageConfirmationView extends ConsumerStatefulWidget {
  final String userId;
  final String storeId;
  final Map<String, dynamic>? scannedUserProfile;

  const PointUsageConfirmationView({
    Key? key,
    required this.userId,
    required this.storeId,
    this.scannedUserProfile,
  }) : super(key: key);

  @override
  ConsumerState<PointUsageConfirmationView> createState() =>
      _PointUsageConfirmationViewState();
}

class _PointUsageConfirmationViewState
    extends ConsumerState<PointUsageConfirmationView> {
  String _actualUserName = 'お客様';
  String? _profileImageUrl;
  bool _isLoadingUserInfo = true;
  bool _isCheckingPoints = true;
  bool _skipTriggered = false;
  int? _availablePoints;

  @override
  void initState() {
    super.initState();
    if (widget.scannedUserProfile != null) {
      _actualUserName = _resolveDisplayName(widget.scannedUserProfile!);
      _profileImageUrl = _resolveProfileImageUrl(widget.scannedUserProfile!);
    }
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
        final userData = <String, dynamic>{
          ...?widget.scannedUserProfile,
          ...?(userDoc.data()),
        };
        final displayName = _resolveDisplayName(userData);
        final profileImageUrl = _resolveProfileImageUrl(userData);
        final points = _parsePointsOrNull(userData['points']) ?? 0;
        final specialPoints =
            _parsePointsOrNull(userData['specialPoints']) ?? 0;
        final availablePoints = points + specialPoints;
        setState(() {
          _actualUserName = displayName;
          _profileImageUrl = profileImageUrl;
          _availablePoints = availablePoints;
          _isLoadingUserInfo = false;
        });
        await _maybeSkipIfNoPoints(userData, displayName);
      } else {
        final fallbackUserData =
            widget.scannedUserProfile ?? const <String, dynamic>{};
        setState(() {
          _actualUserName = _resolveDisplayName(fallbackUserData);
          _profileImageUrl = _resolveProfileImageUrl(fallbackUserData);
          _isLoadingUserInfo = false;
        });
        await _maybeSkipIfNoPoints(fallbackUserData, _actualUserName);
      }
    } catch (e) {
      final fallbackUserData =
          widget.scannedUserProfile ?? const <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _actualUserName = _resolveDisplayName(fallbackUserData);
        _profileImageUrl = _resolveProfileImageUrl(fallbackUserData);
        _isLoadingUserInfo = false;
      });
      await _maybeSkipIfNoPoints(fallbackUserData, _actualUserName);
    }
  }

  String _resolveDisplayName(Map<String, dynamic> userData) {
    if (userData['displayName'] is String &&
        (userData['displayName'] as String).isNotEmpty) {
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PointUsageInputView(
          userId: widget.userId,
          storeId: widget.storeId,
          scannedUserProfile: widget.scannedUserProfile,
        ),
      ),
    );
  }

  void _skipPointUsage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CouponSelectForCheckoutView(
          userId: widget.userId,
          userName: _actualUserName,
          usedPoints: 0,
          storeId: widget.storeId,
          nextRoute: CouponSelectNextRoute.stamp,
          scannedUserProfile: widget.scannedUserProfile,
        ),
      ),
    );
  }

  Future<void> _maybeSkipIfNoPoints(
    Map<String, dynamic> userData,
    String resolvedName,
  ) async {
    if (_skipTriggered) return;
    int availablePoints = 0;
    try {
      final userPoints = _parsePointsOrNull(userData['points']) ?? 0;
      final specialPoints = _parsePointsOrNull(userData['specialPoints']) ?? 0;
      availablePoints = userPoints + specialPoints;
      if (availablePoints == 0) {
        final balanceDoc = await FirebaseFirestore.instance
            .collection('user_point_balances')
            .doc(widget.userId)
            .get();
        final data = balanceDoc.data() ?? {};
        final balancePoints = _parsePointsOrNull(data['availablePoints']) ?? 0;
        availablePoints = balancePoints;
      }

      if (availablePoints <= 0 && mounted) {
        _skipTriggered = true;
        _actualUserName = resolvedName;
        _skipPointUsage();
        return;
      }
    } catch (_) {
      // ignore and continue to show confirmation UI
      if (mounted) {
        setState(() {
          _isCheckingPoints = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _isCheckingPoints = false;
        _availablePoints = availablePoints;
      });
    }
  }

  int? _parsePointsOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPoints) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('ポイント利用確認'),
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3)),
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
            CustomButton(
              text: '利用する',
              onPressed: _navigateToPointUsage,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _skipPointUsage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B35),
                  side: const BorderSide(color: Color(0xFFFF6B35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
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
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 8),
                Text(
                  _availablePoints == null
                      ? '保有ポイント: --'
                      : '保有ポイント: ${_availablePoints}pt',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
        _actualUserName.isNotEmpty
            ? _actualUserName.substring(0, 1).toUpperCase()
            : '客',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
