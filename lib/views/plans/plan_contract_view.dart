import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/common_header.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';

class PlanContractView extends ConsumerWidget {
  const PlanContractView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeIdAsync = ref.watch(userStoreIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: const CommonHeader(title: 'プラン・契約情報'),
      body: storeIdAsync.when(
        data: (storeId) {
          if (storeId == null) {
            return const Center(child: Text('店舗情報が見つかりません'));
          }
          return _PlanContractBody(storeId: storeId);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('エラーが発生しました')),
      ),
    );
  }
}

class _PlanContractBody extends ConsumerWidget {
  final String storeId;

  const _PlanContractBody({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeDataAsync = ref.watch(storeDataProvider(storeId));

    return storeDataAsync.when(
      data: (storeData) {
        if (storeData == null) {
          return const Center(child: Text('店舗データが見つかりません'));
        }

        final subscription =
            storeData['subscription'] as Map<String, dynamic>? ?? {};
        final planId = subscription['planId'] as String? ?? 'basic';
        final status = subscription['status'] as String? ?? 'trialing';
        final startDate = subscription['startDate'] as Timestamp?;
        final currentPeriodEnd =
            subscription['currentPeriodEnd'] as Timestamp?;
        final paymentMethodBrand =
            subscription['paymentMethodBrand'] as String?;
        final paymentMethodLast4 =
            subscription['paymentMethodLast4'] as String?;
        final storeName = storeData['name'] as String? ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentPlanCard(
                planId: planId,
                status: status,
                storeName: storeName,
              ),
              const SizedBox(height: 24),
              _buildContractInfoSection(
                status: status,
                startDate: startDate,
                currentPeriodEnd: currentPeriodEnd,
                paymentMethodBrand: paymentMethodBrand,
                paymentMethodLast4: paymentMethodLast4,
              ),
              const SizedBox(height: 24),
              _buildPlanFeaturesSection(planId, status),
              const SizedBox(height: 24),
              _buildContactSection(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('データの取得に失敗しました')),
    );
  }

  Widget _buildCurrentPlanCard({
    required String planId,
    required String status,
    required String storeName,
  }) {
    final planName = _getPlanName(planId);
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8F5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  storeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            planName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getPlanDescription(planId, status),
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (status == 'active') ...[
                const SizedBox(width: 12),
                Text(
                  _getPlanPrice(planId),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractInfoSection({
    required String status,
    required Timestamp? startDate,
    required Timestamp? currentPeriodEnd,
    required String? paymentMethodBrand,
    required String? paymentMethodLast4,
  }) {
    final dateFormat = DateFormat('yyyy年M月d日');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.description,
                    color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                const Text(
                  '契約情報',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                _buildContractInfoItem(
                  'ステータス',
                  _getStatusLabel(status),
                ),
                if (startDate != null)
                  _buildContractInfoItem(
                    '契約開始日',
                    dateFormat.format(startDate.toDate()),
                  ),
                if (status == 'active' && currentPeriodEnd != null)
                  _buildContractInfoItem(
                    '次回請求日',
                    dateFormat.format(currentPeriodEnd.toDate()),
                  ),
                if (paymentMethodBrand != null &&
                    paymentMethodLast4 != null)
                  _buildContractInfoItem(
                    '支払い方法',
                    '${_getCardBrandLabel(paymentMethodBrand)} ****$paymentMethodLast4',
                  ),
                if (status == 'active')
                  _buildContractInfoItem('請求サイクル', '月額'),
                if (status == 'trialing')
                  _buildContractInfoItem('料金', '無料'),
                _buildContractInfoItem('契約変更', 'サポートへお問い合わせください'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanFeaturesSection(String planId, String status) {
    final features = _getPlanFeatures(planId, status);
    final isTrialing = status == 'trialing';
    final sectionTitle = isTrialing ? '利用可能な機能（全機能開放中）' : '${_getPlanName(planId)}の機能';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.card_membership,
                    color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sectionTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isTrialing)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE0B2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Color(0xFFFF6B35)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '無料期間中はプレミアムプランを含む全機能をご利用いただけます',
                        style: TextStyle(fontSize: 13, color: Color(0xFFE65100), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: features
                  .map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.check_circle,
                                  size: 16, color: Color(0xFFFF6B35)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_support,
                  color: const Color(0xFFFF6B35), size: 24),
              const SizedBox(width: 8),
              const Text(
                'サポート・お問い合わせ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'プラン変更や契約に関するご質問は、以下までお気軽にお問い合わせください。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.email,
            title: 'メールサポート',
            content: 'info@groumapapp.com',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.phone,
            title: '電話サポート',
            content: '080-6050-7194',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.access_time,
            title: '受付時間',
            content: '月〜金 11:00〜18:00',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF6B35), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ヘルパーメソッド ---

  String _getPlanName(String planId) {
    switch (planId) {
      case 'basic':
        return 'ベーシックプラン';
      case 'premium':
        return 'プレミアムプラン';
      default:
        return 'ベーシックプラン';
    }
  }

  String _getPlanDescription(String planId, String status) {
    if (status == 'trialing') {
      return '無料期間中 — 全機能をご利用いただけます';
    }
    switch (planId) {
      case 'basic':
        return '店舗掲載・スタンプ運用・クーポン発行';
      case 'premium':
        return 'ベーシック + 投稿機能 + Instagram連携';
      default:
        return '店舗掲載・スタンプ運用・クーポン発行';
    }
  }

  String _getPlanPrice(String planId) {
    // 料金はFirestoreから取得する形に将来拡張可能
    // 現段階では表示しない（サポート経由で案内）
    return '';
  }

  List<String> _getPlanFeatures(String planId, String status) {
    // 無料期間中は全機能（ベーシック+プレミアム）を開放
    if (status == 'trialing') {
      return [
        'マップ上への店舗掲載',
        'スタンプ運用（スタンプ数・特典は自由設定）',
        'クーポン発行（有効期限内で最大3件）',
        'QRコードによるチェックイン',
        '基本統計情報の表示',
        '投稿機能',
        'Instagram連携（自動同期）',
        'メールサポート',
      ];
    }
    switch (planId) {
      case 'basic':
        return [
          'マップ上への店舗掲載',
          'スタンプ運用（スタンプ数・特典は自由設定）',
          'クーポン発行（有効期限内で最大3件）',
          'QRコードによるチェックイン',
          '基本統計情報の表示',
          'メールサポート',
        ];
      case 'premium':
        return [
          'マップ上への店舗掲載',
          'スタンプ運用（スタンプ数・特典は自由設定）',
          'クーポン発行（有効期限内で最大3件）',
          'QRコードによるチェックイン',
          '基本統計情報の表示',
          '投稿機能',
          'Instagram連携（自動同期）',
          '優先サポート',
        ];
      default:
        return [];
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'trialing':
        return '無料期間中';
      case 'active':
        return 'アクティブ';
      case 'canceled':
        return '解約済み';
      case 'past_due':
        return '支払い遅延';
      default:
        return '無料期間中';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'trialing':
        return Colors.white;
      case 'active':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      case 'past_due':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  String _getCardBrandLabel(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'jcb':
        return 'JCB';
      case 'amex':
        return 'American Express';
      default:
        return brand;
    }
  }
}
