import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanContractView extends ConsumerStatefulWidget {
  const PlanContractView({Key? key}) : super(key: key);

  @override
  ConsumerState<PlanContractView> createState() => _PlanContractViewState();
}

class _PlanContractViewState extends ConsumerState<PlanContractView> {
  // 現在のプラン（デモ用）
  String currentPlan = '小規模店舗プラン';
  
  // プラン情報
  final List<Map<String, dynamic>> plans = [
    {
      'id': 'small',
      'name': '小規模店舗プラン',
      'description': 'ポイント発行1500pt/月',
      'price': 2980,
      'features': [
        '月間ポイント発行上限: 1,500pt',
        '基本統計情報の表示',
        'QRコードスキャン機能',
        'クーポン作成・管理（月5個まで）',
        'メールサポート',
        'データ保持期間: 6ヶ月',
      ],
      'isPopular': false,
      'color': Colors.blue,
    },
    {
      'id': 'medium',
      'name': '中規模店舗プラン',
      'description': 'ポイント発行5000pt/月',
      'price': 4980,
      'features': [
        '月間ポイント発行上限: 5,000pt',
        '詳細統計情報の表示',
        'QRコードスキャン機能',
        'クーポン作成・管理（月20個まで）',
        '優先メールサポート',
        'データ保持期間: 12ヶ月',
        'カスタマイズ機能',
        'API連携',
      ],
      'isPopular': true,
      'color': Colors.purple,
    },
    {
      'id': 'premium',
      'name': 'プレミアムプラン',
      'description': '小・中規模店舗プランに+2,000円',
      'price': 6980,
      'features': [
        '月間ポイント発行上限: 5,000pt',
        '全機能アクセス',
        'QRコードスキャン機能',
        'クーポン作成・管理（無制限）',
        '24時間電話サポート',
        'データ保持期間: 無制限',
        '高度なカスタマイズ機能',
        'API連携',
        '専任カスタマーサクセス',
        '独自機能の追加開発対応',
        '優先的な新機能アクセス',
      ],
      'isPopular': false,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プラン・契約情報'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 現在のプラン情報
            _buildCurrentPlanCard(),
            
            const SizedBox(height: 24),
            
            // プラン選択セクション
            _buildPlansSection(),
            
            const SizedBox(height: 24),
            
            // 契約情報セクション
            _buildContractInfoSection(),
            
            const SizedBox(height: 24),
            
            // お問い合わせセクション
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    final currentPlanData = plans.firstWhere(
      (plan) => plan['name'] == currentPlan,
      orElse: () => plans.first,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [currentPlanData['color'], currentPlanData['color'].withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: currentPlanData['color'].withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '現在のプラン',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentPlanData['name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentPlanData['description'],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${currentPlanData['price'].toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}/月',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Text(
              'アクティブ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.card_membership, color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                const Text(
                  '利用可能なプラン',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...plans.map((plan) => _buildPlanCard(plan)).toList(),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isCurrentPlan = plan['name'] == currentPlan;
    final isPopular = plan['isPopular'] as bool;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentPlan ? plan['color'].withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPlan ? plan['color'] : Colors.grey[300]!,
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // プランヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrentPlan ? plan['color'] : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCurrentPlan ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '人気',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (isCurrentPlan) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: const Text(
                                '現在のプラン',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isCurrentPlan ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¥${plan['price'].toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}/月',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isCurrentPlan ? Colors.white : plan['color'],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCurrentPlan)
                  ElevatedButton(
                    onPressed: () => _showUpgradeDialog(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan['color'],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '変更',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          
          // 機能一覧
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '含まれる機能:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...(plan['features'] as List<String>).map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: plan['color'],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractInfoSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.description, color: const Color(0xFFFF6B35), size: 24),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildContractInfoItem('契約開始日', '2024年12月1日'),
                _buildContractInfoItem('次回請求日', '2025年1月1日'),
                _buildContractInfoItem('支払い方法', 'クレジットカード（****1234）'),
                _buildContractInfoItem('請求サイクル', '月額'),
                _buildContractInfoItem('契約期間', '自動更新'),
                _buildContractInfoItem('キャンセル', 'いつでも可能'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildContractInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_support, color: const Color(0xFFFF6B35), size: 24),
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
            title: 'プランサポート',
            content: 'plan@groumap.com',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.phone,
            title: '電話サポート',
            content: '03-1234-5678',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.access_time,
            title: '受付時間',
            content: '平日 9:00-18:00',
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
        Icon(
          icon,
          color: const Color(0xFFFF6B35),
          size: 20,
        ),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUpgradeDialog(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('プラン変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${plan['name']}に変更しますか？'),
            const SizedBox(height: 16),
            Text(
              '変更内容:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('現在のプラン: $currentPlan'),
            Text('新しいプラン: ${plan['name']}'),
            Text('料金: ¥${plan['price']}/月'),
            const SizedBox(height: 16),
            Text(
              'プラン変更は次回請求日から適用されます。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                currentPlan = plan['name'];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${plan['name']}への変更を申請しました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: plan['color'],
              foregroundColor: Colors.white,
            ),
            child: const Text('変更申請'),
          ),
        ],
      ),
    );
  }
}
