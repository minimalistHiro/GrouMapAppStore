import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーセクション
            _buildHeaderSection(),
            
            const SizedBox(height: 24),
            
            // 更新日セクション
            _buildUpdateSection(),
            
            const SizedBox(height: 24),
            
            // プライバシーポリシー本文
            _buildPolicyContent(),
            
            const SizedBox(height: 24),
            
            // お問い合わせセクション
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.privacy_tip,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'プライバシーポリシー',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'GrouMap Storeにおける個人情報の取り扱いについて',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.update, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最終更新日',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  '2024年12月1日',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyContent() {
    final sections = [
      {
        'title': '1. 個人情報の収集について',
        'content': '''GrouMap Storeでは、以下の個人情報を収集する場合があります：

• アカウント情報（氏名、メールアドレス、電話番号）
• 店舗情報（店舗名、住所、営業時間、連絡先）
• 利用履歴（来店記録、ポイント付与履歴、クーポン使用履歴）
• デバイス情報（IPアドレス、ブラウザ情報、OS情報）

これらの情報は、サービス提供に必要な範囲で収集されます。''',
      },
      {
        'title': '2. 個人情報の利用目的',
        'content': '''収集した個人情報は、以下の目的で利用します：

• サービスの提供・運営
• ユーザー認証・本人確認
• 店舗管理機能の提供
• ポイント・クーポンシステムの運営
• カスタマーサポートの提供
• サービス改善・新機能開発
• 不正利用の防止・セキュリティ向上
• 法令に基づく対応''',
      },
      {
        'title': '3. 個人情報の第三者提供',
        'content': '''当社は、以下の場合を除き、個人情報を第三者に提供することはありません：

• ユーザーの同意がある場合
• 法令に基づく場合
• 人の生命、身体または財産の保護のために必要がある場合
• 公衆衛生の向上または児童の健全な育成の推進のために特に必要がある場合
• 国の機関もしくは地方公共団体またはその委託を受けた者が法令の定める事務を遂行することに対して協力する必要がある場合''',
      },
      {
        'title': '4. 個人情報の管理・保護',
        'content': '''当社は、個人情報の正確性を保ち、これを安全に管理いたします：

• SSL/TLS暗号化による通信の保護
• アクセス制御による情報への不正アクセス防止
• 定期的なセキュリティ監査・脆弱性診断
• 従業員への個人情報保護教育
• 適切な保管期間の設定と期限切れデータの削除''',
      },
      {
        'title': '5. 個人情報の開示・訂正・削除',
        'content': '''ユーザーは、自己の個人情報について、以下の権利を有します：

• 開示請求権：保有する個人情報の開示を求める権利
• 訂正・削除請求権：個人情報の訂正・削除を求める権利
• 利用停止権：個人情報の利用停止を求める権利

これらの請求は、アプリ内のお問い合わせ機能またはサポートメールを通じて行うことができます。''',
      },
      {
        'title': '6. Cookie・トラッキング技術の使用',
        'content': '''当社は、サービス改善のために以下の技術を使用します：

• Cookie：ユーザー設定の保存、利用状況の分析
• ローカルストレージ：アプリデータの一時保存
• アナリティクス：サービス利用状況の分析

これらの技術により収集される情報は、個人を特定できない形で処理されます。''',
      },
      {
        'title': '7. 未成年者の個人情報',
        'content': '''未成年者（18歳未満）の個人情報については、保護者の同意を得た上で収集・利用いたします。

保護者の方は、お子様の個人情報の開示・訂正・削除を求めることができます。''',
      },
      {
        'title': '8. プライバシーポリシーの変更',
        'content': '''当社は、法令の改正やサービス内容の変更に伴い、本プライバシーポリシーを変更する場合があります。

重要な変更がある場合は、アプリ内通知やメールでお知らせいたします。''',
      },
    ];

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'プライバシーポリシー',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...sections.map((section) => _buildPolicySection(
              title: section['title']!,
              content: section['content']!,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
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
                'お問い合わせ',
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
            '個人情報の取り扱いに関するご質問やご不明な点がございましたら、以下までお気軽にお問い合わせください。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.email,
            title: 'サポートメール',
            content: 'support@groumap.com',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.access_time,
            title: '受付時間',
            content: '平日 9:00-18:00（土日祝日を除く）',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.phone,
            title: '電話サポート',
            content: '03-1234-5678',
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
}
